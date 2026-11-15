<?php

namespace App\Http\Controllers\Api;

use App\Models\User;          
use App\Traits\Auditable;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;

class RolePermissionController extends BaseApiController
{
    use Auditable;

    // ============================================================
    //  ROLES - CRUD OPERATIONS
    // ============================================================

    /**
     * Get all roles with pagination
     * GET /v1/roles
     */
    public function rolesIndex(Request $request)
    {
        $this->checkPermission('roles.view');
        
        $guard = $request->input('guard', 'web');
        $perPage = $request->input('per_page', 15);
        $search = $request->input('search');
        
        $query = Role::with('permissions')->where('guard_name', $guard);
        
        if ($search) {
            $query->where('name', 'LIKE', "%{$search}%");
        }
        
        $roles = $query->paginate($perPage);
        
        return $this->successResponse($roles, 'Roles retrieved successfully.');
    }

    /**
     * Get all roles for dropdown
     * GET /v1/roles/dropdown
     */
    public function rolesDropdown(Request $request)
    {
        $guard = $request->input('guard', 'web');
        
        $roles = Role::where('guard_name', $guard)
            ->select('id', 'name')
            ->orderBy('name')
            ->get()
            ->map(function($role) {
                return [
                    'id' => $role->id,
                    'name' => $role->name,
                    'display_name' => $this->getRoleDisplayName($role->name),
                ];
            });
        
        return $this->successResponse($roles, 'Roles retrieved successfully.');
    }

    /**
     * Create a new role
     * POST /v1/roles
     */
    public function roleStore(Request $request)
    {
        $this->checkPermission('roles.create');
        
        $request->validate([
            'name' => 'required|string|unique:roles,name',
            'guard_name' => 'nullable|string|in:web,api',
            'display_name' => 'nullable|string',
            'description' => 'nullable|string',
            'permissions' => 'nullable|array',
            'permissions.*' => 'exists:permissions,id',
        ]);
        
        DB::beginTransaction();
        try {
            $guard = $request->input('guard_name', 'web');
            
            $role = Role::create([
                'name' => $request->name,
                'guard_name' => $guard,
                'display_name' => $request->display_name,
                'description' => $request->description,
            ]);
            
            if ($request->has('permissions')) {
                $permissions = Permission::whereIn('id', $request->permissions)
                    ->where('guard_name', $guard)
                    ->get();
                $role->syncPermissions($permissions);
            }
            
            DB::commit();
            
            $this->logAudit('create_role', 'role', $role->id, "Role created: {$role->name}");
            
            return $this->created($role->load('permissions'), 'Role created successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Role creation failed: ' . $e->getMessage());
            return $this->serverError('Failed to create role: ' . $e->getMessage());
        }
    }

    /**
     * Get single role with permissions
     * GET /v1/roles/{id}
     */
    public function roleShow($id)
    {
        $this->checkPermission('roles.view');
        
        $role = Role::with('permissions')->findOrFail($id);
        
        return $this->successResponse($role, 'Role retrieved successfully.');
    }

    /**
     * Update a role
     * PUT /v1/roles/{id}
     */
    public function roleUpdate(Request $request, $id)
    {
        $this->checkPermission('roles.edit');
        
        $role = Role::findOrFail($id);
        
        $request->validate([
            'name' => ['sometimes', 'string', Rule::unique('roles')->ignore($id)],
            'guard_name' => ['nullable', 'string', 'in:web,api'],
            'display_name' => ['nullable', 'string'],
            'description' => ['nullable', 'string'],
            'permissions' => ['nullable', 'array'],
            'permissions.*' => ['exists:permissions,id'],
        ]);
        
        DB::beginTransaction();
        try {
            $old = $role->toArray();
            
            if ($request->has('name')) {
                $role->name = $request->name;
            }
            if ($request->has('guard_name')) {
                $role->guard_name = $request->guard_name;
            }
            if ($request->has('display_name')) {
                $role->display_name = $request->display_name;
            }
            if ($request->has('description')) {
                $role->description = $request->description;
            }
            $role->save();
            
            if ($request->has('permissions')) {
                $permissions = Permission::whereIn('id', $request->permissions)
                    ->where('guard_name', $role->guard_name)
                    ->get();
                $role->syncPermissions($permissions);
            }
            
            DB::commit();
            
            $new = $role->fresh()->load('permissions')->toArray();
            $this->logAudit('update_role', 'role', $id, "Role #{$id} updated", $old, $new);
            
            return $this->successResponse($role->load('permissions'), 'Role updated successfully.');
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Role update failed: ' . $e->getMessage());
            return $this->serverError('Failed to update role: ' . $e->getMessage());
        }
    }

