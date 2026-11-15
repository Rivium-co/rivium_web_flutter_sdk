// Prepares a Flutter web app's web/ folder for people who install it:
//
//   dart run rivium_web:setup [--accent "#1C72C8"]
//
// - web/offline.html: shown when the app is opened with no network (name, colours and icon from web/manifest.json;
//   --accent is the button colour).
// - adds the offline page to the root service worker web/rivium-push-sw.js (from
//   `dart run rivium_push:web_push_setup --root`, which is run first).
//
// Run it again after `rivium_push:web_push_setup` (that rewrites the worker) and when the manifest or icon change.
import 'dart:convert';
import 'dart:io';

import 'package:rivium_web/src/tool/offline_page.dart';

void main(List<String> args) {
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
  String? icon;
  final iconPath = manifestIcon(manifest);
  if (iconPath != null) {
    final file = File('web/$iconPath');
    if (file.existsSync()) {
      final type = iconPath.endsWith('.svg') ? 'image/svg+xml' : (iconPath.endsWith('.webp') ? 'image/webp' : 'image/png');
      icon = 'data:$type;base64,${base64Encode(file.readAsBytesSync())}';
    }
  }

  final html = offlineHtml(OfflineApp(
    name: name,
    background: background,
    accent: accent ?? lighten(background, 0.35),
    iconDataUri: icon,
  ));
  File('web/offline.html').writeAsStringSync(html);
  stdout.writeln('Wrote web/offline.html ($name).');

  final worker = File('web/rivium-push-sw.js');
  if (!worker.existsSync()) {
    _fail('No web/rivium-push-sw.js: run `dart run rivium_push:web_push_setup --root` first '
        '(the offline page is served by the app\'s root service worker)');
  }
  worker.writeAsStringSync(withOfflineBlock(worker.readAsStringSync(), _hash(html)));
  stdout.writeln('Added the offline page to web/rivium-push-sw.js.');
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
