<?php

namespace App\Exceptions;
use Illuminate\Http\Exceptions\PostTooLargeException;


use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Throwable;

class Handler extends ExceptionHandler
{
    /**
     * The list of the inputs that are never flashed to the session on validation exceptions.
     *
     * @var array<int, string>
     */
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    /**
     * Register the exception handling callbacks for the application.
     */
    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
            //
        });
    }

public function render($request, Throwable $exception)
{
    if ($exception instanceof PostTooLargeException) {
        return response()->json([
            'status'  => 'error',
            'message' => 'The uploaded file is too large. Maximum allowed size is 2MB.'
        ], 413);
    }

    return parent::render($request, $exception);
}
}
