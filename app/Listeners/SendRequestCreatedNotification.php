<?php

namespace App\Listeners;

use App\Events\RequestCreated;
use App\Mail\RequestCreatedMail;
use Illuminate\Support\Facades\Mail;

class SendRequestCreatedNotification
{
    public function handle(RequestCreated $event)
    {
        $request = $event->request;
        Mail::to($request->technician->user->email)->send(new RequestCreatedMail($request));
    }
}