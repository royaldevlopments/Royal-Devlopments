<?php

namespace Boy132\FluffyTheme;

use Filament\Contracts\Plugin;
use Filament\Panel;
use Filament\Support\Colors\Color;

class FluffyThemePlugin implements Plugin
{
    public function getId(): string
    {
        return 'fluffy-theme';
    }

    public function register(Panel $panel): void
    {
        $panel
            ->font('Finger Paint')
            ->colors([
                'danger' => Color::Rose,
                'gray' => Color::generateV3Palette('#b974c3'), // Fuchsia but desaturated
                'info' => Color::Violet,
                'primary' => Color::Indigo,
                'success' => Color::Teal,
                'warning' => Color::Pink,
            ]);
    }

    public function boot(Panel $panel): void {}
}
