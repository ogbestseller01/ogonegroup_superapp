<?php

namespace App\Services;

use App\Mail\ServiceChangeMail;
use App\Models\Service;
use App\Models\TechnicianServiceChangeRequest as ChangeRequest;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

/**
 * Emails for service changes. Runs AFTER the HTTP response and never
 * breaks the request.
 */
class ServiceChangeNotificationService
{
    private const TZ = 'Africa/Dar_es_Salaam';

    /** Recipients are everyone holding this permission (directly or by role). */
    private const APPROVER_PERMISSION = 'service-changes.approve';

    private const TEXT = [
        'en' => [
            'submitted_subject' => 'Service change awaiting approval: :name',
            'submitted_title'   => 'New service change request',
            'submitted_intro'   => ':name has asked to change their services. Please review the request.',
            'approved_subject'  => 'Your service change was approved',
            'approved_title'    => 'Service change approved',
            'approved_intro'    => 'Your profile now shows your updated services.',
            'rejected_subject'  => 'Your service change was rejected',
            'rejected_title'    => 'Service change rejected',
            'rejected_intro'    => 'Your services were not changed. Any new services in this request are now blocked for your account.',
            'greeting'          => 'Hello :name,',
            'section'           => 'Service changes',
            'request'           => 'Request',
            'fundi'             => 'Fundi',
            'phone'             => 'Phone',
            'date'              => 'Submitted',
            'added'             => 'To add',
            'removed'           => 'To remove',
            'reason'            => 'Reason from Fundi',
            'rejection'         => 'Reason for rejection',
            'none'              => 'None',
            'button'            => 'Review request',
            'footer'            => 'This is an automatic message from Nearby Fundi.',
        ],
        'sw' => [
            'submitted_subject' => 'Ombi la kubadili huduma linasubiri idhini: :name',
            'submitted_title'   => 'Ombi jipya la kubadili huduma',
            'submitted_intro'   => ':name ameomba kubadili huduma zake. Tafadhali lipitie ombi hili.',
            'approved_subject'  => 'Mabadiliko ya huduma zako yameidhinishwa',
            'approved_title'    => 'Mabadiliko yameidhinishwa',
            'approved_intro'    => 'Wasifu wako sasa unaonyesha huduma zako mpya.',
            'rejected_subject'  => 'Mabadiliko ya huduma zako yamekataliwa',
            'rejected_title'    => 'Mabadiliko yamekataliwa',
            'rejected_intro'    => 'Huduma zako hazijabadilishwa. Huduma mpya zilizo kwenye ombi hili sasa zimezuiwa kwenye akaunti yako.',
            'greeting'          => 'Habari :name,',
            'section'           => 'Mabadiliko ya huduma',
            'request'           => 'Ombi',
            'fundi'             => 'Fundi',
            'phone'             => 'Simu',
            'date'              => 'Lilitumwa',
            'added'             => 'Za kuongeza',
            'removed'           => 'Za kuondoa',
            'reason'            => 'Sababu ya Fundi',
            'rejection'         => 'Sababu ya kukataliwa',
            'none'              => 'Hakuna',
            'button'            => 'Pitia ombi',
            'footer'            => 'Huu ni ujumbe wa moja kwa moja kutoka Nearby Fundi.',
        ],
    ];

    public static function dispatchSubmitted(int $changeId): void
    {
        self::later(fn () => app(self::class)->notifyApprovers($changeId));
    }

    public static function dispatchDecision(int $changeId): void
    {
        self::later(fn () => app(self::class)->notifyFundi($changeId));
    }

    private static function later(\Closure $job): void
    {
        try {
            dispatch($job)->afterResponse();
        } catch (Throwable $e) {
            Log::warning('Service change notification dispatch failed', ['error' => $e->getMessage()]);
        }
    }

