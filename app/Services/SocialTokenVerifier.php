<?php

namespace App\Services;

use Firebase\JWT\JWK;
use Firebase\JWT\JWT;
use Google_Client;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/**
 * Verifies identity tokens sent by the mobile apps.
 *
 * Install once:  composer require google/apiclient firebase/php-jwt
 */
class SocialTokenVerifier
{
    /** @return array{sub:string,email:?string,name:?string,picture:?string,email_verified:bool} */
    public function google(string $idToken): array
    {
        $clientIds = array_filter((array) config('services.google.client_ids'));
        if (empty($clientIds)) {
            throw new RuntimeException('Google client IDs are not configured.');
        }

        // The token's "aud" must equal one of our client IDs. The Flutter app sets
        // serverClientId = WEB client ID, so aud = that web client ID on Android and iOS.
        $payload = null;
        foreach ($clientIds as $cid) {
            $client = new Google_Client(['client_id' => $cid]);
            $payload = $client->verifyIdToken($idToken);
            if ($payload) {
                break;
            }
        }

        if (!$payload || empty($payload['sub'])) {
            throw new RuntimeException('Invalid Google token.');
        }

        return [
            'sub'            => (string) $payload['sub'],
            'email'          => $payload['email'] ?? null,
            'name'           => $payload['name'] ?? null,
            'picture'        => $payload['picture'] ?? null,
            'email_verified' => filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN),
        ];
    }

    /** @return array{sub:string,email:?string,email_verified:bool} */
    public function apple(string $identityToken, ?string $rawNonce = null): array
    {
        $audiences = array_filter((array) config('services.apple.client_ids'));
        if (empty($audiences)) {
            throw new RuntimeException('Apple client IDs are not configured.');
        }

        $keys = Cache::remember('apple_jwks', 3600, function () {
            $res = Http::timeout(10)->get('https://appleid.apple.com/auth/keys');
            if (!$res->ok()) {
                throw new RuntimeException('Could not fetch Apple public keys.');
            }
            return $res->json();
        });

        JWT::$leeway = 60;
        $claims = (array) JWT::decode($identityToken, JWK::parseKeySet($keys, 'RS256'));

        if (($claims['iss'] ?? '') !== 'https://appleid.apple.com') {
            throw new RuntimeException('Invalid Apple issuer.');
        }
        if (!in_array($claims['aud'] ?? '', $audiences, true)) {
            throw new RuntimeException('Invalid Apple audience.');
        }
        if (empty($claims['sub'])) {
            throw new RuntimeException('Invalid Apple token.');
        }

        // Replay protection: the app sends sha256(rawNonce) to Apple and rawNonce to us.
        if ($rawNonce !== null && $rawNonce !== '') {
            $expected = hash('sha256', $rawNonce);
            if (!hash_equals($expected, (string) ($claims['nonce'] ?? ''))) {
                throw new RuntimeException('Apple nonce mismatch.');
            }
        }

        return [
            'sub'            => (string) $claims['sub'],
            'email'          => $claims['email'] ?? null,
            'email_verified' => filter_var($claims['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN),
        ];
    }
}