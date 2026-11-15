<?php

namespace App\Http\Controllers\Api;

use App\Models\MiniApp;
use App\Models\MiniAppQr;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class MiniAppQrController extends BaseApiController
{
    // ──────────────────────────────────────────────
    // ADMIN
    // ──────────────────────────────────────────────

    /** GET /api/v24/admin/mini-app-qrs?search=&mini_app_id=&status=&per_page=&page= */
    public function index(Request $request)
    {
        $q = MiniAppQr::with('miniApp')->latest('id');

        if ($s = trim((string) $request->query('search', ''))) {
            $q->where(function ($w) use ($s) {
                $w->where('label', 'like', "%{$s}%")
                    ->orWhere('token', 'like', "%{$s}%")
                    ->orWhereHas('miniApp', fn ($m) => $m
                        ->where('name', 'like', "%{$s}%")
                        ->orWhere('slug', 'like', "%{$s}%"));
            });
        }

        if ($appId = $request->query('mini_app_id')) {
            $q->where('mini_app_id', $appId);
        }

        match ($request->query('status')) {
            'active'   => $q->valid(),
            'expired'  => $q->expired(),
            'revoked'  => $q->revoked(),
            'expiring' => $q->valid()
                ->whereNotNull('expires_at')
                ->where('expires_at', '<=', now()->addDays(7)),
            default    => null,
        };

        $perPage = max(1, min((int) $request->query('per_page', 10), 100));
        $page    = $q->paginate($perPage)->through(fn (MiniAppQr $r) => $this->format($r));

        return $this->successResponse($page);
    }

    /** GET /api/v24/admin/mini-app-qrs/stats */
    public function stats()
    {
        return $this->successResponse([
            'total'    => MiniAppQr::count(),
            'active'   => MiniAppQr::valid()->count(),
            'expiring' => MiniAppQr::valid()
                ->whereNotNull('expires_at')
                ->where('expires_at', '<=', now()->addDays(7))
                ->count(),
            'expired'  => MiniAppQr::expired()->count(),
            'revoked'  => MiniAppQr::revoked()->count(),
        ]);
    }

    /** GET /api/v24/admin/mini-app-qrs/{id} */
    public function show(int $id)
    {
        $qr = MiniAppQr::with('miniApp')->findOrFail($id);

        return $this->successResponse($this->format($qr));
    }

    /** POST /api/v24/admin/mini-app-qrs */
    public function store(Request $request)
    {
        $data = $request->validate([
            'mini_app_id' => 'required|integer|exists:mini_apps,id',
            'label'       => 'nullable|string|max:120',
            'validity'    => ['required', Rule::in(MiniAppQr::VALIDITIES)],
        ]);

        $qr = MiniAppQr::create([
            'mini_app_id' => $data['mini_app_id'],
            'label'       => $data['label'] ?? null,
            'token'       => MiniAppQr::newToken(),
            'validity'    => $data['validity'],
            'expires_at'  => MiniAppQr::expiryFor($data['validity']),
            'is_active'   => true,
            'created_by'  => $request->user()?->id,
        ]);

        return $this->created($this->format($qr->load('miniApp')), 'QR code created.');
    }

    /**
     * PUT /api/v24/admin/mini-app-qrs/{id}
     * Edit label, revoke / re-activate, or renew: sending `validity`
     * restarts the expiry from today.
     */
    public function update(Request $request, int $id)
    {
        $qr = MiniAppQr::findOrFail($id);

        $data = $request->validate([
            'label'     => 'nullable|string|max:120',
            'is_active' => 'sometimes|boolean',
            'validity'  => ['sometimes', Rule::in(MiniAppQr::VALIDITIES)],
        ]);

        if (array_key_exists('label', $data)) {
            $qr->label = $data['label'];
        }
        if (array_key_exists('is_active', $data)) {
            $qr->is_active = $data['is_active'];
        }
        if (isset($data['validity'])) {
            $qr->validity   = $data['validity'];
            $qr->expires_at = MiniAppQr::expiryFor($data['validity']);
        }

        $qr->save();

        return $this->successResponse($this->format($qr->load('miniApp')), 'QR code updated.');
    }

    /** DELETE /api/v24/admin/mini-app-qrs/{id} */
    public function destroy(int $id)
    {
        MiniAppQr::findOrFail($id)->delete();

        return $this->successResponse(null, 'QR code deleted.');
    }

    // ──────────────────────────────────────────────
    // PUBLIC (used by the Flutter app and <img> tags)
    // ──────────────────────────────────────────────

    /**
     * POST /api/v24/mini-apps/qr/verify   body: { "token": "..." }
     * Always HTTP 200. Read `success` and `data.reason` (expired | invalid).
     */
    public function verify(Request $request)
    {
        $token = (string) $request->input('token', '');

        $qr = $token !== ''
            ? MiniAppQr::with('miniApp')->where('token', $token)->first()
            : null;

        if (!$qr || !$qr->is_active || !$qr->miniApp || !$qr->miniApp->is_active) {
            return $this->verifyFail('invalid', 'This QR code is not valid.');
        }

        if ($qr->is_expired) {
            return $this->verifyFail('expired', 'This QR code has expired.');
        }

        $qr->increment('scans_count', 1, ['last_scanned_at' => now()]);

        return response()->json([
            'success' => true,
            'status'  => 'success',
            'message' => 'OK',
            'data'    => [
                'slug'       => $qr->miniApp->slug,
                'expires_at' => $qr->expires_at?->toIso8601String(),
            ],
        ]);
    }

    /** GET /api/v24/mini-apps/qr/{token}/image?format=svg|png&size=512 */
    public function image(Request $request, string $token)
    {
        $qr = MiniAppQr::with('miniApp')->where('token', $token)->first();

        if (!$qr || !$qr->miniApp) {
            return $this->notFound('QR code not found.');
        }

        $format = $request->query('format', 'svg') === 'png' ? 'png' : 'svg';
        $size   = max(128, min((int) $request->query('size', 512), 1024));

        // Use the helper method to generate QR with logo
        $image = $this->generateQrWithLogo($qr->qr_payload, $format, $size);

        return response($image, 200, [
            'Content-Type'  => $format === 'png' ? 'image/png' : 'image/svg+xml',
            'Cache-Control' => 'public, max-age=3600',
        ]);
    }

    // ──────────────────────────────────────────────

    private function verifyFail(string $reason, string $message)
    {
        return response()->json([
            'success' => false,
            'status'  => 'error',
            'message' => $message,
            'data'    => ['reason' => $reason],
        ]);
    }

    private function format(MiniAppQr $r): array
    {
        return [
            'id'              => $r->id,
            'mini_app_id'     => $r->mini_app_id,
            'mini_app'        => $r->miniApp ? [
                'id'   => $r->miniApp->id,
                'slug' => $r->miniApp->slug,
                'name' => $r->miniApp->name,
            ] : null,
            'label'           => $r->label,
            'token'           => $r->token,
            'validity'        => $r->validity,
            'expires_at'      => $r->expires_at?->toIso8601String(),
            'days_left'       => $r->days_left,
            'status'          => $r->status,
            'is_active'       => $r->is_active,
            'scans_count'     => $r->scans_count,
            'last_scanned_at' => $r->last_scanned_at?->toIso8601String(),
            'qr_payload'      => $r->qr_payload,
            'qr_image_url'    => url("/api/v24/mini-apps/qr/{$r->token}/image"),
            'created_at'      => $r->created_at?->toIso8601String(),
        ];
    }

    /**
     * Generates a QR code with the company logo embedded in the center.
     */
    private function generateQrWithLogo(string $payload, string $format, int $size)
    {
        $logoPath = public_path('all_images/logo.png');

        if ($format === 'png') {
            $qr = QrCode::format('png')->size($size)->margin(2)->errorCorrection('H');
            if (file_exists($logoPath)) {
                try {
                    // Requires intervention/image package
                    $qr->merge($logoPath, 0.22, true);
                } catch (\Exception $e) {
                    // Fallback to normal QR if merge fails
                }
            }
            return $qr->generate($payload);
        }

        // SVG Generation
        $image = QrCode::format('svg')->size($size)->margin(2)->errorCorrection('H')->generate($payload);

        if (file_exists($logoPath)) {
            $logoData = base64_encode(file_get_contents($logoPath));
            $logoSize = $size * 0.22; // 22% of the QR size
            $logoPos = ($size - $logoSize) / 2;
            $padding = $size * 0.02; // small padding around logo

            // White background for the logo to improve scannability
            $svgRect = '<rect x="'.($logoPos - $padding).'" y="'.($logoPos - $padding).'" width="'.($logoSize + $padding * 2).'" height="'.($logoSize + $padding * 2).'" fill="#FFFFFF" rx="'.($size * 0.03).'" />';
            $svgLogo = '<image x="'.$logoPos.'" y="'.$logoPos.'" width="'.$logoSize.'" height="'.$logoSize.'" href="data:image/png;base64,'.$logoData.'" />';

            $image = str_replace('</svg>', $svgRect . $svgLogo . '</svg>', $image);
        }

        return $image;
    }
}