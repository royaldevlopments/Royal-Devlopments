# NoirUI Theme for PteroCA

A modern, minimal theme for PteroCA with a clean design and improved user experience.

## Features

- **Custom Satoshi Font**: Clean, modern typography throughout
- **Redesigned Sidebar**: 
  - White background with 350px width
  - Fixed position with scrollable menu
  - User info section at bottom with role display
  - Hidden scrollbar for clean appearance
  - Search bar with keyboard shortcuts hint
- **Modern Dashboard**:
  - Breadcrumb navigation
  - Quick action cards with icons and descriptions
  - Redesigned servers list with status badges
  - Enhanced balance section with gradient background
  - Activity timeline with clean card layout
- **Design System**:
  - No shadows, minimal borders
  - Squircle icon backgrounds
  - Consistent spacing and typography
  - Gray color palette with primary blue accents
  - Responsive grid layouts

## Installation

### Auto Installer (Recommended)

The easiest way to install NoirUI theme:

```bash
git clone https://github.com/craterXO/NoirUI-pteroca-theme.git
cd NoirUI-pteroca-theme
chmod +x install.sh
sudo ./install.sh
```

The installer will:
- Auto-detect your PteroCA installation
- Backup existing theme (if present)
- Copy all theme files
- Set proper permissions
- Clear all caches (Symfony, OPcache, Twig)
- Provide clear next steps

### Manual Installation

If you prefer to install manually:

1. **Copy theme files**:
   ```bash
   cp -r themes/noirui /path/to/pteroca/themes/
   cp -r public/assets/theme/noirui /path/to/pteroca/public/assets/theme/
   ```

2. **Set proper permissions**:
   ```bash
   chown -R www-data:www-data /path/to/pteroca/themes/noirui
   chown -R www-data:www-data /path/to/pteroca/public/assets/theme/noirui
   ```

3. **Clear cache**:
   ```bash
   cd /path/to/pteroca
   php bin/console cache:clear
   php bin/console cache:warmup
   ```

4. **Set as active theme**:
   - Go to Admin Panel > Settings > Theme Settings
   - Select "NoirUI" from the theme dropdown
   - Save changes

## File Structure

```
NoirUI-pteroca-theme/
├── themes/noirui/           # Theme templates
│   ├── base.html.twig
│   ├── bundles/             # EasyAdmin overrides
│   ├── components/          # Reusable components
│   ├── panel/               # Panel templates
│   ├── _partials/           # Template partials
│   └── template.json        # Theme metadata
└── public/assets/theme/noirui/  # Theme assets
    ├── css/                 # Stylesheets
    │   ├── panel.css       # Main panel styles
    │   ├── errors.css      # Error page styles
    │   └── error-page.css  # Alternative error styles
    ├── fonts/              # Custom fonts
    │   ├── fonts.css       # Font declarations
    │   └── Satoshi-Regular.woff2
    ├── img/                # Theme images
    └── js/                 # JavaScript files
```

## Compatibility

- **PteroCA Version**: Compatible with latest version
- **PHP Version**: 8.1+
- **Browser Support**: Modern browsers (Chrome, Firefox, Safari, Edge)

## Credits

- **Theme Design**: Mason
- **Font**: Satoshi by Indian Type Foundry
- **Icons**: Lucide Icons (https://lucide.dev/)
- **Avatar API**: DiceBear Glass Style (https://www.dicebear.com/styles/glass/)

## Support

For issues, questions, or feature requests, please refer to the PteroCA documentation:
https://docs.pteroca.com/for-developers/themes/getting-started

## License

This theme follows the same license as PteroCA.