    /**
     * Delete a role
     * DELETE /v1/roles/{id}
     */
    public function roleDestroy($id)
    {
        $this->checkPermission('roles.delete');
        
        $role = Role::findOrFail($id);
        
        // Check if role has users assigned
        $usersWithRole = User::role($role->name)->count();
        if ($usersWithRole > 0) {
            return $this->badRequest("Cannot delete role '{$role->name}' because it has {$usersWithRole} user(s) assigned.");
        }
        
        // Remove all permissions first
        $role->syncPermissions([]);
        $role->delete();
        
        $this->logAudit('delete_role', 'role', $id, "Role #{$id} deleted");
        
        return $this->successResponse(null, 'Role deleted successfully.');
    }

    /**
     * Get permissions for a specific role
     * GET /v1/roles/{id}/permissions
     */
    public function rolePermissions($id)
    {
        $this->checkPermission('roles.view');
        
        $role = Role::findOrFail($id);
        
        return $this->successResponse($role->permissions, 'Role permissions retrieved.');
    }

    /**
     * Assign permissions to a role - FIXED for web guard
     * POST /v1/roles/{id}/permissions
     */
    public function assignPermissionsToRole(Request $request, $id)
    {
        $this->checkPermission('roles.edit');
        
        $role = Role::findOrFail($id);
        
        $request->validate([
            'permissions' => 'required|array',
            'permissions.*' => 'exists:permissions,id',
        ]);
        
        // Get permissions for the role's guard
        $permissions = Permission::whereIn('id', $request->permissions)
            ->where('guard_name', $role->guard_name)
            ->get();
        
        // Check if all permissions were found
        $foundIds = $permissions->pluck('id')->toArray();
        $missingIds = array_diff($request->permissions, $foundIds);
        
        if (!empty($missingIds)) {
            // Try to get permissions without guard filter (fallback)
            $fallbackPermissions = Permission::whereIn('id', $missingIds)->get();
            
            if ($fallbackPermissions->isNotEmpty()) {
                // Update these permissions to match the role's guard
                foreach ($fallbackPermissions as $perm) {
                    $perm->guard_name = $role->guard_name;
                    $perm->save();
                }
                
                // Re-fetch all permissions
                $permissions = Permission::whereIn('id', $request->permissions)
                    ->where('guard_name', $role->guard_name)
                    ->get();
                
                $foundIds = $permissions->pluck('id')->toArray();
                $missingIds = array_diff($request->permissions, $foundIds);
            }
        }
        
        if (!empty($missingIds)) {
            return $this->errorResponse(
                'Some permissions do not exist for guard "' . $role->guard_name . '": ' . implode(', ', $missingIds) . 
                '. Please create these permissions first or change the role guard.',
                422
            );
        }
        
        $role->syncPermissions($permissions);
        
        $this->logAudit('assign_permissions', 'role', $id, 
            "Permissions assigned to role #{$id}: " . implode(', ', $permissions->pluck('name')->toArray()));
        
        return $this->successResponse(
            $role->load('permissions'), 
            'Permissions assigned successfully.'
        );
    }

