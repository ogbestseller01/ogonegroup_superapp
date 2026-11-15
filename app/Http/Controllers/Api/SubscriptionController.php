<?php

namespace App\Http\Controllers\Api;

use App\Models\RateCard;
use App\Models\PaymentMethod;
use App\Models\Subscription;
use App\Models\Invoice;
use App\Models\User;
use App\Models\Notification;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Mail;
use Carbon\Carbon;

class SubscriptionController extends BaseApiController
{
    use Auditable;

    /*
    |--------------------------------------------------------------------------
    | PUBLIC ENDPOINTS (No Authentication Required)
    |--------------------------------------------------------------------------
    */

    /**
     * Get active rate cards.
     * GET /api/v16/rate-cards
     */
    public function getRateCards()
    {
        $rateCards = RateCard::active()
            ->orderBy('display_order')
            ->get()
            ->map(fn($card) => [
                'id'              => $card->id,
                'name'            => $card->name,
                'slug'            => $card->slug,
                'price'           => $card->price,
                'formatted_price' => $card->formatted_price,
                'duration_days'   => $card->duration_days,
                'duration_label'  => $card->duration_label,
                'description'     => $card->description,
                'currency'        => $card->currency,
            ]);

        return $this->successResponse($rateCards, 'Rate cards retrieved successfully');
    }

    /**
     * Get active payment methods.
     * GET /api/v16/payment-methods
     */
    public function getPaymentMethods()
    {
        $methods = PaymentMethod::active()
            ->orderBy('display_order')
            ->get()
            ->map(fn($method) => [
                'id'              => $method->id,
                'name'            => $method->name,
                'slug'            => $method->slug,
                'phone_number'    => $method->phone_number,
                'formatted_phone' => $method->formatted_phone,
                'account_name'    => $method->account_name,
                'logo'            => $method->logo ? url('storage/' . $method->logo) : null,
            ]);

        return $this->successResponse($methods, 'Payment methods retrieved successfully');
    }

    /*
    |--------------------------------------------------------------------------
    | AUTHENTICATED USER ENDPOINTS
    |--------------------------------------------------------------------------
    */

