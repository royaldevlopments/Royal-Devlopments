<?php

namespace Boy132\ThemeCustomizer\Providers;

use App\Models\Role;
use Illuminate\Support\ServiceProvider;

class ThemeCustomizerPluginProvider extends ServiceProvider
{
    public function boot(): void
    {
        Role::registerCustomPermissions([
            'themeCustomizer' => [
                'view',
                'update',
            ],
        ]);
        Role::registerCustomModelIcon('themeCustomizer', 'tabler-palette');
    }
}
