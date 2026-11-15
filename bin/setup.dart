// Prepares a Flutter web app's web/ folder for people who install it:
//
//   dart run rivium_web:setup [--accent "#1C72C8"] [--no-splash]
//
// From web/manifest.json (name, background colour, icon) and --accent (glow, bar and button colour):
// - the launch screen in web/index.html, shown until Flutter draws its first frame;
// - the iPhone and iPad splash images (web/splash/, needs Google Chrome) and their tags in web/index.html;
// - web/offline.html, shown when the app is opened with no network, added to the root service worker
//   web/rivium-push-sw.js (from `dart run rivium_push:web_push_setup --root`, run first).
//
// Run it again after `rivium_push:web_push_setup` (that rewrites the worker) and when the manifest or icon change.
import 'dart:convert';
import 'dart:io';

import 'package:rivium_web/src/tool/launch_screen.dart';
import 'package:rivium_web/src/tool/offline_page.dart';
import 'package:rivium_web/src/tool/splash_render.dart';

Future<void> main(List<String> args) async {
  final withSplash = !args.contains('--no-splash');
  final accentArg = args.indexOf('--accent');
  final accent = accentArg >= 0 && accentArg + 1 < args.length ? parseHex(args[accentArg + 1]) : null;
  if (accentArg >= 0 && accent == null) _fail('--accent needs a colour like "#1C72C8"');

  final manifestFile = File('web/manifest.json');
  if (!manifestFile.existsSync()) _fail('No web/manifest.json: run this in the Flutter app\'s folder');
  final Map<String, dynamic> manifest;
  try {
    manifest = jsonDecode(manifestFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (_) {
    _fail('web/manifest.json is not valid JSON');
  }

  final name = (manifest['name'] ?? manifest['short_name'] ?? 'App') as String;
  final background = parseHex(manifest['background_color']) ?? parseHex(manifest['theme_color']) ?? '#10203A';
  final iconPath = manifestIcon(manifest);
  final icon = _dataUri(iconPath);
  final splashIcon = _dataUri(manifestIcon(manifest, largest: true)) ?? icon;

  final app = OfflineApp(
    name: name,
    background: background,
    accent: accent ?? lighten(background, 0.35),
    iconDataUri: icon,
  );

  // Launch screen and splash images.
  final index = File('web/index.html');
  if (!index.existsSync()) _fail('No web/index.html: run this in the Flutter app\'s folder');
  var splash = false;
  if (withSplash) {
    final chrome = findChrome();
    if (icon == null) {
      stderr.writeln('Splash images skipped: web/manifest.json has no icon file.');
    } else if (chrome == null) {
      stderr.writeln('Splash images skipped: Google Chrome not found (set CHROME to its path).');
    } else {
      final count = await renderSplashes(chrome, splashPage(app, splashIcon!), 'web');
      final shrunk = shrinkSplashes('web');
      stdout.writeln('Wrote $count splash images to web/splash/${shrunk ? '' : ' (not shrunk: python3 with Pillow not found)'}.');
      splash = true;
    }
  }
  try {
    index.writeAsStringSync(withLaunchScreen(index.readAsStringSync(), app, iconPath ?? 'favicon.png', withSplash: splash));
  } on FormatException catch (error) {
    _fail(error.message);
  }
  stdout.writeln('Wrote the launch screen${splash ? ' and splash tags' : ''} to web/index.html.');

  final html = offlineHtml(app);
  File('web/offline.html').writeAsStringSync(html);
  stdout.writeln('Wrote web/offline.html ($name).');

  final worker = File('web/rivium-push-sw.js');
  if (!worker.existsSync()) {
    stderr.writeln('Offline page not served: no web/rivium-push-sw.js. Run `dart run rivium_push:web_push_setup --root` '
        'first, then this again (the offline page is served by the app\'s root service worker).');
    return;
  }
  worker.writeAsStringSync(withOfflineBlock(worker.readAsStringSync(), _hash(html)));
  stdout.writeln('Added the offline page to web/rivium-push-sw.js.');
}

/// web/[path] inlined as a data: URI, or null.
String? _dataUri(String? path) {
  if (path == null) return null;
  final file = File('web/$path');
  if (!file.existsSync()) return null;
  final type = path.endsWith('.svg') ? 'image/svg+xml' : (path.endsWith('.webp') ? 'image/webp' : 'image/png');
  return 'data:$type;base64,${base64Encode(file.readAsBytesSync())}';
}

/// A short hash of [text] (FNV-1a), so the worker changes when the page does.
String _hash(String text) {
  var h = 0x811c9dc5;
  for (final unit in utf8.encode(text)) {
    h = ((h ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