    /**
     * Create a new subscription request.
     * POST /api/v16/subscriptions
     */
    public function store(Request $request)
    {
        $user = $request->user();

        $data = $request->validate([
            'rate_card_id'      => 'required|exists:rate_cards,id',
            'payment_method_id' => 'required|exists:payment_methods,id',
            'payment_proof'     => 'nullable|image|mimes:jpg,jpeg,png,pdf|max:5120',
            'payment_reference' => 'nullable|string|max:255',
            'notes'             => 'nullable|string|max:1000',
        ]);

        $rateCard = RateCard::findOrFail($data['rate_card_id']);
        $paymentMethod = PaymentMethod::findOrFail($data['payment_method_id']);

        // ✅ FIX: Check if user already has an ACTIVE subscription
        if ($user->hasActiveSubscription()) {
            $expiryDate = $user->subscription_expires_at ? $user->subscription_expires_at->format('Y-m-d H:i:s') : 'unknown';
            return $this->errorResponse(
                "You already have an active subscription. It will expire on {$expiryDate}. Please wait until it expires before subscribing again.",
                422
            );
        }

        // ✅ FIX: Check if user has a PENDING subscription
        if (Subscription::where('user_id', $user->id)->where('status', Subscription::STATUS_PENDING)->exists()) {
            return $this->errorResponse(
                'You already have a pending subscription request. Please wait for admin approval.',
                422
            );
        }

        // ✅ FIX: Check if user has an EXPIRED subscription that hasn't been cleaned up
        // Allow expired users to subscribe again, but make sure there's no active subscription
        // This check is already covered by hasActiveSubscription() above

        DB::beginTransaction();

        try {
            $subscription = Subscription::create([
                'user_id'           => $user->id,
                'rate_card_id'      => $rateCard->id,
                'status'            => Subscription::STATUS_PENDING,
                'amount_paid'       => $rateCard->price,
                'currency'          => $rateCard->currency,
                'payment_method'    => $paymentMethod->name,
                'payment_reference' => $data['payment_reference'] ?? null,
                'admin_notes'       => $data['notes'] ?? null,
            ]);

            if ($request->hasFile('payment_proof')) {
                $path = $request->file('payment_proof')->store('payment_proofs', 'public');
                $subscription->payment_proof = $path;
                $subscription->save();
            }

            $invoice = Invoice::create([
                'invoice_number'  => Invoice::generateInvoiceNumber(),
                'user_id'         => $user->id,
                'subscription_id' => $subscription->id,
                'rate_card_id'    => $rateCard->id,
                'amount'          => $rateCard->price,
                'currency'        => $rateCard->currency,
                'status'          => Invoice::STATUS_PENDING,
                'due_date'        => now()->addDays(3),
                'items'           => [
                    [
                        'description' => $rateCard->name . ' Subscription',
                        'duration'    => $rateCard->duration_days . ' days',
                        'amount'      => $rateCard->price,
                    ]
                ],
                'payment_details' => [
                    'payment_method' => $paymentMethod->name,
                    'phone_number'   => $paymentMethod->phone_number,
                    'account_name'   => $paymentMethod->account_name,
                ],
                'notes' => 'Payment pending confirmation. Send payment to the provided number.',
            ]);

            $this->generatePdfInvoice($invoice);

            $this->createNotification(
                $user->id,
                'Subscription Created',
                "Your {$rateCard->name} subscription has been created. Please complete payment and wait for approval.",
                'subscription_created',
                [
                    'subscription_id' => $subscription->id,
                    'rate_card'       => $rateCard->name,
                    'amount'          => $rateCard->formatted_price,
                    'invoice_number'  => $invoice->invoice_number,
                ]
            );

            $this->notifyAdminsNewSubscription($subscription, $invoice);
            $this->logAudit('create_subscription', 'subscription', $subscription->id, "Subscription created by user {$user->id}");

            DB::commit();

            $subscription->load(['rateCard', 'user']);
            $invoice->load(['rateCard']);

            return $this->created([
                'subscription' => $subscription,
                'invoice' => [
                    'id'            => $invoice->id,
                    'invoice_number'=> $invoice->invoice_number,
                    'amount'        => $invoice->formatted_amount,
                    'status'        => $invoice->status,
                    'status_label'  => $invoice->status_label,
                    'pdf_url'       => $invoice->pdf_path ? url('storage/' . $invoice->pdf_path) : null,
                    'created_at'    => $invoice->created_at,
                ],
                'payment_instructions' => [
                    'message'      => "Please send {$rateCard->formatted_price} to:",
                    'method'       => $paymentMethod->name,
                    'phone'        => $paymentMethod->phone_number,
                    'account_name' => $paymentMethod->account_name,
                ]
            ], 'Subscription created. Please complete payment and wait for approval.');

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Failed to create subscription: ' . $e->getMessage());
            return $this->serverError('Failed to create subscription: ' . $e->getMessage());
        }
    }