    public function notifyApprovers(int $changeId): void
    {
        try {
            $change = ChangeRequest::with('technician.user')->find($changeId);
            if (!$change || !$change->technician?->user) {
                return;
            }

            $approvers = User::permission(self::APPROVER_PERMISSION)
                ->where('is_active', true)
                ->whereNotNull('email')
                ->get();

            if ($approvers->isEmpty()) {
                Log::warning('No approver with an email for service changes', ['change_id' => $changeId]);
                return;
            }

            $sent = 0;

            foreach ($approvers as $admin) {
                // One failed address must not stop the others.
                try {
                    Mail::to($admin->email)->send($this->buildMail($change, $admin, 'submitted'));
                    $sent++;
                } catch (Throwable $e) {
                    Log::warning('Service change admin email failed', [
                        'change_id' => $changeId,
                        'admin_id'  => $admin->id,
                        'error'     => $e->getMessage(),
                    ]);
                }
            }

            if ($sent > 0) {
                $change->update(['admin_notified_at' => now()]);
            }
        } catch (Throwable $e) {
            Log::warning('Service change admin notification failed', [
                'change_id' => $changeId,
                'error'     => $e->getMessage(),
            ]);
        }
    }

    public function notifyFundi(int $changeId): void
    {
        try {
            $change = ChangeRequest::with('technician.user')->find($changeId);
            $user   = $change?->technician?->user;

            if (!$user || empty($user->email) || $change->isPending()) {
                return;
            }

            Mail::to($user->email)->send($this->buildMail($change, $user, $change->status));
        } catch (Throwable $e) {
            Log::warning('Service change decision email failed', [
                'change_id' => $changeId,
                'error'     => $e->getMessage(),
            ]);
        }
    }

    /** $type: submitted | approved | rejected */
    private function buildMail(ChangeRequest $change, User $recipient, string $type): ServiceChangeMail
    {
        $locale = $recipient->locale === 'sw' ? 'sw' : 'en';
        $t      = self::TEXT[$locale];
        $fundi  = $change->technician->user;
        $swap   = [':name' => (string) $fundi->name];

        $rows = [$t['request'] => '#' . $change->id];

        if ($type === 'submitted') {
            $rows[$t['fundi']] = $fundi->name;
            $rows[$t['phone']] = $fundi->phone ?: '-';
        }

        $rows[$t['date']] = $change->created_at
            ?->copy()->timezone(self::TZ)->format('d/m/Y H:i') . ' (EAT)';

        $adminUrl = (string) config('services.admin_panel.url', '');

        return new ServiceChangeMail(strtr($t["{$type}_subject"], $swap), [
            'locale'          => $locale,
            'type'            => $type,
            'title'           => $t["{$type}_title"],
            'greeting'        => strtr($t['greeting'], [':name' => (string) $recipient->name]),
            'intro'           => strtr($t["{$type}_intro"], $swap),
            'rows'            => $rows,
            'section'         => $t['section'],
            'addedLabel'      => $t['added'],
            'added'           => $this->serviceLines($change->added_service_ids ?? [], $locale),
            'removedLabel'    => $t['removed'],
            'removed'         => $this->serviceLines($change->removed_service_ids ?? [], $locale),
            'none'            => $t['none'],
            'reasonLabel'     => $t['reason'],
            'reason'          => $change->reason,
            'rejectionLabel'  => $t['rejection'],
            'rejectionReason' => $change->rejection_reason,
            'buttonText'      => $t['button'],
            'buttonUrl'       => $type === 'submitted' && $adminUrl !== '' ? $adminUrl : null,
            'footer'          => $t['footer'],
        ]);
    }

    /** "Service name (Category, Category)" for each id. */
    private function serviceLines(array $ids, string $locale): array
    {
        return Service::with('categories')->whereIn('id', $ids)->orderBy('name')->get()
            ->map(function (Service $s) use ($locale) {
                $categories = $s->categories
                    ->map(fn ($c) => $c->getNameForLocale($locale))
                    ->implode(', ');

                return $s->getNameForLocale($locale) . ($categories !== '' ? " ({$categories})" : '');
            })
            ->all();
    }
}
