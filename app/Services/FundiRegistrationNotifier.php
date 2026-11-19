<?php

namespace App\Services;

use App\Mail\NewFundiRegisteredMail;
use App\Models\Technician;
use App\Models\User;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;

/**
 * Emails every active ADMINISTRATOR when a new fundi registers.
 * Never throws: a mail problem must not break the registration.
 */
class FundiRegistrationNotifier
{
    public static function notifyAdministrators(Technician $technician): void
    {
        try {
            $technician->loadMissing(['user', 'services']);

            $admins = User::role('ADMINISTRATOR')
                ->where('is_active', true)
                ->whereNotNull('email')
                ->where('email', '!=', '')
                ->get();

            if ($admins->isEmpty()) {
                Log::info('No active ADMINISTRATOR with an email to notify', [
                    'technician_id' => $technician->id,
                ]);
                return;
            }

            foreach ($admins as $admin) {
                try {
                    Mail::to($admin->email)->send(new NewFundiRegisteredMail($technician));
                } catch (\Throwable $e) {
                    Log::warning('New fundi email failed', [
                        'admin_id' => $admin->id,
                        'error'    => $e->getMessage(),
                    ]);
                }
            }
        } catch (\Throwable $e) {
            Log::warning('notifyAdministrators failed', ['error' => $e->getMessage()]);
        }
    }
}