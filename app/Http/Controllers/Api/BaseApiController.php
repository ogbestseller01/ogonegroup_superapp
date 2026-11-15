<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Response;

class BaseApiController extends Controller
{
    /**
     * Return a successful JSON response.
     *
     * @param mixed $data
     * @param string $message
     * @param int $code
     * @return JsonResponse
     */
    protected function successResponse($data = null, string $message = 'Success', int $code = Response::HTTP_OK): JsonResponse
    {
        return response()->json([
            'status' => 'success',
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    /**
     * Return a 201 Created response.
     *
     * @param mixed $data
     * @param string $message
     * @return JsonResponse
     */
    protected function created($data = null, string $message = 'Resource created'): JsonResponse
    {
        return $this->successResponse($data, $message, Response::HTTP_CREATED);
    }

    /**
     * Return a 400 Bad Request response.
     *
     * @param string $message
     * @return JsonResponse
     */
    protected function badRequest(string $message = 'Bad request'): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], Response::HTTP_BAD_REQUEST);
    }

    /**
     * Return a 401 Unauthorized response.
     *
     * @param string $message
     * @return JsonResponse
     */
    protected function unauthorized(string $message = 'Unauthorized'): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], Response::HTTP_UNAUTHORIZED);
    }

    /**
     * Return a 403 Forbidden response.
     *
     * @param string $message
     * @return JsonResponse
     */
    protected function forbidden(string $message = 'Forbidden'): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], Response::HTTP_FORBIDDEN);
    }

    /**
     * Return a 404 Not Found response.
     *
     * @param string $message
     * @return JsonResponse
     */
    protected function notFound(string $message = 'Not found'): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], Response::HTTP_NOT_FOUND);
    }

    /**
     * Return a 500 Internal Server Error response.
     *
     * @param string $message
     * @return JsonResponse
     */
    protected function serverError(string $message = 'Server error'): JsonResponse
    {
        return response()->json(['status' => 'error', 'message' => $message], Response::HTTP_INTERNAL_SERVER_ERROR);
    }

    /**
     * Check if the current user has a specific permission.
     * If no user is authenticated, abort with 401.
     * If the user lacks the permission, abort with 403.
     *
     * @param string $permission
     * @return void
     */
    protected function checkPermission(string $permission): void
    {
        $user = auth()->user();

        // If there is no authenticated user, respond with 401
        if (!$user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthenticated.');
        }

        // If the user does not have the required permission, respond with 403
        if (!$user->can($permission)) {
            abort(Response::HTTP_FORBIDDEN, 'Missing permission: ' . $permission);
        }
    }

    /**
     * Return a generic error response (default 422 Unprocessable Entity).
     *
     * @param string $message
     * @param int $code
     * @return JsonResponse
     */
    protected function errorResponse(string $message, int $code = Response::HTTP_UNPROCESSABLE_ENTITY): JsonResponse
    {
        return response()->json([
            'status' => 'error',
            'message' => $message,
        ], $code);
    }
}