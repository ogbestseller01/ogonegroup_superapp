<?php

namespace App\Mail;

use App\Models\Technician;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class NewFundiRegisteredMail extends Mailable
{
    use Queueable, SerializesModels;

    public Technician $technician;

    public function __construct(Technician $technician)
    {
        $this->technician = $technician->loadMissing(['user', 'services']);
    }

    public function build()
    {
        $user = $this->technician->user;

        $services = $this->technician->services
            ->pluck('name')
            ->filter()
            ->values()
            ->all();

        $fundiName = $user->name ?? 'Unknown';
        $area      = $this->technician->area ?: 'Not specified';

        return $this->subject("New fundi registered: {$fundiName} ({$area})")
                    ->view('emails.new_fundi_registered')
                    ->with([
                        'fundiName'    => $fundiName,
                        'fundiPhone'   => $user->phone ?? null,
                        'fundiEmail'   => $user->email ?? null,
                        'area'         => $area,
                        'services'     => $services,
                        'registeredAt' => $this->technician->created_at ?? now(),
                    ]);
    }
}