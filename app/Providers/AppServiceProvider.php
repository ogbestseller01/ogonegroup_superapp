<?php

namespace App\Providers;

use App\Services\RafikiSmsService;
use App\Services\SmsNotificationService;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Schema;
use Illuminate\Pagination\Paginator;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        $this->registerSmsServices();
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        $this->configureDatabase();
        $this->configurePagination();
    }

    /**
     * Register SMS services.
     */
    protected function registerSmsServices(): void
    {
        // Register RafikiSmsService as a singleton
        $this->app->singleton(RafikiSmsService::class, function ($app) {
            return new RafikiSmsService();
        });

        // Register SmsNotificationService with dependency injection
        $this->app->singleton(SmsNotificationService::class, function ($app) {
            return new SmsNotificationService(
                $app->make(RafikiSmsService::class)
            );
        });
    }

    /**
     * Configure database settings.
     */
    protected function configureDatabase(): void
    {
        // Fix for MySQL < 5.7.7 or MariaDB < 10.2.2
        // Prevents "Specified key was too long" error
        if (method_exists(Schema::class, 'defaultStringLength')) {
            Schema::defaultStringLength(191);
        }
    }

    /**
     * Configure pagination settings.
     */
    protected function configurePagination(): void
    {
        // Use Bootstrap 5 pagination styling
        if (class_exists(Paginator::class)) {
            Paginator::useBootstrapFive();
        }
    }
}