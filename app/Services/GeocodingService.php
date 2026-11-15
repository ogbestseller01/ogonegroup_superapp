<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class GeocodingService
{
    /**
     * Geocode a place name to lat/lng coordinates using OpenStreetMap.
     * ✅ This is the main method called from registerFundi
     */
    public function geocode(string $place): ?array
    {
        // Clean the input
        $place = trim($place);
        if (empty($place)) {
            return null;
        }

        $cacheKey = 'geocode_' . md5(strtolower($place));

        return Cache::remember($cacheKey, 86400, function () use ($place) {
            Log::info('GeocodingService: Searching for place', ['place' => $place]);

            // Step 1: Try exact match with Tanzania bias
            $result = $this->searchNominatim($place, true);
            if ($result) {
                Log::info('GeocodingService: Found with Tanzania bias', ['place' => $place]);
                return $result;
            }

            // Step 2: Try without country bias (broader search)
            $result = $this->searchNominatim($place, false);
            if ($result) {
                Log::info('GeocodingService: Found without bias', ['place' => $place]);
                return $result;
            }

            // Step 3: Try with "Tanzania" appended
            $result = $this->searchNominatim($place . ', Tanzania', true);
            if ($result) {
                Log::info('GeocodingService: Found with Tanzania appended', ['place' => $place]);
                return $result;
            }

            // Step 4: Try with "Dar es Salaam" if it's a Dar location
            $result = $this->searchNominatim($place . ', Dar es Salaam, Tanzania', true);
            if ($result) {
                Log::info('GeocodingService: Found with Dar es Salaam context', ['place' => $place]);
                return $result;
            }

            Log::warning('GeocodingService: No results found', ['place' => $place]);
            return null;
        });
    }

    /**
     * Search Nominatim API
     */
    private function searchNominatim(string $query, bool $biasTanzania = true): ?array
    {
        try {
            $params = [
                'q' => $query,
                'format' => 'json',
                'limit' => 1,
                'addressdetails' => 0,
            ];

            // Add Tanzania bias if requested
            if ($biasTanzania) {
                $params['countrycodes'] = 'tz';
            }

            $response = Http::withHeaders([
                'User-Agent' => 'nearbyfundi/1.0 (nyemamudhihirsoft01@gmail.com)'
            ])
            ->timeout(10) // Increased timeout for better reliability
            ->get('https://nominatim.openstreetmap.org/search', $params);

            if ($response->failed()) {
                Log::warning('Nominatim API request failed', [
                    'query' => $query,
                    'status' => $response->status()
                ]);
                return null;
            }

            $data = $response->json();

            if (empty($data) || !isset($data[0]['lat'], $data[0]['lon'])) {
                return null;
            }

            return [
                'lat' => (float) $data[0]['lat'],
                'lng' => (float) $data[0]['lon'],
                'display_name' => $data[0]['display_name'] ?? null,
            ];

        } catch (\Illuminate\Http\Client\ConnectionException $e) {
            Log::error('Nominatim API connection timeout', [
                'query' => $query,
                'error' => $e->getMessage(),
            ]);
            return null;

        } catch (\Exception $e) {
            Log::error('Nominatim API error', [
                'query' => $query,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
    }

    /**
     * Reverse geocode: coordinates → place name.
     */
    public function reverseGeocode(float $lat, float $lng): ?string
    {
        $cacheKey = 'reverse_geocode_' . md5("$lat,$lng");

        return Cache::remember($cacheKey, 86400, function () use ($lat, $lng) {
            try {
                $response = Http::withHeaders([
                    'User-Agent' => 'nearbyfundi/1.0 (nyemamudhihirsoft01@gmail.com)'
                ])
                ->timeout(10)
                ->get('https://nominatim.openstreetmap.org/reverse', [
                    'lat'    => $lat,
                    'lon'    => $lng,
                    'format' => 'json',
                ]);

                if ($response->failed() || empty($response->json())) {
                    return null;
                }

                $data = $response->json();
                $address = $data['address'] ?? [];

                // Return the most specific location name available
                return $address['suburb']
                    ?? $address['neighbourhood']
                    ?? $address['city_district']
                    ?? $address['city']
                    ?? $address['town']
                    ?? $address['village']
                    ?? $address['state']
                    ?? $data['display_name']
                    ?? null;

            } catch (\Exception $e) {
                Log::error('GeocodingService: Reverse geocode error', [
                    'lat'   => $lat,
                    'lng'   => $lng,
                    'error' => $e->getMessage(),
                ]);
                return null;
            }
        });
    }
}