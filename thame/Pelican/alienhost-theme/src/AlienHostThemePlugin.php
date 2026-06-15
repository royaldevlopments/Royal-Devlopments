<?php

namespace AlienHost\Theme;

use Filament\Contracts\Plugin;
use Filament\Panel;
use Filament\Support\Colors\Color;

class AlienHostThemePlugin implements Plugin
{
    public function getId(): string
    {
        return 'alienhost-theme';
    }

    public function register(Panel $panel): void
    {
        $panel
            ->font('Poppins')
            ->colors([
                // Primary: Púrpura AlienHost vibrante
                'primary' => Color::hex('#6419ff'),

                // Gray: Paleta personalizada ultra oscura con tinte azul-púrpura (+8% claridad)
                'gray' => [
                    50 => '#f8fafc',
                    100 => '#e2e8f0',
                    200 => '#94a3b8',
                    300 => '#64748b',
                    400 => '#475569',
                    500 => '#334155',
                    600 => '#222d3d',
                    700 => '#131c2b',
                    800 => '#0b111c',
                    900 => '#060a10',
                    950 => '#030407',
                ],

                // Danger: Rojo oscuro
                'danger' => Color::hex('#be123c'),

                // Warning: Ámbar oscuro
                'warning' => Color::hex('#d97706'),

                // Success: Verde esmeralda oscuro
                'success' => Color::hex('#059669'),

                // Info: Azul AlienHost
                'info' => Color::hex('#0073ce'),
            ]);
    }

    public function boot(Panel $panel): void {}
}
