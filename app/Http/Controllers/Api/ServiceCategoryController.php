<?php

namespace App\Http\Controllers\Api;

use App\Models\ServiceCategory;
use App\Traits\Auditable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;

class ServiceCategoryController extends BaseApiController
{
    use Auditable;

    /**
     * Get all categories with service count.
     * GET /v17/service-categories
     */
    public function index(Request $request)
    {
        try {
            $query = ServiceCategory::withCount('services'); // ✅ adds services_count

            if ($request->filled('search')) {
                $search = $request->search;
                $query->where(function ($q) use ($search) {
                    $q->where('category_name', 'LIKE', "%{$search}%")
                      ->orWhere('swahili_name', 'LIKE', "%{$search}%")
                      ->orWhere('description', 'LIKE', "%{$search}%")
                      ->orWhere('comment', 'LIKE', "%{$search}%");
                });
            }

            $query->orderBy('category_name', 'asc');
            $perPage = $request->input('per_page', 20);
            $categories = $query->paginate($perPage);

            $data = $this->formatCategories($categories);

            return $this->successResponse($data, 'Categories retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching service categories: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch categories. Please try again.', 500);
        }
    }

    /**
     * Get single category (Public)
     * GET /v17/service-categories/{id}
     */
    public function show($id, Request $request)
    {
        try {
            $category = ServiceCategory::withCount('services')->findOrFail($id);
            $data = $this->formatSingleCategory($category);
            return $this->successResponse($data, 'Category retrieved successfully');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Exception $e) {
            Log::error('Error fetching service category: ' . $e->getMessage(), [
                'category_id' => $id,
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch category. Please try again.', 500);
        }
    }

    /**
     * Get category by slug (Public)
     * GET /v17/service-categories/slug/{slug}
     */
    public function showBySlug($slug, Request $request)
    {
        try {
            $category = ServiceCategory::where('slug', $slug)->withCount('services')->firstOrFail();
            $data = $this->formatSingleCategory($category);
            return $this->successResponse($data, 'Category retrieved successfully');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Exception $e) {
            Log::error('Error fetching service category by slug: ' . $e->getMessage(), [
                'slug' => $slug,
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch category. Please try again.', 500);
        }
    }

    /**
     * Get categories as dropdown by ID (Public)
     * GET /v17/service-categories/dropdown/by-id
     */
    public function dropdownById(Request $request)
    {
        try {
            $categories = ServiceCategory::orderBy('category_name', 'asc')
                ->get(['service_categoryID', 'category_name', 'swahili_name', 'slug']);

            $dropdown = $categories->mapWithKeys(function ($category) {
                return [$category->service_categoryID => $category->category_name];
            });

            $dropdownWithData = $categories->map(function ($category) {
                return [
                    'id'   => $category->service_categoryID,
                    'name' => $category->category_name,
                    'swahili_name' => $category->swahili_name,
                    'slug' => $category->slug,
                ];
            });

            return $this->successResponse([
                'dropdown' => $dropdown,
                'dropdown_with_data' => $dropdownWithData,
                'count' => $categories->count()
            ], 'Categories dropdown retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching categories dropdown by ID: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch categories dropdown. Please try again.', 500);
        }
    }

    /**
     * Get only active (non-deleted) categories as dropdown (Public)
     * GET /v17/service-categories/dropdown/active
     */
    public function dropdownActive(Request $request)
    {
        try {
            $categories = ServiceCategory::withoutTrashed()
                ->orderBy('category_name', 'asc')
                ->get(['service_categoryID', 'category_name', 'swahili_name', 'slug']);

            $dropdown = $categories->mapWithKeys(function ($category) {
                return [$category->service_categoryID => $category->category_name];
            });

            return $this->successResponse([
                'dropdown' => $dropdown,
                'count' => $categories->count()
            ], 'Active categories dropdown retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching active categories dropdown: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch active categories. Please try again.', 500);
        }
    }

    /**
     * Get categories as dropdown with pagination (Public)
     * GET /v17/service-categories/dropdown/paginated
     */
    public function dropdownPaginated(Request $request)
    {
        try {
            $perPage = $request->input('per_page', 50);
            $categories = ServiceCategory::orderBy('category_name', 'asc')
                ->paginate($perPage, ['service_categoryID', 'category_name', 'swahili_name', 'slug']);

            $dropdown = $categories->mapWithKeys(function ($category) {
                return [$category->service_categoryID => $category->category_name];
            });

            return $this->successResponse([
                'dropdown' => $dropdown,
                'pagination' => [
                    'total' => $categories->total(),
                    'per_page' => $categories->perPage(),
                    'current_page' => $categories->currentPage(),
                    'last_page' => $categories->lastPage(),
                ]
            ], 'Categories dropdown retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching paginated categories dropdown: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch categories. Please try again.', 500);
        }
    }

    /**
     * Create a new category (Admin only)
     * POST /v17/service-categories
     */
    public function store(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->can('service-categories.create')) {
                return $this->forbidden('Unauthorized. You need service-categories.create permission.');
            }

            $validated = $request->validate([
                'category_name' => 'required|string|max:255|unique:service_categories,category_name',
                'swahili_name' => 'nullable|string|max:255',
                'slug' => 'nullable|string|max:255|unique:service_categories,slug',
                'description' => 'nullable|string|max:1000',
                'comment' => 'nullable|string|max:1000',
            ]);

            DB::beginTransaction();

            if (empty($validated['slug'])) {
                $validated['slug'] = \Illuminate\Support\Str::slug($validated['category_name']);
            }

            $category = ServiceCategory::create($validated);

            DB::commit();

            $this->logAudit('create_category', 'service_category', $category->service_categoryID, json_encode([
                'name' => $category->category_name,
                'swahili_name' => $category->swahili_name,
                'slug' => $category->slug,
            ]));

            return $this->created($category, 'Category created successfully.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->errorResponse($e->errors(), 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error creating service category: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown',
                'data' => $request->all()
            ]);
            return $this->errorResponse('Failed to create category. Please try again.', 500);
        }
    }

    /**
     * Update a category (Admin only)
     * PUT /v17/service-categories/{id}
     */
    public function update(Request $request, $id)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->can('service-categories.update')) {
                return $this->forbidden('Unauthorized. You need service-categories.update permission.');
            }