    /**
     * Get authenticated user's subscriptions.
     * GET /api/v16/my-subscriptions
     */
    public function mySubscriptions(Request $request)
    {
        $user = $request->user();

        // ✅ FIX: Auto-mark expired subscriptions for this user
        $expiredSubscriptions = Subscription::where('user_id', $user->id)
            ->where('status', Subscription::STATUS_ACTIVE)
            ->where('expiry_date', '<', now())
            ->get();

        foreach ($expiredSubscriptions as $expiredSub) {
            $expiredSub->update(['status' => Subscription::STATUS_EXPIRED]);
        }

        // Also update user status if expired
        if (!$user->hasActiveSubscription() && $user->subscription_status === 'active') {
            $user->update(['subscription_status' => 'expired']);
        }

        $subscriptions = Subscription::with(['rateCard', 'invoice'])
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($sub) => [
                'id'               => $sub->id,
                'rate_card'        => $sub->rateCard ? [
                    'id'       => $sub->rateCard->id,
                    'name'     => $sub->rateCard->name,
                    'price'    => $sub->rateCard->formatted_price,
                    'duration' => $sub->rateCard->duration_days . ' days',
                ] : null,
                'status'           => $sub->status,
                'status_label'     => $sub->status_label,
                'start_date'       => $sub->start_date,
                'expiry_date'      => $sub->expiry_date,
                'days_remaining'   => $sub->days_remaining,
                'amount_paid'      => number_format($sub->amount_paid, 0) . ' ' . $sub->currency,
                'payment_method'   => $sub->payment_method,
                'payment_reference'=> $sub->payment_reference,
                'payment_proof'    => $sub->payment_proof ? url('storage/' . $sub->payment_proof) : null,
                'approved_at'      => $sub->approved_at,
                'approved_by'      => $sub->approver ? $sub->approver->name : null,
                'admin_notes'      => $sub->admin_notes,
                'created_at'       => $sub->created_at,
                'invoice'          => $sub->invoice ? [
                    'id'           => $sub->invoice->id,
                    'number'       => $sub->invoice->invoice_number,
                    'amount'       => $sub->invoice->formatted_amount,
                    'status'       => $sub->invoice->status,
                    'status_label' => $sub->invoice->status_label,
                    'pdf_url'      => $sub->invoice->pdf_path ? url('storage/' . $sub->invoice->pdf_path) : null,
                    'created_at'   => $sub->invoice->created_at,
                    'paid_at'      => $sub->invoice->paid_at,
                ] : null,
            ]);

        $active = $user->hasActiveSubscription();

