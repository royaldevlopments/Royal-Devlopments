<?php

namespace Boy132\ThemeCustomizer;

use Filament\Contracts\Plugin;
use Filament\Enums\ThemeMode;
use Filament\FontProviders\LocalFontProvider;
use Filament\Panel;
use Filament\View\PanelsRenderHook;
use Illuminate\Support\Facades\Blade;

class ThemeCustomizerPlugin implements Plugin
{
    public const COLOR_NAMES = [
        'gray',
        'primary',
        'info',
        'success',
        'warning',
        'danger',
    ];

    public function getId(): string
    {
        return 'theme-customizer';
    }

    public function register(Panel $panel): void
    {
        $id = str($panel->getId())->title();

        $panel->discoverPages(plugin_path($this->getId(), "src/Filament/$id/Pages"), "Boy132\\ThemeCustomizer\\Filament\\$id\\Pages");

        $this->applyTheme($panel);
    }

    public function boot(Panel $panel): void {}

    private function applyTheme(Panel $panel): void
    {
        $font = config('theme-customizer.font');
        if ($font) {
            $panel->font($font, provider: LocalFontProvider::class);

            $fontUrl = asset("storage/fonts/$font.ttf");
            $panel->renderHook(
                PanelsRenderHook::STYLES_BEFORE,
                fn () => Blade::render("<style>@font-face { font-family: $font; src: url(\"$fontUrl\"); }</style>")
            );
        }

        $colors = [];

        foreach (static::COLOR_NAMES as $color) {
            $value = config('theme-customizer.colors.' . $color);
            if ($value) {
                $colors[$color] = $value;
            }
        }

        $panel->colors($colors);

        $defaultThemeMode = config('theme-customizer.default_theme_mode');
        if ($defaultThemeMode) {
            $panel->defaultThemeMode(ThemeMode::tryFrom($defaultThemeMode) ?? ThemeMode::System);
        }
    }
}
