<?php

namespace App\Services;

use App\Mail\RequestAcceptedMail;
use App\Mail\RequestCreatedMail;
use App\Models\Notification;
use App\Models\ServiceRequest;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Every booking event is sent on EVERY channel:
 *   in-app row + FCM push, SMS, Email.
 * Each channel is isolated: one failing never blocks the others.
 *
 *   new request  → fundi
 *   accepted     → customer
 *   rejected     → customer
 *   cancelled    → fundi
 */
class RequestNotificationService
{
    public function __construct(protected SmsNotificationService $sms)
    {
    }

    // ──────────────────────────────────────────────
    // NEW REQUEST → fundi
    // ──────────────────────────────────────────────
    public function notifyFundiNewRequest(ServiceRequest $request): array
    {
        $request->loadMissing(['customer', 'technician.user', 'service', 'category']);

        $technician = $request->technician;
        $fundi      = $technician?->user;

        if (!$fundi) {
            Log::warning('New request: technician has no user', ['request_id' => $request->id]);
            return ['in_app' => false, 'sms' => false, 'email' => false];
        }

        $service  = $request->service->name ?? 'Service';
        $category = $request->category->category_name ?? '';
        $customer = $request->customer->name ?? 'a customer';

        $title = 'New Service Request';
        $body  = "You have a new request for {$service}"
               . ($category ? " ({$category})" : '')
               . " from {$customer}.";

        return $this->send(
            $request, 'new_request', $fundi, $title, $body, 'new_request',
            [
                'request_id'    => $request->id,
                'customer_id'   => $request->customer_id,
                'customer_name' => $customer,
                'service_name'  => $service,
                'category_name' => $category,
                'description'   => $request->description,
                'status'        => $request->status,
            ],
            fn () => $this->sms->notifyTechnicianNewRequest($request, $technician),
            function (string $email) use ($request) {
                Mail::to($email)->send(new RequestCreatedMail($request));
            }
        );
    }

    // ──────────────────────────────────────────────
    // ACCEPTED → customer
    // ──────────────────────────────────────────────
        // ──────────────────────────────────────────────
    // ACCEPTED → customer
    // ──────────────────────────────────────────────
    public function notifyCustomerAccepted(ServiceRequest $request): array
    {
        $request->loadMissing(['customer', 'technician.user', 'service', 'job']);

        $customer = $request->customer;
        if (!$customer) {
            return ['in_app' => false, 'sms' => false, 'email' => false];
        }

        $techName = $request->technician->user->name ?? 'the fundi';
        $title    = 'Request Accepted';
        $body     = "Your request has been accepted by {$techName}. "
                  . "Open the Jobs section to contact the fundi or chat with them in the app.";

        return $this->send(
            $request, 'accepted', $customer, $title, $body, 'request_accepted',
            [
                'request_id'      => $request->id,
                'job_id'          => $request->job?->id,
                'technician_id'   => $request->technician_id,
                'technician_name' => $techName,
                'status'          => $request->status,
            ],
            fn () => $this->sms->notifyCustomerRequestAccepted($request, $request->technician),
            function (string $email) use ($request) {
                Mail::to($email)->send(new RequestAcceptedMail($request));
            }
        );
    }
   

    // ──────────────────────────────────────────────
    // REJECTED → customer
    // ──────────────────────────────────────────────
    public function notifyCustomerRejected(ServiceRequest $request): array
    {
        $request->loadMissing(['customer', 'technician.user', 'service']);

        $customer = $request->customer;
        if (!$customer) {
            return ['in_app' => false, 'sms' => false, 'email' => false];
        }

        $techName = $request->technician->user->name ?? 'The fundi';
        $service  = $request->service->name ?? 'your service';
        $title    = 'Request Rejected';
        $body     = "{$techName} could not take your {$service} request. You can choose another fundi.";

        return $this->send(
            $request, 'rejected', $customer, $title, $body, 'request_rejected',
            [
                'request_id'      => $request->id,
                'technician_id'   => $request->technician_id,
                'technician_name' => $techName,
                'status'          => $request->status,
            ],
            fn () => $this->sms->notifyCustomerRequestRejected($request, $request->technician),
            fn (string $email) => $this->plainEmail($email, $title, $body)
        );
    }

    // ──────────────────────────────────────────────
    // CANCELLED → fundi
    // ──────────────────────────────────────────────
    public function notifyFundiCancelled(ServiceRequest $request): array
    {
        $request->loadMissing(['customer', 'technician.user', 'service']);

        $technician = $request->technician;
        $fundi      = $technician?->user;

        if (!$fundi) {
            return ['in_app' => false, 'sms' => false, 'email' => false];
        }

        $customer = $request->customer->name ?? 'A customer';
        $service  = $request->service->name ?? 'a service';
        $title    = 'Request Cancelled';
        $body     = "{$customer} cancelled the {$service} request.";

        return $this->send(
            $request, 'cancelled', $fundi, $title, $body, 'request_cancelled',
            [
                'request_id'    => $request->id,
                'customer_name' => $customer,
                'status'        => $request->status,
            ],
            fn () => $this->sms->notifyTechnicianRequestCancelled($request, $technician),
            fn (string $email) => $this->plainEmail($email, $title, $body)
        );
    }

    // ──────────────────────────────────────────────
    // INTERNALS
    // ──────────────────────────────────────────────

    /** in-app + push, SMS, email — each isolated. */
    protected function send(
        ServiceRequest $request,
        string $event,
        User $to,
        string $title,
        string $body,
        string $type,
        array $data,
        callable $smsCall,
        callable $emailCall
    ): array {
        $result = [
            'in_app' => $this->attempt('in_app', fn () => $this->inApp($to, $title, $body, $type, $data)),
            'sms'    => $this->attempt('sms', fn () => (bool) ($smsCall()['success'] ?? false)),
            'email'  => $this->attempt('email', function () use ($to, $emailCall) {
                if (empty($to->email)) {
                    return false;
                }
                $emailCall($to->email);
                return true;
            }),
        ];

        Log::info("Request notifications [{$event}]", ['request_id' => $request->id] + $result);

        return $result;
    }

    protected function plainEmail(string $email, string $subject, string $body): void
    {
        Mail::raw(
            $body . "\n\nOpen the Nearby Fundi app to see the details.\n\n— Nearby Fundi",
            fn ($message) => $message->to($email)->subject($subject)
        );
    }

    protected function inApp(User $user, string $title, string $body, string $type, array $data): bool
    {
        $title = (trim($title) !== '' && !is_numeric($title)) ? trim($title) : config('app.name', 'NearbyFundi');
        $body  = (trim($body) !== '' && !is_numeric($body)) ? trim($body) : 'You have a new update';

        $notification = Notification::create([
            'user_id' => $user->id,
            'title'   => $title,
            'body'    => $body,
            'type'    => $type,
            'data'    => $this->stringify($data),
            'is_read' => false,
        ]);

        app(FcmService::class)->sendFromNotification($notification->fresh('user'));

        return true;
    }

    protected function attempt(string $channel, callable $fn): bool
    {
        try {
            return (bool) $fn();
        } catch (Throwable $e) {
            Log::error("Request notification [{$channel}] failed", ['error' => $e->getMessage()]);
            return false;
        }
    }

    protected function stringify(array $data): array
    {
        $out = [];
        foreach ($data as $key => $value) {
            $out[$key] = match (true) {
                $value === null                     => '',
                is_bool($value)                     => $value ? 'true' : 'false',
                is_array($value), is_object($value) => json_encode($value),
                default                             => (string) $value,
            };
        }
        return $out;
    }
}