# rivium_web

For Flutter web apps that people install on their phone (PWA): where the app runs, and a ready-made
"Add to Home Screen" guide.

## Install

```yaml
dependencies:
  rivium_web: ^0.1.1
```

## Install guide

```dart
RiviumInstallGuide(appName: 'Lino', icon: Image.asset('assets/icon.png'))
```

It shows what is needed where the app runs, and nothing elsewhere:

- iPhone and iPad Safari: Share › Add to Home Screen › open from the icon.
- Android: an Install button (the browser's install prompt), or the menu steps.
- Inside Instagram, Facebook and other apps: open in the browser, with Copy link.
- Installed, on a computer, or in a native build: nothing.

Pass `strings:` for your own texts or language. "Not now" hides it for 7 days.

## Where the app runs

```dart
final where = RiviumWeb.context;
where.installed;      // opened from the Home Screen
where.installNeed;    // none, iosAddToHomeScreen, androidInstall, openInBrowser
where.inAppBrowser;   // 'Instagram', … or null
```

Docs: https://rivium.co/docs/push/install-guide
