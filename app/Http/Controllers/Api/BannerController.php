<?php
// app/Http/Controllers/Api/BannerController.php

namespace App\Http\Controllers\Api;

use App\Models\Banner;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class BannerController extends BaseApiController
{
    use Auditable;

    /**
     * PUBLIC – Get all visible banners (active + not expired)
     * GET /v1/banners  or  GET /v25/banners
     */
    /**
 * PUBLIC – Get only image + link of visible banners
 * GET /v25/banners
 */
public function publicIndex(Request $request)
{
    $query = Banner::publicVisible()
        ->orderBy('sort_order')
        ->orderByDesc('created_at');

    if ($request->filled('type')) {
        $query->where('type', $request->type);
    }

    $banners = $query->get()->map(function ($banner) {
        return [
            'image' => $banner->image_url,   // full URL
            'link'  => $banner->link,        // can be null
        ];
    });

    return $this->successResponse($banners, 'Banners retrieved successfully');
}


    /**
     * ADMIN – List all banners (including drafts & expired)
     * GET /v25/admin/banners
     */
    public function index(Request $request)
    {
        $query = Banner::with('creator:id,name,email')
            ->orderBy('sort_order')
            ->orderByDesc('created_at');

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }
        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->boolean('expired_only')) {
            $query->whereNotNull('expires_at')->where('expires_at', '<=', now());
        }

        $banners = $query->paginate($request->input('per_page', 20));

        $data = $banners->getCollection()->map(fn ($b) => $this->formatBanner($b, true));

        return $this->successResponse([
            'data'       => $data,
            'pagination' => [
                'total'        => $banners->total(),
                'per_page'     => $banners->perPage(),
                'current_page' => $banners->currentPage(),
                'last_page'    => $banners->lastPage(),
            ],
        ], 'Banners retrieved successfully');
    }

    /**
     * ADMIN – Show single banner
     * GET /v25/admin/banners/{id}
     */
    public function show($id)
    {
        $banner = Banner::with('creator:id,name,email')->findOrFail($id);
        return $this->successResponse($this->formatBanner($banner, true), 'Banner retrieved');
    }

    /**
     * ADMIN – Create banner
     * POST /v25/admin/banners
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'title'      => 'nullable|string|max:255',
            'image'      => 'required|file|mimes:jpg,jpeg,png,gif,webp,svg,bmp|max:5120', // any common image, 5MB
            'type'       => 'required|string|max:50',
            'link'       => 'nullable|url|max:500',
            'status'     => ['nullable', Rule::in(['active', 'draft'])],
            'starts_at'  => 'nullable|date',
            'expires_at' => 'nullable|date|after:starts_at',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        $path = $request->file('image')->store('banners', 'public');

        $banner = Banner::create([
            'title'      => $data['title'] ?? null,
            'image'      => $path,
            'type'       => $data['type'],
            'link'       => $data['link'] ?? null,
            'status'     => $data['status'] ?? 'active',
            'starts_at'  => $data['starts_at'] ?? null,
            'expires_at' => $data['expires_at'] ?? null,
            'sort_order' => $data['sort_order'] ?? 0,
            'created_by' => $request->user()->id,
        ]);

        $this->logAudit('create_banner', 'banner', $banner->id, 'Created banner');

        return $this->created($this->formatBanner($banner, true), 'Banner created successfully');
    }

    /**
     * ADMIN – Update banner
     * PUT / POST /v25/admin/banners/{id}
     */
    public function update(Request $request, $id)
    {
        $banner = Banner::findOrFail($id);

        $data = $request->validate([
            'title'      => 'nullable|string|max:255',
            'image'      => 'nullable|file|mimes:jpg,jpeg,png,gif,webp,svg,bmp|max:5120',
            'type'       => 'sometimes|string|max:50',
            'link'       => 'nullable|url|max:500',
            'status'     => ['nullable', Rule::in(['active', 'draft'])],
            'starts_at'  => 'nullable|date',
            'expires_at' => 'nullable|date|after:starts_at',
            'sort_order' => 'nullable|integer|min:0',
        ]);

        if ($request->hasFile('image')) {
            // delete old image
            if ($banner->image && Storage::disk('public')->exists($banner->image)) {
                Storage::disk('public')->delete($banner->image);
            }
            $data['image'] = $request->file('image')->store('banners', 'public');
        }

        $old = $banner->toArray();
        $banner->update($data);
        $new = $banner->fresh()->toArray();

        $this->logAudit('update_banner', 'banner', $id, 'Updated banner', $old, $new);

        return $this->successResponse($this->formatBanner($banner->fresh(), true), 'Banner updated successfully');
    }

    /**
     * ADMIN – Soft delete
     * DELETE /v25/admin/banners/{id}
     */
    public function destroy($id)
    {
        $banner = Banner::findOrFail($id);

        // optional: also delete the image file
        // if ($banner->image && Storage::disk('public')->exists($banner->image)) {
        //     Storage::disk('public')->delete($banner->image);
        // }

        $banner->delete();

        $this->logAudit('delete_banner', 'banner', $id, 'Deleted banner');

        return $this->successResponse(null, 'Banner deleted successfully');
    }

    /**
     * ADMIN – Quickly set status (active / draft)
     * PATCH /v25/admin/banners/{id}/status
     */
    public function updateStatus(Request $request, $id)
    {
        $banner = Banner::findOrFail($id);

        $data = $request->validate([
            'status' => ['required', Rule::in(['active', 'draft'])],
        ]);

        $old = $banner->status;
        $banner->update(['status' => $data['status']]);

        $this->logAudit('update_banner_status', 'banner', $id, "Changed status from {$old} to {$data['status']}");

        return $this->successResponse($this->formatBanner($banner, true), 'Banner status updated');
    }

    /**
     * Helper – consistent response format
     */
    private function formatBanner(Banner $banner, bool $admin = false): array
    {
        $data = [
            'id'         => $banner->id,
            'title'      => $banner->title,
            'image'      => $banner->image_url,
            'type'       => $banner->type,
            'link'       => $banner->link,
            'status'     => $banner->status,
            'starts_at'  => $banner->starts_at?->toIso8601String(),
            'expires_at' => $banner->expires_at?->toIso8601String(),
            'sort_order' => $banner->sort_order,
            'created_at' => $banner->created_at?->toIso8601String(),
        ];

        if ($admin) {
            $data['created_by'] = $banner->creator ? [
                'id'    => $banner->creator->id,
                'name'  => $banner->creator->name,
                'email' => $banner->creator->email,
            ] : null;
            $data['updated_at'] = $banner->updated_at?->toIso8601String();
            $data['is_expired'] = $banner->expires_at && $banner->expires_at->isPast();
        }

        return $data;
    }
}