            $category = ServiceCategory::findOrFail($id);

            $validated = $request->validate([
                'category_name' => [
                    'sometimes',
                    'required',
                    'string',
                    'max:255',
                    Rule::unique('service_categories', 'category_name')->ignore($id, 'service_categoryID')
                ],
                'swahili_name' => 'nullable|string|max:255',
                'slug' => [
                    'nullable',
                    'string',
                    'max:255',
                    Rule::unique('service_categories', 'slug')->ignore($id, 'service_categoryID')
                ],
                'description' => 'nullable|string|max:1000',
                'comment' => 'nullable|string|max:1000',
            ]);

            DB::beginTransaction();

            if (empty($validated['slug']) && isset($validated['category_name'])) {
                $validated['slug'] = \Illuminate\Support\Str::slug($validated['category_name']);
            }

            $oldData = $category->toArray();
            $category->update($validated);

            DB::commit();

            $this->logAudit('update_category', 'service_category', $category->service_categoryID, json_encode([
                'old' => $oldData,
                'new' => $category->toArray(),
            ]));

            return $this->successResponse($category, 'Category updated successfully.');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->errorResponse($e->errors(), 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error updating service category: ' . $e->getMessage(), [
                'category_id' => $id,
                'user_id' => $request->user()->id ?? 'unknown',
                'data' => $request->all()
            ]);
            return $this->errorResponse('Failed to update category. Please try again.', 500);
        }
    }

    /**
     * Delete a category (Admin only)
     * DELETE /v17/service-categories/{id}
     */
    public function destroy($id, Request $request)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->can('service-categories.delete')) {
                return $this->forbidden('Unauthorized. You need service-categories.delete permission.');
            }

            $category = ServiceCategory::findOrFail($id);

            if ($category->services()->exists()) {
                return $this->errorResponse(
                    'Cannot delete category with associated services.',
                    422
                );
            }

            DB::beginTransaction();

            $category->delete();

            DB::commit();

            $this->logAudit('delete_category', 'service_category', $category->service_categoryID, json_encode([
                'name' => $category->category_name,
                'swahili_name' => $category->swahili_name,
            ]));

            return $this->successResponse(null, 'Category deleted successfully.');
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return $this->notFound('Category not found.');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error deleting service category: ' . $e->getMessage(), [
                'category_id' => $id,
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to delete category. Please try again.', 500);
        }
    }

    /**
     * Bulk delete categories (Admin only)
     * DELETE /v17/service-categories/bulk-delete
     */
    public function bulkDelete(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->can('service-categories.delete')) {
                return $this->forbidden('Unauthorized. You need service-categories.delete permission.');
            }

            $validated = $request->validate([
                'ids' => 'required|array',
                'ids.*' => 'integer|exists:service_categories,service_categoryID'
            ]);

            $categories = ServiceCategory::whereIn('service_categoryID', $validated['ids'])->get();

            foreach ($categories as $category) {
                if ($category->services()->exists()) {
                    return $this->errorResponse(
                        "Cannot delete category '{$category->category_name}' because it has associated services.",
                        422
                    );
                }
            }

            DB::beginTransaction();

            $deleted = ServiceCategory::whereIn('service_categoryID', $validated['ids'])->delete();

            DB::commit();

            $this->logAudit('bulk_delete_categories', 'service_category', null, json_encode([
                'deleted_ids' => $validated['ids'],
                'deleted_count' => $deleted,
            ]));

            return $this->successResponse(['deleted_count' => $deleted], 'Categories deleted successfully.');
        } catch (\Illuminate\Validation\ValidationException $e) {
            return $this->errorResponse($e->errors(), 422);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Error bulk deleting service categories: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown',
                'ids' => $request->ids ?? []
            ]);
            return $this->errorResponse('Failed to delete categories. Please try again.', 500);
        }
    }

    /**
     * Get category statistics (Admin only)
     * GET /v17/service-categories/stats
     */
    public function stats(Request $request)
    {
        try {
            $user = $request->user();

            if (!$user || !$user->can('service-categories.view')) {
                return $this->forbidden('Unauthorized. You need service-categories.view permission.');
            }

            $stats = [
                'total' => ServiceCategory::count(),
                'total_with_services' => ServiceCategory::has('services')->count(),
                'total_without_services' => ServiceCategory::doesntHave('services')->count(),
            ];

            return $this->successResponse($stats, 'Category statistics retrieved successfully');
        } catch (\Exception $e) {
            Log::error('Error fetching service category stats: ' . $e->getMessage(), [
                'user_id' => $request->user()->id ?? 'unknown'
            ]);
            return $this->errorResponse('Failed to fetch statistics. Please try again.', 500);
        }
    }

    // ─── Private Formatters ─────────────────────────────────────────────

    /**
     * Format paginated categories for response.
     */
    private function formatCategories($categories): array
    {
        $data = $categories->map(function ($category) {
            return $this->formatSingleCategory($category);
        });

        return [
            'data' => $data,
            'pagination' => [
                'total' => $categories->total(),
                'per_page' => $categories->perPage(),
                'current_page' => $categories->currentPage(),
                'last_page' => $categories->lastPage(),
            ]
        ];
    }

    /**
     * Format a single category.
     */
    private function formatSingleCategory($category): array
    {
        return [
            'service_categoryID' => $category->service_categoryID,
            'category_name'      => $category->category_name,
            'swahili_name'       => $category->swahili_name,
            'formatted_name'     => $category->formatted_name,
            'slug'               => $category->slug,
            'description'        => $category->description,
            'comment'            => $category->comment,
            'services_count'     => $category->services_count ?? 0, // ✅ now included
            'created_at'         => $category->created_at,
            'updated_at'         => $category->updated_at,
        ];
    }
}