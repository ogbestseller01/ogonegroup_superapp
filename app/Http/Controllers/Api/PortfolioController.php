<?php

namespace App\Http\Controllers\Api;

use App\Models\Portfolio;
use App\Models\Technician;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class PortfolioController extends BaseApiController
{
    /**
     * GET /v3/portfolios
     * Admin list: paginated, searchable, filterable by technician.
     */
    public function index(Request $request)
    {
        $query = Portfolio::with(['technician.user', 'images']);

        // Filter by specific technician
        if ($request->filled('technician_id') && $request->technician_id !== 'all') {
            $query->where('technician_id', $request->technician_id);
        }

        // Search by technician name or email (if search term is provided)
        if ($request->filled('search')) {
            $search = $request->search;
            $query->whereHas('technician.user', function ($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('email', 'LIKE', "%{$search}%");
            });
        }

        $perPage = $request->input('per_page', 10);
        $portfolios = $query->orderByDesc('created_at')->paginate($perPage);

        // Map the paginated items through the existing serialize() helper
        $items = collect($portfolios->items())->map(fn ($p) => $this->serialize($p))->values();

        return $this->successResponse([
            'data' => $items,
            'pagination' => [
                'total'        => $portfolios->total(),
                'per_page'     => $portfolios->perPage(),
                'current_page' => $portfolios->currentPage(),
                'last_page'    => $portfolios->lastPage(),
                'from'         => $portfolios->firstItem(),
                'to'           => $portfolios->lastItem(),
            ]
        ], 'Portfolios retrieved successfully');
    }

    /** GET /v3/portfolios/technician/{id} */
    public function getByTechnician($technicianId)
    {
        $technician = Technician::find($technicianId);
        if (!$technician) {
            return $this->notFound('Technician not found.');
        }

        $portfolios = Portfolio::with('images')
            ->where('technician_id', $technician->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($p) => $this->serialize($p))
            ->values();

        return $this->successResponse([
            'portfolios' => $portfolios,
        ], 'Portfolios retrieved successfully');
    }

    /** GET /v3/portfolios/my */
    public function myPortfolios(Request $request)
    {
        $technician = $request->user()->technician;
        if (!$technician) {
            return $this->forbidden('Only technicians can view their own portfolios.');
        }

        $list = Portfolio::with('images')
            ->where('technician_id', $technician->id)
            ->orderByDesc('created_at')
            ->get()
            ->map(fn ($p) => $this->serialize($p))
            ->values();

        return $this->successResponse($list, 'Portfolios retrieved successfully');
    }

    /** POST /v3/portfolios */
    public function store(Request $request)
    {
        $technician = $request->user()->technician;
        if (!$technician) {
            return $this->forbidden('Only technicians can add portfolio items.');
        }

        $request->validate([
            'images'   => 'required|array|min:1|max:10',
            'images.*' => 'image|mimes:jpg,jpeg,png,webp|max:5120',
        ]);

        $portfolio = Portfolio::create(['technician_id' => $technician->id]);

        foreach ($request->file('images') as $file) {
            $path = $file->store('portfolios', 'public');
            $portfolio->images()->create(['image' => $path]);
        }

        return $this->created(
            $this->serialize($portfolio->load('images')),
            'Portfolio post created successfully.'
        );
    }

    /** PUT /v3/portfolios/{id} (multipart + _method=PUT) */
    public function update(Request $request, $id)
    {
        $portfolio  = Portfolio::with('images')->findOrFail($id);
        $technician = $request->user()->technician;

        if (!$technician || $technician->id != $portfolio->technician_id) {
            return $this->forbidden('Unauthorized.');
        }

        $request->validate([
            'images'             => 'nullable|array|max:10',
            'images.*'           => 'image|mimes:jpg,jpeg,png,webp|max:5120',
            'delete_image_ids'   => 'nullable|array',
            'delete_image_ids.*' => 'integer',
        ]);

        if ($request->filled('delete_image_ids')) {
            $toDelete = $portfolio->images()
                ->whereIn('id', $request->input('delete_image_ids'))
                ->get();

            foreach ($toDelete as $img) {
                if (Storage::disk('public')->exists($img->image)) {
                    Storage::disk('public')->delete($img->image);
                }
                $img->delete();
            }
        }

        if ($request->hasFile('images')) {
            foreach ($request->file('images') as $file) {
                $path = $file->store('portfolios', 'public');
                $portfolio->images()->create(['image' => $path]);
            }
        }

        return $this->successResponse(
            $this->serialize($portfolio->fresh('images')),
            'Portfolio post updated successfully.'
        );
    }

    /** DELETE /v3/portfolios/{id} */
    public function destroy(Request $request, $id)
    {
        $portfolio  = Portfolio::with('images')->findOrFail($id);
        $technician = $request->user()->technician;

        if (!$technician || $technician->id != $portfolio->technician_id) {
            return $this->forbidden('Unauthorized.');
        }

        $this->deleteFiles($portfolio);
        $portfolio->delete();

        return $this->successResponse(null, 'Portfolio post deleted.');
    }

    /* ---------------- private helpers ---------------- */

    private function serialize(Portfolio $p): array
    {
        return [
            'id'          => $p->id,
            'image_count' => $p->images->count(),
            'created_at'  => $p->created_at?->toIso8601String(),
            'technician'  => [
                'id'            => $p->technician?->id,
                'profile_photo' => $p->technician?->profile_photo,
                'area'          => $p->technician?->area,
                'rating'        => $p->technician?->rating,
                'verified'      => $p->technician?->verified,
                'user'          => [
                    'name'  => $p->technician?->user?->name,
                    'email' => $p->technician?->user?->email,
                ],
            ],
            'images' => $p->images
                ->filter(fn ($i) => !empty($i->image))
                ->map(fn ($i) => [
                    'id'  => $i->id,
                    'url' => url('storage/' . ltrim($i->image, '/')),
                ])->values(),
        ];
    }

    private function deleteFiles(Portfolio $p): void
    {
        foreach ($p->images as $img) {
            if ($img->image && Storage::disk('public')->exists($img->image)) {
                Storage::disk('public')->delete($img->image);
            }
        }
    }
}