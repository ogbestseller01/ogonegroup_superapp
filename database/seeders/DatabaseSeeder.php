<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\User;
use App\Models\Technician;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // First, seed roles and permissions
        $this->call(PermissionSeeder::class);

        // Create default users if they don't exist

        // 1. ADMINISTRATOR
        $admin = User::firstOrCreate(
            ['email' => 'admin@nearbyfundi.com'],
            [
                'name'              => 'Super Admin',
                'password'          => Hash::make('password'),
                'phone'             => '0712345678',
                'status'            => 'active',
                'is_active'         => true,
                'email_verified_at' => now(),
                'locale'            => 'en',
            ]
        );
        $admin->assignRole('ADMINISTRATOR');

        // 2. MANAGER
        $manager = User::firstOrCreate(
            ['email' => 'manager@nearbyfundi.com'],
            [
                'name'              => 'Branch Manager',
                'password'          => Hash::make('password'),
                'phone'             => '0712345679',
                'status'            => 'active',
                'is_active'         => true,
                'email_verified_at' => now(),
                'locale'            => 'en',
            ]
        );
        $manager->assignRole('MANAGER');

        // 3. FUNDI (Technician)
        $fundi = User::firstOrCreate(
            ['email' => 'fundi@nearbyfundi.com'],
            [
                'name'              => 'John Fundi',
                'password'          => Hash::make('password'),
                'phone'             => '0712345680',
                'status'            => 'active',
                'is_active'         => true,
                'email_verified_at' => now(),
                'locale'            => 'en',
            ]
        );
        $fundi->assignRole('FUNDI');
        // Create technician record if it doesn't exist
        Technician::firstOrCreate(
            ['user_id' => $fundi->id],
            [
                'bio'        => 'Experienced home appliance repair technician',
                'experience' => 5,
                'latitude'   => -6.7916,
                'longitude'  => 39.2186,
                'area'       => 'Ubungo',
                'verified'   => true, // manager/Admin can verify, but we set true for demo
            ]
        );

        // 4. CUSTOMER
        $customer = User::firstOrCreate(
            ['email' => 'customer@nearbyfundi.com'],
            [
                'name'              => 'Test Customer',
                'password'          => Hash::make('password'),
                'phone'             => '0712345681',
                'status'            => 'active',
                'is_active'         => true,
                'email_verified_at' => now(),
                'locale'            => 'en',
            ]
        );
        $customer->assignRole('CUSTOMER');

        $this->command->info('Default users created:');
        $this->command->info('Admin: admin@nearbyfundi.com / password');
        $this->command->info('Manager: manager@nearbyfundi.com / password');
        $this->command->info('Fundi: fundi@nearbyfundi.com / password');
        $this->command->info('Customer: customer@nearbyfundi.com / password');
    }
}