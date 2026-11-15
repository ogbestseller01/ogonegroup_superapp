<?php
namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;

class PermissionSeeder extends Seeder
{
    public function run()
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        // ==================== CREATE ROLES ====================
        $roles = [
            'ADMINISTRATOR' => 'Full system access',
            'MANAGER'       => 'Manage technicians, requests, and blog',
            'FUNDI'         => 'Technician (service provider)',
            'CUSTOMER'      => 'Regular customer',
        ];
        foreach ($roles as $roleName => $description) {
            Role::firstOrCreate(
                ['name' => $roleName, 'guard_name' => 'web'],
                ['description' => $description]
            );
        }

        // ==================== ALL PERMISSIONS ====================
        $permissions = [
            // Dashboard
            'dashboard.view',

            // Technicians (Fundis)
            'technicians.view',
            'technicians.create',
            'technicians.edit',
            'technicians.delete',
            'fundi.verify',

            // Requests
            'requests.view',
            'requests.create',
            'requests.update',
            'requests.delete',

            // Blog
            'posts.view',
            'posts.create',
            'posts.edit',
            'posts.delete',
            'comments.manage',

            // Portfolio
            'portfolios.view',
            'portfolios.create',
            'portfolios.delete',

            // Services
            'services.create',
            'services.edit',
            'services.delete',

            // Static pages (About, FAQ, Terms)
            'about.edit',
            'faq.manage',
            'terms.edit',

            // User management
            'users.view',
            'users.create',
            'users.edit',
            'users.delete',
            'users.activate',
            'users.deactivate',
            'users.suspend',
            'users.reset_password',
            'users.assign_role',

            // Roles & Permissions management
            'roles.view',
            'roles.create',
            'roles.edit',
            'roles.delete',
            'roles.assign_permissions',
            'permissions.view',
            'permissions.create',
            'permissions.edit',
            'permissions.delete',

            // OTP & Audit
            'otp.view',
            'otp.cleanup',
            'audit.view',

            // Reports (new)
            'reports.view',
        ];

        foreach ($permissions as $perm) {
            Permission::firstOrCreate(['name' => $perm, 'guard_name' => 'web']);
        }

        // ==================== ASSIGN PERMISSIONS ====================
        $adminRole = Role::where('name', 'ADMINISTRATOR')->first();
        if ($adminRole) $adminRole->syncPermissions(Permission::all());

        $managerRole = Role::where('name', 'MANAGER')->first();
        if ($managerRole) {
            $managerRole->syncPermissions([
                'dashboard.view',
                'technicians.view', 'technicians.create', 'technicians.edit', 'technicians.delete', 'fundi.verify',
                'requests.view', 'requests.create', 'requests.update', 'requests.delete',
                'posts.view', 'posts.create', 'posts.edit', 'posts.delete', 'comments.manage',
                'portfolios.view', 'portfolios.create', 'portfolios.delete',
                'services.create', 'services.edit', 'services.delete',
                'about.edit', 'faq.manage', 'terms.edit',
                'users.view', 'users.create', 'users.edit', 'users.delete', 'users.activate',
                'users.deactivate', 'users.suspend', 'users.reset_password', 'users.assign_role',
                'otp.view', 'audit.view', 'reports.view',
            ]);
        }

        $fundiRole = Role::where('name', 'FUNDI')->first();
        if ($fundiRole) {
            $fundiRole->syncPermissions([
                'technicians.view', 'technicians.edit',
                'portfolios.create', 'portfolios.delete',
                'posts.create', 'posts.edit', 'posts.delete',
                'requests.view', 'requests.update',
            ]);
        }

        $customerRole = Role::where('name', 'CUSTOMER')->first();
        if ($customerRole) {
            $customerRole->syncPermissions([
                'technicians.view',
                'requests.create', 'requests.view', 'requests.update',
                'posts.view', 'comments.manage',
            ]);
        }

        $this->command->info('Roles and permissions seeded successfully!');
    }
}