        return $this->successResponse([
            'subscriptions'       => $subscriptions,
            'current_status'      => [
                'has_active'      => $active,
                'expires_at'      => $user->subscription_expires_at,
                'days_remaining'  => $user->subscription_expires_at ? now()->diffInDays($user->subscription_expires_at, false) : null,
                'is_locked'       => !$active,
                'status'          => $user->subscription_status,
            ],
            'subscription_required' => !$active,
        ], 'Subscriptions retrieved successfully');
    }

    /**
     * Get authenticated user's invoices.
     * GET /api/v16/my-invoices
     */
    public function myInvoices(Request $request)
    {
        $user = $request->user();

        $invoices = Invoice::with(['rateCard', 'subscription'])
            ->where('user_id', $user->id)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(fn($invoice) => [
                'id'             => $invoice->id,
                'invoice_number' => $invoice->invoice_number,
                'amount'         => $invoice->formatted_amount,
                'status'         => $invoice->status,
                'status_label'   => $invoice->status_label,
                'due_date'       => $invoice->due_date,
                'paid_at'        => $invoice->paid_at,
                'pdf_url'        => $invoice->pdf_path ? url('storage/' . $invoice->pdf_path) : null,
                'rate_card'      => $invoice->rateCard ? [
                    'name'     => $invoice->rateCard->name,
                    'duration' => $invoice->rateCard->duration_days . ' days',
                ] : null,
                'payment_details' => $invoice->payment_details,
                'notes'          => $invoice->notes,
                'created_at'     => $invoice->created_at,
            ]);

        return $this->successResponse([
            'invoices'      => $invoices,
            'total_pending' => Invoice::where('user_id', $user->id)->where('status', 'pending')->count(),
            'total_paid'    => Invoice::where('user_id', $user->id)->where('status', 'paid')->count(),
        ], 'Invoices retrieved successfully');
    }

    /**
     * Download invoice PDF.
     * GET /api/v16/invoices/{id}/download
     */
    public function downloadInvoicePdf($id, Request $request)
    {
        $invoice = Invoice::with(['user', 'rateCard', 'subscription'])->findOrFail($id);

        $user = $request->user();
        if ($user->id !== $invoice->user_id && !$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.view')) {
            return $this->forbidden('You do not have permission to view this invoice.');
        }

        if (!$invoice->pdf_path || !Storage::disk('public')->exists($invoice->pdf_path)) {
            $this->generatePdfInvoice($invoice);
        }

        if (!$invoice->pdf_path || !Storage::disk('public')->exists($invoice->pdf_path)) {
            return $this->errorResponse('Invoice PDF not found.', 404);
        }

        return Storage::disk('public')->download($invoice->pdf_path, 'invoice_' . $invoice->invoice_number . '.pdf');
    }

    /**
     * Check current user's subscription status.
     * GET /api/v16/check-subscription
     */
    public function checkStatus(Request $request)
    {
        $user = $request->user();
        
        // ✅ FIX: Auto-mark expired subscriptions for this user
        $expiredSubscriptions = Subscription::where('user_id', $user->id)
            ->where('status', Subscription::STATUS_ACTIVE)
            ->where('expiry_date', '<', now())
            ->get();

        foreach ($expiredSubscriptions as $expiredSub) {
            $expiredSub->update(['status' => Subscription::STATUS_EXPIRED]);
        }
        
        // Check if subscription is actually expired
        $hasActive = $user->hasActiveSubscription();
        
        // If subscription is marked active but expired, fix it
        if (!$hasActive && $user->subscription_status === 'active') {
            $user->update([
                'subscription_status' => 'expired',
            ]);
        }

        return $this->successResponse([
            'has_active_subscription' => $hasActive,
            'subscription_status'     => $user->subscription_status ?? 'inactive',
            'expires_at'              => $user->subscription_expires_at,
            'days_remaining'          => $user->subscription_expires_at ? now()->diffInDays($user->subscription_expires_at, false) : null,
            'is_locked'               => !$hasActive,
            'subscription_required'   => !$hasActive,
        ], 'Subscription status retrieved.');
    }

    /*
    |--------------------------------------------------------------------------
    | ADMIN ENDPOINTS (Role or Permission Based)
    |--------------------------------------------------------------------------
    */

    /**
     * Admin: Get all subscriptions with filters.
     * GET /api/v16/admin/subscriptions
     */
    public function adminIndex(Request $request)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.view'))) {
            return $this->forbidden('You need administrator role or subscriptions.view permission.');
        }

        $query = Subscription::with(['user', 'rateCard', 'approver', 'invoice']);

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('user_id')) {
            $query->where('user_id', $request->user_id);
        }
        if ($request->filled('date_from')) {
            $query->whereDate('created_at', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('created_at', '<=', $request->date_to);
        }
        if ($request->filled('search')) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('payment_reference', 'like', "%{$search}%")
                    ->orWhereHas('user', fn($u) => $u->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%"));
            });
        }

        $subscriptions = $query->orderBy('created_at', 'desc')->paginate($request->input('per_page', 20));

        // ✅ FIX: Auto-mark expired subscriptions
        $expiredSubscriptions = Subscription::where('status', Subscription::STATUS_ACTIVE)
            ->where('expiry_date', '<', now())
            ->get();

        foreach ($expiredSubscriptions as $expiredSub) {
            $expiredSub->update(['status' => Subscription::STATUS_EXPIRED]);
            
            // Update user status
            if ($expiredSub->user) {
                $expiredSub->user->update([
                    'subscription_status' => 'expired',
                ]);
            }
        }

        return $this->successResponse([
            'data'       => $subscriptions->map(fn($sub) => [
                'id'               => $sub->id,
                'user'             => $sub->user ? [
                    'id'    => $sub->user->id,
                    'name'  => $sub->user->name,
                    'email' => $sub->user->email,
                    'phone' => $sub->user->phone,
                ] : null,
                'rate_card'        => $sub->rateCard ? [
                    'id'       => $sub->rateCard->id,
                    'name'     => $sub->rateCard->name,
                    'price'    => $sub->rateCard->formatted_price,
                    'duration' => $sub->rateCard->duration_days . ' days',
                ] : null,
                'status'           => $sub->status,
                'status_label'     => $sub->status_label,
                'start_date'       => $sub->start_date,
                'expiry_date'      => $sub->expiry_date,
                'days_remaining'   => $sub->days_remaining,
                'amount'           => number_format($sub->amount_paid, 0) . ' ' . $sub->currency,
                'payment_method'   => $sub->payment_method,
                'payment_reference'=> $sub->payment_reference,
                'payment_proof'    => $sub->payment_proof ? url('storage/' . $sub->payment_proof) : null,
                'approved_at'      => $sub->approved_at,
                'approved_by'      => $sub->approver ? ['id' => $sub->approver->id, 'name' => $sub->approver->name] : null,
                'admin_notes'      => $sub->admin_notes,
                'created_at'       => $sub->created_at,
                'invoice'          => $sub->invoice ? [
                    'id'           => $sub->invoice->id,
                    'number'       => $sub->invoice->invoice_number,
                    'amount'       => $sub->invoice->formatted_amount,
                    'status'       => $sub->invoice->status,
                    'status_label' => $sub->invoice->status_label,
                    'pdf_url'      => $sub->invoice->pdf_path ? url('storage/' . $sub->invoice->pdf_path) : null,
                    'created_at'   => $sub->invoice->created_at,
                    'paid_at'      => $sub->invoice->paid_at,
                ] : null,
            ]),
            'pagination' => [
                'total'        => $subscriptions->total(),
                'per_page'     => $subscriptions->perPage(),
                'current_page' => $subscriptions->currentPage(),
                'last_page'    => $subscriptions->lastPage(),
            ],
            'filters'    => [
                'pending_count'  => Subscription::where('status', Subscription::STATUS_PENDING)->count(),
                'active_count'   => Subscription::where('status', Subscription::STATUS_ACTIVE)
                    ->where('expiry_date', '>', now())
                    ->count(),
                'expired_count'  => Subscription::where(function($query) {
                    $query->where('status', Subscription::STATUS_EXPIRED)
                        ->orWhere('expiry_date', '<=', now());
                })->count(),
                'cancelled_count'=> Subscription::where('status', Subscription::STATUS_CANCELLED)->count(),
            ],
        ], 'Subscriptions retrieved successfully');
    }

    /**
     * Admin: Approve a subscription.
     * POST /api/v16/admin/subscriptions/{id}/approve
     */
    public function approve(Request $request, $id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.approve'))) {
            return $this->forbidden('You need administrator role or subscriptions.approve permission.');
        }

        $subscription = Subscription::with(['user', 'rateCard'])->findOrFail($id);

        if ($subscription->status !== Subscription::STATUS_PENDING) {
            return $this->errorResponse('This subscription is not pending approval.', 422);
        }

        // ✅ FIX: Check if user already has an active subscription before approving
        $user = $subscription->user;
        if ($user->hasActiveSubscription()) {
            return $this->errorResponse(
                "This user already has an active subscription. It will expire on {$user->subscription_expires_at->format('Y-m-d H:i:s')}.",
                422
            );
        }

        DB::beginTransaction();

        try {
            $rateCard = $subscription->rateCard;

            $expiryDate = now()->addDays($rateCard->duration_days);

            $subscription->update([
                'status'      => Subscription::STATUS_ACTIVE,
                'start_date'  => now(),
                'expiry_date' => $expiryDate,
                'approved_at' => now(),
                'approved_by' => $request->user()->id,
            ]);

            // ✅ FIX: Update user's subscription status
            $user->update([
                'subscription_status'      => 'active',
                'subscription_expires_at'  => $expiryDate,
                'current_subscription_id'  => $subscription->id,
            ]);

            if ($subscription->invoice) {
                $subscription->invoice->update([
                    'status'  => Invoice::STATUS_PAID,
                    'paid_at' => now(),
                ]);
                $this->generatePdfInvoice($subscription->invoice);
            }

            // Notify user
            $this->createNotification(
                $user->id,
                'Subscription Approved! 🎉',
                "Your {$rateCard->name} subscription has been approved. Your account is now active until {$expiryDate->format('M d, Y')}.",
                'subscription_approved',
                [
                    'subscription_id' => $subscription->id,
                    'rate_card'       => $rateCard->name,
                    'expiry_date'     => $expiryDate->toIso8601String(),
                    'invoice_number'  => $subscription->invoice?->invoice_number,
                ]
            );

            $this->sendSubscriptionApprovedEmail($user, $subscription);
            $this->logAudit('approve_subscription', 'subscription', $subscription->id, "Subscription approved by admin {$request->user()->id}");

            DB::commit();

            return $this->successResponse([
                'subscription' => $subscription->load(['rateCard', 'user', 'invoice']),
                'user' => [
                    'id'                    => $user->id,
                    'name'                  => $user->name,
                    'subscription_status'   => $user->subscription_status,
                    'expires_at'            => $user->subscription_expires_at,
                ],
            ], 'Subscription approved successfully.');

        } catch (\Exception $e) {
            DB::rollBack();
            \Log::error('Failed to approve subscription: ' . $e->getMessage());
            return $this->serverError('Failed to approve subscription: ' . $e->getMessage());
        }
    }

    /**
     * Admin: Reject a subscription.
     * POST /api/v16/admin/subscriptions/{id}/reject
     */
    public function reject(Request $request, $id)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.approve'))) {
            return $this->forbidden('You need administrator role or subscriptions.approve permission.');
        }

        $request->validate(['reason' => 'nullable|string|max:1000']);

        $subscription = Subscription::findOrFail($id);

        if ($subscription->status !== Subscription::STATUS_PENDING) {
            return $this->errorResponse('This subscription is not pending approval.', 422);
        }

        DB::beginTransaction();

        try {
            $subscription->update([
                'status'      => Subscription::STATUS_CANCELLED,
                'admin_notes' => $request->reason ?? 'Rejected by admin',
            ]);

            if ($subscription->invoice) {
                $subscription->invoice->update(['status' => Invoice::STATUS_CANCELLED]);
            }

            $this->createNotification(
                $subscription->user_id,
                'Subscription Rejected',
                "Your subscription request has been rejected. Reason: " . ($request->reason ?? 'No reason provided'),
                'subscription_rejected',
                [
                    'subscription_id' => $subscription->id,
                    'reason'          => $request->reason ?? 'No reason provided',
                ]
            );

            $this->logAudit('reject_subscription', 'subscription', $subscription->id, "Subscription rejected by admin {$request->user()->id}");

            DB::commit();

            return $this->successResponse($subscription, 'Subscription rejected.');

        } catch (\Exception $e) {
            DB::rollBack();
            return $this->serverError('Failed to reject subscription: ' . $e->getMessage());
        }
    }

    /**
     * Admin: Get subscription statistics.
     * GET /api/v16/admin/subscriptions/stats
     */
    public function stats(Request $request)
    {
        $user = auth()->user();
        if (!$user || (!$user->hasRole('ADMINISTRATOR') && !$user->can('subscriptions.view'))) {
            return $this->forbidden('You need administrator role or subscriptions.view permission.');
        }

        // ✅ FIX: Auto-mark expired subscriptions
        $expiredSubscriptions = Subscription::where('status', Subscription::STATUS_ACTIVE)
            ->where('expiry_date', '<', now())
            ->get();

        foreach ($expiredSubscriptions as $expiredSub) {
            $expiredSub->update(['status' => Subscription::STATUS_EXPIRED]);
            
            if ($expiredSub->user) {
                $expiredSub->user->update([
                    'subscription_status' => 'expired',
                ]);
            }
        }

        return $this->successResponse([
            'total'             => Subscription::count(),
            'pending'           => Subscription::where('status', Subscription::STATUS_PENDING)->count(),
            'active'            => Subscription::where('status', Subscription::STATUS_ACTIVE)
                ->where('expiry_date', '>', now())
                ->count(),
            'expired'           => Subscription::where(function($query) {
                $query->where('status', Subscription::STATUS_EXPIRED)
                    ->orWhere('expiry_date', '<=', now());
            })->count(),
            'cancelled'         => Subscription::where('status', Subscription::STATUS_CANCELLED)->count(),
            'total_revenue'     => Subscription::where('status', Subscription::STATUS_ACTIVE)->sum('amount_paid'),
            'monthly_revenue'   => Subscription::where('status', Subscription::STATUS_ACTIVE)->whereMonth('created_at', now()->month)->sum('amount_paid'),
            'active_users'      => User::where('subscription_status', 'active')->count(),
            'expired_users'     => User::where('subscription_status', 'expired')->count(),
            'payment_breakdown' => Subscription::select('payment_method', \DB::raw('count(*) as count'))
                ->whereNotNull('payment_method')
                ->groupBy('payment_method')
                ->get(),
            'revenue_by_card'   => Subscription::select('rate_cards.name', \DB::raw('sum(subscriptions.amount_paid) as total'))
                ->join('rate_cards', 'subscriptions.rate_card_id', '=', 'rate_cards.id')
                ->where('subscriptions.status', Subscription::STATUS_ACTIVE)
                ->groupBy('rate_cards.name')
                ->get(),
        ], 'Subscription statistics retrieved.');
    }

    /*
    |--------------------------------------------------------------------------
    | PRIVATE HELPERS
    |--------------------------------------------------------------------------
    */

    private function generatePdfInvoice(Invoice $invoice): void
    {
        try {
            $invoice->load(['user', 'rateCard', 'subscription']);
            $pdf = app('dompdf.wrapper')->loadView('invoices.invoice', compact('invoice'));
            $path = 'invoices/invoice_' . $invoice->invoice_number . '.pdf';
            $fullPath = storage_path('app/public/' . $path);

            if (!file_exists(dirname($fullPath))) {
                mkdir(dirname($fullPath), 0775, true);
            }

            $pdf->save($fullPath);
            $invoice->update(['pdf_path' => $path]);

        } catch (\Exception $e) {
            \Log::error('Failed to generate invoice PDF: ' . $e->getMessage(), [
                'invoice_id'     => $invoice->id,
                'invoice_number' => $invoice->invoice_number,
            ]);
        }
    }

    private function createNotification(int $userId, string $title, string $body, string $type, array $data = []): void
    {
        try {
            Notification::create([
                'user_id' => $userId,
                'title'   => $title,
                'body'    => $body,
                'type'    => $type,
                'data'    => json_encode($data),
                'is_read' => false,
            ]);
        } catch (\Exception $e) {
            \Log::error('Failed to create notification: ' . $e->getMessage());
        }
    }

    private function notifyAdminsNewSubscription(Subscription $subscription, Invoice $invoice): void
    {
        try {
            $admins = User::role('ADMINISTRATOR')->get();
            foreach ($admins as $admin) {
                $this->createNotification(
                    $admin->id,
                    'New Subscription Request',
                    "User {$subscription->user->name} has requested a {$subscription->rateCard->name} subscription. Invoice: {$invoice->invoice_number}",
                    'admin_new_subscription',
                    [
                        'subscription_id' => $subscription->id,
                        'user_id'         => $subscription->user_id,
                        'user_name'       => $subscription->user->name,
                        'rate_card'       => $subscription->rateCard->name,
                        'amount'          => $subscription->rateCard->formatted_price,
                        'invoice_number'  => $invoice->invoice_number,
                    ]
                );
            }
        } catch (\Exception $e) {
            \Log::error('Failed to notify admins: ' . $e->getMessage());
        }
    }

    private function sendSubscriptionApprovedEmail(User $user, Subscription $subscription): void
    {
        try {
            Mail::send('emails.subscription-approved', [
                'user'        => $user,
                'subscription'=> $subscription,
                'expiry_date' => $subscription->expiry_date->format('M d, Y'),
                'rate_card'   => $subscription->rateCard->name,
                'invoice'     => $subscription->invoice,
            ], function ($message) use ($user) {
                $message->to($user->email)
                        ->subject('Your Subscription Has Been Approved! 🎉');
            });
        } catch (\Exception $e) {
            \Log::error('Failed to send subscription approved email: ' . $e->getMessage());
        }
    }

    /**
     * Check and update expired subscriptions (public method for cron/command).
     */
    public function checkExpiredSubscriptions()
    {
        $expiredSubscriptions = Subscription::where('status', Subscription::STATUS_ACTIVE)
            ->where('expiry_date', '<', now())
            ->get();

        $count = 0;
        foreach ($expiredSubscriptions as $subscription) {
            $subscription->update(['status' => Subscription::STATUS_EXPIRED]);
            
            if ($subscription->user) {
                $subscription->user->update([
                    'subscription_status' => 'expired',
                ]);
                $count++;
            }
        }

        return $this->successResponse([
            'expired_count' => $count,
            'message' => "{$count} subscriptions marked as expired.",
        ], 'Expired subscriptions updated.');
    }
}