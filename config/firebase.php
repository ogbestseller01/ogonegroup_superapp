<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Firebase Credentials
    |--------------------------------------------------------------------------
    */
    'credentials' => env('FIREBASE_CREDENTIALS', 'firebase/nearbyfundi-firebase-adminsdk.json'),

    /*
    |--------------------------------------------------------------------------
    | Send Notifications
    |--------------------------------------------------------------------------
    | Set to true in production. When false, no FCM pushes are sent at all.
    */
    'send_notifications' => env('FCM_SEND_NOTIFICATIONS', true),

    /*
    |--------------------------------------------------------------------------
    | Default Android Channel
    |--------------------------------------------------------------------------
    | Must match the channel ID declared in the Flutter app's
    | NotificationProvider (_channelId = 'fundi_channel').
    */
    'android_channel_id' => 'fundi_channel',

    /*
    |--------------------------------------------------------------------------
    | FCM Configuration
    |--------------------------------------------------------------------------
    */
    'fcm' => [
        'timeout'     => 30,
        'retry'       => 3,
        'retry_delay' => 1000,
    ],
];