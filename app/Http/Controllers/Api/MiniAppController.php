<?php

namespace App\Http\Controllers\Api;

use App\Models\MiniApp;
use Illuminate\Http\Request;
use SimpleSoftwareIO\QrCode\Facades\QrCode;

class MiniAppController extends BaseApiController
{
    // ──────────────────────────────────────────────
    // PUBLIC
    // ──────────────────────────────────────────────

    /** GET /api/v24/mini-apps */
    public function index()
    {
        $apps = MiniApp::active()->ordered()->get()
            ->map(fn (MiniApp $a) => $this->format($a));

        return $this->successResponse($apps);
    }

    /** GET /api/v24/mini-apps/{slug} */
    public function show(string $slug)
    {
        $app = MiniApp::active()->where('slug', $slug)->first();

        if (!$app) {
            return $this->notFound('Mini app not found.');
        }

        return $this->successResponse($this->format($app));
    }

    /**
     * GET /api/v24/mini-apps/{slug}/qr?format=svg|png&size=512
     * SVG needs no PHP extension; PNG needs imagick.
     */
    public function qr(Request $request, string $slug)
    {
        $app = MiniApp::active()->where('slug', $slug)->first();

        if (!$app) {
            return $this->notFound('Mini app not found.');
        }

        $format = $request->query('format', 'svg') === 'png' ? 'png' : 'svg';
        $size   = max(128, min((int) $request->query('size', 512), 1024));

        // Use the helper method to generate QR with logo
        $image = $this->generateQrWithLogo($app->qr_payload, $format, $size);

        return response($image, 200, [
            'Content-Type'  => $format === 'png' ? 'image/png' : 'image/svg+xml',
            'Cache-Control' => 'public, max-age=86400',
        ]);
    }

    /** GET /api/v24/mini-apps-print  (printable sheet of every QR) */
    public function printSheet()
    {
        $apps = MiniApp::active()->ordered()->get();

        return view('mini-apps.print', ['apps' => $apps]);
    }

    // ──────────────────────────────────────────────
    // ADMIN (permission: miniapps.manage)
    // ──────────────────────────────────────────────

    /** POST /api/v24/admin/mini-apps */
    public function store(Request $request)
    {
        $data = $request->validate([
            'slug'           => ['required', 'string', 'max:60', 'regex:/^[a-z0-9_]+$/', 'unique:mini_apps,slug'],
            'name'           => 'required|string|max:120',
            'subtitle'       => 'nullable|string|max:190',
            'is_coming_soon' => 'sometimes|boolean',
            'is_active'      => 'sometimes|boolean',
            'sort_order'     => 'sometimes|integer|min:0',
        ]);

        $app = MiniApp::create($data);

        return $this->created($this->format($app), 'Mini app created.');
    }

    /** PUT /api/v24/admin/mini-apps/{id} */
    public function update(Request $request, int $id)
    {
        $app = MiniApp::findOrFail($id);

        // slug is the QR identity; changing it would break printed codes.
        $data = $request->validate([
            'name'           => 'sometimes|string|max:120',
            'subtitle'       => 'nullable|string|max:190',
            'is_coming_soon' => 'sometimes|boolean',
            'is_active'      => 'sometimes|boolean',
            'sort_order'     => 'sometimes|integer|min:0',
        ]);

        $app->update($data);

        return $this->successResponse($this->format($app->fresh()), 'Mini app updated.');
    }

    /** DELETE /api/v24/admin/mini-apps/{id} */
    public function destroy(int $id)
    {
        MiniApp::findOrFail($id)->delete();

        return $this->successResponse(null, 'Mini app deleted.');
    }

    // ──────────────────────────────────────────────

    private function format(MiniApp $a): array
    {
        return [
            'id'             => $a->id,
            'slug'           => $a->slug,
            'name'           => $a->name,
            'subtitle'       => $a->subtitle,
            'is_coming_soon' => $a->is_coming_soon,
            'is_active'      => $a->is_active,
            'sort_order'     => $a->sort_order,
            'qr_payload'     => $a->qr_payload,
            'qr_url'         => url("/api/v24/mini-apps/{$a->slug}/qr"),
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