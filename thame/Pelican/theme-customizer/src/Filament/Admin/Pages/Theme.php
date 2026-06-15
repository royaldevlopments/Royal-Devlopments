<?php

namespace Boy132\ThemeCustomizer\Filament\Admin\Pages;

use App\Traits\EnvironmentWriterTrait;
use Boy132\ThemeCustomizer\ThemeCustomizerPlugin;
use Exception;
use Filament\Actions\Action;
use Filament\Enums\ThemeMode;
use Filament\Forms\Components\ColorPicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\ToggleButtons;
use Filament\Forms\Concerns\InteractsWithForms;
use Filament\Infolists\Components\TextEntry;
use Filament\Notifications\Notification;
use Filament\Pages\Concerns\InteractsWithFormActions;
use Filament\Pages\Page;
use Filament\Schemas\Components\Component;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Schema;
use Filament\Support\Colors\Color;
use Illuminate\Support\Arr;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\HtmlString;

/**
 * @property Schema $form
 */
class Theme extends Page
{
    use EnvironmentWriterTrait;
    use InteractsWithFormActions;
    use InteractsWithForms;

    protected static string|\BackedEnum|null $navigationIcon = 'tabler-palette';

    protected string $view = 'filament.server.pages.server-form-page';

    /** @var array<mixed>|null */
    public ?array $data = [];

    public function getTitle(): string
    {
        return 'Theme Customizer';
    }

    public static function getNavigationLabel(): string
    {
        return 'Theme Customizer';
    }

    public static function canAccess(): bool
    {
        return user()?->can('view themeCustomizer');
    }

    public function mount(): void
    {
        $this->form->fill(config('theme-customizer'));
    }

    /**
     * @return Component[]
     *
     * @throws Exception
     */
    public function getFormSchema(): array
    {
        $schema = [
            Section::make('Font')
                ->columns()
                ->columnSpanFull()
                ->schema([
                    Select::make('font')
                        ->live()
                        ->selectablePlaceholder()
                        ->placeholder('Default Font')
                        ->options(function () {
                            $fonts = [];

                            foreach (Storage::disk('public')->allFiles('fonts') as $file) {
                                $fileInfo = pathinfo($file);

                                if ($fileInfo['extension'] === 'ttf') {
                                    $fonts[$fileInfo['filename']] = $fileInfo['filename'];
                                }
                            }

                            return $fonts;
                        }),
                    TextEntry::make('font_preview')
                        ->label('Preview')
                        ->state(function (Get $get) {
                            $fontName = $get('font');

                            if (!$fontName) {
                                return 'The quick brown fox jumps over the lazy dog';
                            }

                            $fontUrl = asset("storage/fonts/$fontName.ttf");
                            $style = <<<CSS
                        @font-face {
                            font-family: $fontName;
                            src: url("$fontUrl");
                        }
                        .preview-text {
                            font-family: $fontName;
                            font-size: 10px;
                            margin-top: 10px;
                            display: block;
                        }
                    CSS;

                            return new HtmlString(<<<HTML
                        <style>
                        {$style}
                        </style>
                        <span class="preview-text">The quick brown fox jumps over the lazy dog</span>
                    HTML);
                        }),
                ]),
        ];

        $colorsSchema = [];
        foreach (ThemeCustomizerPlugin::COLOR_NAMES as $color) {
            $colorsSchema[] = ColorPicker::make('colors.' . $color)
                ->live()
                ->rgb()
                ->placeholder('Default color')
                ->columnSpan(3);

            $colorsSchema[] = TextEntry::make($color . '_text_preview')
                ->hiddenLabel()
                ->state($color)
                ->badge()
                ->color(fn (Get $get) => $get('colors.' . $color) ? Color::rgb($get('colors.' . $color)) : $color);

            $colorsSchema[] = Action::make('exclude_' . $color . '_button_preview')
                ->label($color)
                ->color(fn (Get $get) => $get('colors.' . $color) ? Color::rgb($get('colors.' . $color)) : $color);

            $colorsSchema[] = Action::make('exclude_' . $color . '_icon_button_preview')
                ->tooltip($color)
                ->iconButton()
                ->icon('tabler-palette')
                ->color(fn (Get $get) => $get('colors.' . $color) ? Color::rgb($get('colors.' . $color)) : $color);
        }
        $schema[] = Section::make('Colors')
            ->columns(6)
            ->columnSpanFull()
            ->schema($colorsSchema);

        $schema[] = Section::make('Theme Mode')
            ->columns()
            ->columnSpanFull()
            ->schema([
                ToggleButtons::make('default_theme_mode')
                    ->label('Default Theme Mode')
                    ->inline()
                    ->options(ThemeMode::class)
                    ->columnSpanFull(),
            ]);

        return $schema;
    }

    protected function getFormStatePath(): ?string
    {
        return 'data';
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('save')
                ->authorize(fn () => user()?->can('update themeCustomizer'))
                ->hiddenLabel()
                ->action('save')
                ->keyBindings(['mod+s'])
                ->tooltip(trans('filament-panels::resources/pages/edit-record.form.actions.save.label'))
                ->icon('tabler-device-floppy'),
        ];
    }

    public function save(): void
    {
        $formData = $this->form->getState();

        $envData = [
            'THEME_CUSTOMIZER_FONT' => $formData['font'],
            'THEME_CUSTOMIZER_DEFAULT_THEME_MODE' => $formData['default_theme_mode']?->value,
        ];

        foreach (ThemeCustomizerPlugin::COLOR_NAMES as $color) {
            $envData['THEME_CUSTOMIZER_COLORS_' . strtoupper($color)] = Arr::get($formData, 'colors.' . $color);
        }

        $this->writeToEnvironment($envData);

        Notification::make()
            ->title('Theme saved')
            ->success()
            ->send();

        $this->redirect(static::getUrl());
    }
}
