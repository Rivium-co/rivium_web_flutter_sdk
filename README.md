# rivium_web

For Flutter web apps that people install on their phone (PWA): where the app runs, and a ready-made
"Add to Home Screen" guide.

## Install

```yaml
dependencies:
  rivium_web: ^0.4.0
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

## New versions

```dart
void main() {
  RiviumWebUpdates.start(); // version.json now, when the app comes back, and every 10 minutes
  runApp(MaterialApp(
    builder: (context, child) => RiviumUpdateGate(child: child!), // required updates
    home: …,
  ));
}

RiviumUpdatePrompt(icon: Image.asset('assets/icon.png')) // "New version available" · Reload · Later
```

Build every deploy with its own build number, so open pages see it (the prompt shows "Version 0.5.1 (build 13)"
when only the build changed):

```bash
flutter build web --release --build-number=13
```

Optional `web/update.json`: `{"minimum": "0.6.0", "notes": {"en": "…"}}` — below `minimum` the update is
required.

## Launch screen, splash images and offline page

```bash
dart run rivium_push:web_push_setup --root
dart run rivium_web:setup --accent "#1C72C8"
```

From `web/manifest.json` (name, `background_color`, icons) and `--accent`:

- the launch screen in `web/index.html` (icon, name, loading bar), until Flutter's first frame;
- the iPhone and iPad splash images in `web/splash/` with their tags in `web/index.html` (needs Google Chrome;
  `--no-splash` skips them);
- `web/offline.html`, added to the root service worker `web/rivium-push-sw.js`: opening the app with no network
  shows it, and it reloads when the connection is back.

Run both again after upgrading `rivium_push`, and when the manifest or icons change.

Docs: https://rivium.co/docs/push/install-guide
