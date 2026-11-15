<?php

use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| Web Routes
|--------------------------------------------------------------------------
*/

Route::get('/', function () {
    return view('welcome');
});

// 👇 WebSocket test route
Route::get('/laravel-websockets', function () {
    return '<h1 style="color: green;">✅ WebSocket Server is Running!</h1>
            <p><strong>Port:</strong> 6001</p>
            <p><strong>Server Time:</strong> ' . now() . '</p>
            <p><strong>Status:</strong> Active and listening for connections</p>
            <hr>
            <p>Connect your Flutter app to: <code>http://127.0.0.1:6001</code></p>';
});