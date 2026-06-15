<?php

namespace JoanFo\StarryNight\Providers;

use Illuminate\Support\Facades\File;
use Illuminate\Support\ServiceProvider;

class StarryNightPluginProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->ensureCssPublished();
    }

    public function boot(): void
    {
        $sourceDark = __DIR__.'/../../css/starry-night.css';
        $destDark = public_path('plugins/starrynight/css/starry-night.css');

        $sourceLight = __DIR__.'/../../css/starry-night-light.css';
        $destLight = public_path('plugins/starrynight/css/starry-night-light.css');

        $this->publishes([
            $sourceDark => $destDark,
            $sourceLight => $destLight,
        ], 'starrynight-assets');
    }

    private function ensureCssPublished(): void
    {
        $pairs = [
            [__DIR__.'/../../css/starry-night.css', public_path('plugins/starrynight/css/starry-night.css')],
            [__DIR__.'/../../css/starry-night-light.css', public_path('plugins/starrynight/css/starry-night-light.css')],
        ];

        foreach ($pairs as [$source, $destination]) {
            if (!File::exists($destination) && File::exists($source)) {
                $dir = dirname($destination);
                if (!File::isDirectory($dir)) {
                    File::makeDirectory($dir, 0755, true);
                }
                File::copy($source, $destination);
            }
        }
    }
}
