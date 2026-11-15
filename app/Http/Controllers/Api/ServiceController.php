<?php

namespace App\Http\Controllers\Api;

use App\Models\Service;
use App\Models\ServiceCategory;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class ServiceController extends BaseApiController
{
    use Auditable;

    /**
     * Get all services with their categories.
     * Supports filtering by category_id, category_slug, and search (name/swahili_name).
     *
     * GET /v11/services
     */
    public function index(Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');

            $query = Service::with(['categories' => function ($q) use ($locale) {
                $q->select('service_categories.service_categoryID', 'category_name', 'swahili_name', 'slug')
                  ->orderBy('category_name', 'asc');
            }]);

            if ($request->filled('category_id')) {
                $query->whereHas('categories', function ($q) use ($request) {
                    $q->where('service_categoryID', $request->category_id);
                });
            }

            if ($request->filled('category_slug')) {
                $query->whereHas('categories', function ($q) use ($request) {
                    $q->where('slug', $request->category_slug);
                });
            }

            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('name', 'LIKE', "%{$search}%")
                      ->orWhere('swahili_name', 'LIKE', "%{$search}%");
                });
            }

            $query->orderBy('name', 'asc');
            $services = $query->get();

            $data = $services->map(fn($service) => $this->formatService($service, $locale));

            return $this->successResponse($data, 'Services retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching services: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch services. Please try again.', 500);
        }
    }

    /**
     * Get a single service with its categories.
     *
     * GET /v11/services/{id}
     */
    public function show($id, Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');
            $service = Service::with(['categories'])->findOrFail($id);
            return $this->successResponse($this->formatService($service, $locale), 'Service retrieved successfully');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Service not found.');
        } catch (\Exception $e) {
            Log::error('Error fetching service: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch service. Please try again.', 500);
        }
    }

    /**
     * Get all categories with their services, grouped by category.
     * Each service includes a technicians_count (via withCount).
     *
     * GET /v11/services/grouped-by-category
     */
    public function getServicesGroupedByCategory(Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');

            $categories = ServiceCategory::with(['services' => function ($q) use ($locale) {
                $q->select('services.id', 'services.name', 'services.swahili_name')
                  ->withCount('technicians') // ← this adds technicians_count to each service
                  ->orderBy('services.name', 'asc');
            }])
            ->select('service_categoryID', 'category_name', 'swahili_name', 'slug', 'description')
            ->orderBy('category_name', 'asc')
            ->get();

            $data = $categories->map(function ($category) use ($locale) {
                return [
                    'category_id'      => $category->service_categoryID,
                    'category_name'    => $category->getNameForLocale($locale),
                    'category_name_en' => $category->category_name,
                    'category_name_sw' => $category->swahili_name,
                    'category_slug'    => $category->slug,
                    'description'      => $category->description,
                    'services'         => $category->services->map(function ($service) use ($locale) {
                        return [
                            'id'                => $service->id,
                            'name'              => $service->getNameForLocale($locale),
                            'name_en'           => $service->name,
                            'name_sw'           => $service->swahili_name,
                            'technicians_count' => $service->technicians_count ?? 0, // included from withCount
                        ];
                    }),
                    'service_count' => $category->services->count(),
                ];
            });

            return $this->successResponse($data, 'Services grouped by category retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching grouped services: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch services. Please try again.', 500);
        }
    }

    /**
     * Get a simple dropdown list of services (id => localized name).
     *
     * GET /v11/services/dropdown
     */
    public function getServicesDropdown(Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');
            $services = Service::orderBy('name', 'asc')->get(['id', 'name', 'swahili_name']);

            $dropdown = $services->mapWithKeys(function ($service) use ($locale) {
                return [$service->id => $service->getNameForLocale($locale)];
            });

            return $this->successResponse([
                'dropdown' => $dropdown,
                'count'    => $services->count(),
            ], 'Services dropdown retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching dropdown: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch dropdown. Please try again.', 500);
        }
    }

    /**
     * Get services by a specific category ID.
     *
     * GET /v11/services/by-category/{categoryId}
     */
    public function getServicesByCategory($categoryId, Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');
            $category = ServiceCategory::findOrFail($categoryId);

            $services = Service::with(['categories'])
                ->whereHas('categories', fn($q) => $q->where('service_categoryID', $categoryId))
                ->orderBy('name', 'asc')
                ->get();

            $data = [
                'category' => [
                    'id'        => $category->service_categoryID,
                    'name'      => $category->getNameForLocale($locale),
                    'name_en'   => $category->category_name,
                    'name_sw'   => $category->swahili_name,
                    'slug'      => $category->slug,
                    'description' => $category->description,
                ],
                'services' => $services->map(fn($service) => [
                    'id'      => $service->id,
                    'name'    => $service->getNameForLocale($locale),
                    'name_en' => $service->name,
                    'name_sw' => $service->swahili_name,
                ]),
                'count' => $services->count(),
            ];

            return $this->successResponse($data, 'Services by category retrieved successfully');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Exception $e) {
            Log::error('Error fetching services by category: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch services. Please try again.', 500);
        }
    }

    /**
     * Get services by a category slug.
     *
     * GET /v11/services/by-category-slug/{slug}
     */
    public function getServicesByCategorySlug($slug, Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');
            $category = ServiceCategory::where('slug', $slug)->firstOrFail();

            $services = Service::with(['categories'])
                ->whereHas('categories', fn($q) => $q->where('service_categoryID', $category->service_categoryID))
                ->orderBy('name', 'asc')
                ->get();

            $data = [
                'category' => [
                    'id'        => $category->service_categoryID,
                    'name'      => $category->getNameForLocale($locale),
                    'name_en'   => $category->category_name,
                    'name_sw'   => $category->swahili_name,
                    'slug'      => $category->slug,
                    'description' => $category->description,
                ],
                'services' => $services->map(fn($service) => [
                    'id'      => $service->id,
                    'name'    => $service->getNameForLocale($locale),
                    'name_en' => $service->name,
                    'name_sw' => $service->swahili_name,
                ]),
                'count' => $services->count(),
            ];

            return $this->successResponse($data, 'Services by category retrieved successfully');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Exception $e) {
            Log::error('Error fetching services by category slug: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch services. Please try again.', 500);
        }
    }

    /**
     * Get all categories with service count (no services list).
     *
     * GET /v11/categories/with-service-count
     */
    public function getCategoriesWithServiceCount(Request $request)
    {
        try {
            $locale = $request->header('Accept-Language', 'en');
            $categories = ServiceCategory::withCount('services')
                ->orderBy('category_name', 'asc')
                ->get();

            $data = $categories->map(function ($category) use ($locale) {
                return [
                    'id'            => $category->service_categoryID,
                    'name'          => $category->getNameForLocale($locale),
                    'name_en'       => $category->category_name,
                    'name_sw'       => $category->swahili_name,
                    'slug'          => $category->slug,
                    'description'   => $category->description,
                    'service_count' => $category->services_count,
                ];
            });

            return $this->successResponse($data, 'Categories with service count retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching categories: ' . $e->getMessage());
            return $this->errorResponse('Failed to fetch categories. Please try again.', 500);
        }
    }

 


    // ─── CREATE ─────────────────────────────────────────────────────
    public function store(Request $request)
    {
        $data = $request->validate([
            'name'          => 'required|string|max:255|unique:services,name',
            'swahili_name'  => 'nullable|string|max:255',
        ]);

        $service = Service::create($data);

        // Optionally attach categories if provided
        if ($request->has('category_ids')) {
            $categoryIds = (array) $request->category_ids;
            $service->syncCategories($categoryIds);
        }

        $this->logAudit('create_service', 'service', $service->id, "Created service: {$service->name}");

        return $this->successResponse($this->formatService($service, $request->header('Accept-Language', 'en')), 'Service created successfully');
    }

    // ─── UPDATE ─────────────────────────────────────────────────────
    public function update(Request $request, $id)
    {
        $service = Service::findOrFail($id);

        $data = $request->validate([
            'name'          => 'required|string|max:255|unique:services,name,' . $service->id,
            'swahili_name'  => 'nullable|string|max:255',
        ]);

        $service->update($data);

        // Optionally sync categories
        if ($request->has('category_ids')) {
            $categoryIds = (array) $request->category_ids;
            $service->syncCategories($categoryIds);
        }

        $this->logAudit('update_service', 'service', $service->id, "Updated service: {$service->name}");

        return $this->successResponse($this->formatService($service, $request->header('Accept-Language', 'en')), 'Service updated successfully');
    }

    // ─── DELETE ─────────────────────────────────────────────────────
    public function destroy($id)
    {
        $service = Service::findOrFail($id);
        $service->delete();

        $this->logAudit('delete_service', 'service', $service->id, "Deleted service: {$service->name}");

        return $this->successResponse(null, 'Service deleted successfully');
    }

    // ─── CATEGORY ASSIGNMENT ──────────────────────────────────────

    // Attach categories (adds, no duplicates)
    public function attachCategories(Request $request, $serviceId)
    {
        $data = $request->validate([
            'category_ids' => 'required|array|min:1',
            'category_ids.*' => 'exists:service_categories,service_categoryID',
        ]);

        $service = Service::findOrFail($serviceId);
        $service->categories()->attach($data['category_ids']);

        $this->logAudit('attach_categories', 'service', $serviceId, "Attached categories to service ID {$serviceId}");

        return $this->successResponse($service->load('categories'), 'Categories attached successfully');
    }

    // Detach categories (removes)
    public function detachCategories(Request $request, $serviceId)
    {
        $data = $request->validate([
            'category_ids' => 'required|array|min:1',
            'category_ids.*' => 'exists:service_categories,service_categoryID',
        ]);

        $service = Service::findOrFail($serviceId);
        $service->categories()->detach($data['category_ids']);

        $this->logAudit('detach_categories', 'service', $serviceId, "Detached categories from service ID {$serviceId}");

        return $this->successResponse($service->load('categories'), 'Categories detached successfully');
    }

    // Sync categories (replace all)
    public function syncCategories(Request $request, $serviceId)
    {
        $data = $request->validate([
            'category_ids' => 'required|array',
            'category_ids.*' => 'exists:service_categories,service_categoryID',
        ]);

        $service = Service::findOrFail($serviceId);
        $service->syncCategories($data['category_ids']);

        $this->logAudit('sync_categories', 'service', $serviceId, "Synced categories for service ID {$serviceId}");

        return $this->successResponse($service->load('categories'), 'Categories synced successfully');
    }

    // ─── Helper (existing) ─────────────────────────────────────────
    private function formatService($service, string $locale): array
    {
        return [
            'id'           => $service->id,
            'name'         => $service->getNameForLocale($locale),
            'name_en'      => $service->name,
            'name_sw'      => $service->swahili_name,
            'categories'   => $service->categories->map(function ($cat) use ($locale) {
                return [
                    'id'   => $cat->service_categoryID,
                    'name' => $cat->getNameForLocale($locale),
                    'slug' => $cat->slug,
                ];
            }),
            'category_ids' => $service->categories->pluck('service_categoryID')->toArray(),
            'created_at'   => $service->created_at,
            'updated_at'   => $service->updated_at,
        ];
    }
}