    /**
     * Remove a permission from a role
     * DELETE /v1/roles/{roleId}/permissions/{permissionId}
     */
    public function removePermissionFromRole($roleId, $permissionId)
    {
        $this->checkPermission('roles.edit');
        
        $role = Role::findOrFail($roleId);
        $permission = Permission::findOrFail($permissionId);
        
        $role->revokePermissionTo($permission);
        
        $this->logAudit('remove_permission_from_role', 'role', $roleId, 
            "Permission {$permission->name} removed from role {$role->name}");
        
        return $this->successResponse(
            $role->load('permissions'), 
            'Permission removed from role successfully.'
        );
    }

    // ============================================================
    //  PERMISSIONS - CRUD OPERATIONS
    // ============================================================

    /**
     * Get all permissions with pagination
     * GET /v1/permissions
     */
    public function permissionsIndex(Request $request)
    {
        $this->checkPermission('permissions.view');
        
        $guard = $request->input('guard');
        $perPage = $request->input('per_page', 15);
        $search = $request->input('search');
        
        $query = Permission::query();
        
        if ($guard) {
            $query->where('guard_name', $guard);
        }
        
        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('name', 'LIKE', "%{$search}%")
                  ->orWhere('display_name', 'LIKE', "%{$search}%")
                  ->orWhere('description', 'LIKE', "%{$search}%");
            });
        }
        
        $permissions = $query->paginate($perPage);
        
        return $this->successResponse($permissions, 'Permissions retrieved successfully.');
    }

    /**
     * Get all permissions for dropdown
     * GET /v1/permissions/dropdown
     */
    public function permissionsDropdown(Request $request)
    {
        $guard = $request->input('guard', 'web');
        
        $permissions = Permission::where('guard_name', $guard)
            ->select('id', 'name', 'display_name', 'description')
            ->orderBy('name')
            ->get();
        
        return $this->successResponse($permissions, 'Permissions retrieved successfully.');
    }

    /**
     * Create a new permission
     * POST /v1/permissions
     */
    public function permissionStore(Request $request)
    {
        $this->checkPermission('permissions.create');
        
        $request->validate([
            'name' => 'required|string|unique:permissions,name',
            'display_name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $guard = $request->input('guard_name', 'web');
        
        $permission = Permission::create([
            'name' => $request->name,
            'guard_name' => $guard,
            'display_name' => $request->display_name,
            'description' => $request->description,
        ]);
        
        $this->logAudit('create_permission', 'permission', $permission->id, 
            "Permission created: {$permission->name}");
        
        return $this->created($permission, 'Permission created successfully.');
    }

    /**
     * Get single permission
     * GET /v1/permissions/{id}
     */
    public function permissionShow($id)
    {
        $this->checkPermission('permissions.view');
        
        $permission = Permission::findOrFail($id);
        
        return $this->successResponse($permission, 'Permission retrieved successfully.');
    }

    /**
     * Update a permission
     * PUT /v1/permissions/{id}
     */
    public function permissionUpdate(Request $request, $id)
    {
        $this->checkPermission('permissions.edit');
        
        $permission = Permission::findOrFail($id);
        
        $request->validate([
            'name' => ['sometimes', 'string', Rule::unique('permissions')->ignore($id)],
            'display_name' => 'nullable|string|max:255',
            'description' => 'nullable|string',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $old = $permission->toArray();
        
        if ($request->has('name')) {
            $permission->name = $request->name;
        }
        if ($request->has('display_name')) {
            $permission->display_name = $request->display_name;
        }
        if ($request->has('description')) {
            $permission->description = $request->description;
        }
        if ($request->has('guard_name')) {
            $permission->guard_name = $request->guard_name;
        }
        $permission->save();
        
        $new = $permission->fresh()->toArray();
        $this->logAudit('update_permission', 'permission', $id, "Permission #{$id} updated", $old, $new);
        
        return $this->successResponse($permission, 'Permission updated successfully.');
    }

    /**
     * Delete a permission
     * DELETE /v1/permissions/{id}
     */
    public function permissionDestroy($id)
    {
        $this->checkPermission('permissions.delete');
        
        $permission = Permission::findOrFail($id);
        
        // Check if permission is assigned to any role
        $rolesWithPermission = Role::whereHas('permissions', function($query) use ($permission) {
            $query->where('permission_id', $permission->id);
        })->count();
        
        if ($rolesWithPermission > 0) {
            return $this->badRequest("Cannot delete permission '{$permission->name}' because it is assigned to {$rolesWithPermission} role(s).");
        }
        
        $permission->delete();
        
        $this->logAudit('delete_permission', 'permission', $id, "Permission #{$id} deleted");
        
        return $this->successResponse(null, 'Permission deleted successfully.');
    }

    /**
     * Bulk create permissions
     * POST /v1/permissions/bulk
     */
    public function bulkCreatePermissions(Request $request)
    {
        $this->checkPermission('permissions.create');
        
        $request->validate([
            'permissions' => 'required|array',
            'permissions.*.name' => 'required|string|unique:permissions,name',
            'permissions.*.display_name' => 'nullable|string',
            'permissions.*.description' => 'nullable|string',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $guard = $request->input('guard_name', 'web');
        $created = [];
        
        foreach ($request->permissions as $perm) {
            $permission = Permission::create([
                'name' => $perm['name'],
                'guard_name' => $guard,
                'display_name' => $perm['display_name'] ?? null,
                'description' => $perm['description'] ?? null,
            ]);
            $created[] = $permission;
        }
        
        $this->logAudit('bulk_create_permissions', 'permission', null, 
            'Bulk created ' . count($created) . ' permissions');
        
        return $this->successResponse([
            'created' => count($created),
            'permissions' => $created,
            'guard' => $guard,
        ], 'Permissions created successfully.');
    }

    // ============================================================
    //  USER ROLE ASSIGNMENT
    // ============================================================

    /**
     * Assign a role to a user
     * POST /v1/users/{userId}/assign-role
     */
    public function assignRoleToUser(Request $request, $userId)
    {
        $this->checkPermission('users.edit');
        
        $user = User::findOrFail($userId);
        
        $request->validate([
            'role' => 'required|exists:roles,name',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $guard = $request->input('guard_name', 'web');
        $role = Role::where('name', $request->role)
            ->where('guard_name', $guard)
            ->first();
        
        if (!$role) {
            return $this->errorResponse("Role '{$request->role}' does not exist for guard '{$guard}'.", 422);
        }
        
        $user->syncRoles([$role->name]);
        
        $this->logAudit('assign_role_to_user', 'user', $userId, 
            "Assigned role {$role->name} to user #{$userId}");
        
        return $this->successResponse(
            $user->load('roles'), 
            'Role assigned to user successfully.'
        );
    }

    /**
     * Get user's roles
     * GET /v1/users/{userId}/roles
     */
    public function getUserRoles($userId)
    {
        $this->checkPermission('users.view');
        
        $user = User::findOrFail($userId);
        $roles = $user->getRoleNames();
        
        $roleDetails = Role::whereIn('name', $roles)->get();
        
        return $this->successResponse([
            'roles' => $roles,
            'role_details' => $roleDetails,
        ], 'User roles retrieved successfully.');
    }

    /**
     * Remove a role from a user
     * DELETE /v1/users/{userId}/roles/{roleName}
     */
    public function removeRoleFromUser($userId, $roleName)
    {
        $this->checkPermission('users.edit');
        
        $user = User::findOrFail($userId);
        
        if (!$user->hasRole($roleName)) {
            return $this->errorResponse("User does not have role '{$roleName}'.", 422);
        }
        
        $user->removeRole($roleName);
        
        $this->logAudit('remove_role_from_user', 'user', $userId, 
            "Removed role {$roleName} from user #{$userId}");
        
        return $this->successResponse(
            $user->load('roles'), 
            'Role removed from user successfully.'
        );
    }

    /**
     * Sync multiple roles to a user
     * POST /v1/users/{userId}/sync-roles
     */
    public function syncUserRoles(Request $request, $userId)
    {
        $this->checkPermission('users.edit');
        
        $user = User::findOrFail($userId);
        
        $request->validate([
            'roles' => 'required|array',
            'roles.*' => 'exists:roles,name',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $guard = $request->input('guard_name', 'web');
        
        $roles = Role::whereIn('name', $request->roles)
            ->where('guard_name', $guard)
            ->get();
        
        $roleNames = $roles->pluck('name')->toArray();
        
        $user->syncRoles($roleNames);
        
        $this->logAudit('sync_user_roles', 'user', $userId, 
            "Synced roles for user #{$userId}: " . implode(', ', $roleNames));
        
        return $this->successResponse(
            $user->load('roles'), 
            'User roles synced successfully.'
        );
    }

    // ============================================================
    //  BULK OPERATIONS
    // ============================================================

    /**
     * Bulk assign permissions to multiple roles
     * POST /v1/roles/bulk/assign-permissions
     */
    public function bulkAssignPermissions(Request $request)
    {
        $this->checkPermission('roles.edit');
        
        $request->validate([
            'role_ids' => 'required|array',
            'role_ids.*' => 'exists:roles,id',
            'permission_ids' => 'required|array',
            'permission_ids.*' => 'exists:permissions,id',
            'guard_name' => 'nullable|string|in:web,api',
        ]);
        
        $guard = $request->input('guard_name', 'web');
        
        $roles = Role::whereIn('id', $request->role_ids)
            ->where('guard_name', $guard)
            ->get();
        
        $permissions = Permission::whereIn('id', $request->permission_ids)
            ->where('guard_name', $guard)
            ->get();
        
        if ($permissions->isEmpty()) {
            return $this->errorResponse('No permissions found for guard "' . $guard . '".', 422);
        }
        
        foreach ($roles as $role) {
            $role->syncPermissions($permissions);
        }
        
        $this->logAudit('bulk_assign_permissions', 'system', null, 
            "Bulk assigned " . $permissions->count() . " permissions to " . $roles->count() . " roles");
        
        return $this->successResponse([
            'roles_updated' => $roles->count(),
            'permissions_assigned' => $permissions->count(),
            'guard' => $guard,
        ], 'Permissions assigned to roles successfully.');
    }

    // ============================================================
    //  UTILITY
    // ============================================================

    /**
     * Get all available guards
     * GET /v1/guards
     */
    public function getGuards()
    {
        $guards = [
            ['value' => 'web', 'label' => 'Web'],
            ['value' => 'api', 'label' => 'API'],
        ];
        
        return $this->successResponse($guards, 'Available guards retrieved.');
    }

    /**
     * Get statistics about roles and permissions
     * GET /v1/roles-permissions/stats
     */
    public function getStats(Request $request)
    {
        $this->checkPermission('roles.view');
        
        $guard = $request->input('guard', 'web');
        
        $stats = [
            'total_roles' => Role::where('guard_name', $guard)->count(),
            'total_permissions' => Permission::where('guard_name', $guard)->count(),
            'roles' => Role::where('guard_name', $guard)
                ->withCount('users')
                ->get()
                ->map(function($role) {
                    return [
                        'id' => $role->id,
                        'name' => $role->name,
                        'display_name' => $role->display_name,
                        'users_count' => $role->users_count,
                        'permissions_count' => $role->permissions->count(),
                    ];
                }),
            'permissions' => Permission::where('guard_name', $guard)
                ->get()
                ->map(function($permission) {
                    return [
                        'id' => $permission->id,
                        'name' => $permission->name,
                        'display_name' => $permission->display_name,
                        'description' => $permission->description,
                    ];
                }),
            'guard' => $guard,
        ];
        
        return $this->successResponse($stats, 'Statistics retrieved successfully.');
    }

    // ============================================================
    //  PRIVATE HELPERS
    // ============================================================

    /**
     * Get display name for role
     */
    private function getRoleDisplayName($name)
    {
        // Try to find existing display name from database
        $role = Role::where('name', $name)->first();
        if ($role && $role->display_name) {
            return $role->display_name;
        }
        
        // Fallback: convert to readable format
        return ucwords(str_replace('_', ' ', strtolower($name)));
    }
}