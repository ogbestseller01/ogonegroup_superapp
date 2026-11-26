<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    */

    'mailgun' => [
        'domain'   => env('MAILGUN_DOMAIN'),
        'secret'   => env('MAILGUN_SECRET'),
        'endpoint' => env('MAILGUN_ENDPOINT', 'api.mailgun.net'),
        'scheme'   => 'https',
    ],

    'postmark' => [
        'token' => env('POSTMARK_TOKEN'),
    ],

    'ses' => [
        'key'    => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    // Google Sign-In (mobile ID-token flow).
    // GOOGLE_CLIENT_IDS = Web client ID(s), comma separated, no spaces.
    'google' => [
        'client_ids' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('GOOGLE_CLIENT_IDS', ''))
        ))),
    ],

    // Sign in with Apple (mobile identity-token flow).
    // APPLE_CLIENT_IDS = iOS bundle ID(s), comma separated, no spaces.
    'apple' => [
        'client_ids' => array_values(array_filter(array_map(
            'trim',
            explode(',', (string) env('APPLE_CLIENT_IDS', ''))
        ))),
    ],

    'rafikisms' => [
        'base_url'  => env('RAFIKISMS_BASE_URL', 'https://api.rafikisms.com'),
        'api_key'   => env('RAFIKISMS_API_KEY'),
        'sender_id' => env('RAFIKISMS_SENDER_ID', 'OG ONEGROUP'),
        'timeout'   => env('RAFIKISMS_TIMEOUT', 15),
    ],

    

];