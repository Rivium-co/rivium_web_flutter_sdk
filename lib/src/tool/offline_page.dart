// Used by `dart run rivium_web:setup` (bin/setup.dart). Plain Dart: no Flutter here.
import 'dart:convert';

/// What the offline page shows, from the app's web/manifest.json.
class OfflineApp {
  const OfflineApp({required this.name, required this.background, required this.accent, this.iconDataUri});

  final String name;

  /// "#10203A".
  final String background;

  /// The button and glow colour.
  final String accent;

  /// "data:image/png;base64,…", inlined so the page needs nothing else.
  final String? iconDataUri;
}

/// Marks the block [offlineWorkerBlock] adds to the root service worker.
const offlineBegin = '// rivium_web:offline:begin';
const offlineEnd = '// rivium_web:offline:end';

/// A "#RRGGBB" colour, or null.
String? parseHex(Object? value) {
  if (value is! String) return null;
  final hex = value.trim();
  return RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(hex) ? hex.toUpperCase() : null;
}

/// [hex] mixed with white by [amount] (0–1).
String lighten(String hex, double amount) {
  final v = int.parse(hex.substring(1), radix: 16);
  String part(int shift) {
    final c = (v >> shift) & 0xFF;
    return (c + ((255 - c) * amount)).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  }

  return '#${part(16)}${part(8)}${part(0)}'.toUpperCase();
}

/// The first non-maskable icon of [manifest] (the largest up to 192px is enough for the page).
String? manifestIcon(Map<String, dynamic> manifest) {
  final icons = (manifest['icons'] as List? ?? const []).whereType<Map>().toList();
  int size(Map icon) => int.tryParse('${icon['sizes'] ?? ''}'.split('x').first) ?? 0;
  final plain = icons.where((i) => '${i['purpose'] ?? 'any'}'.contains('any')).toList()
    ..sort((a, b) => (size(a) - 192).abs().compareTo((size(b) - 192).abs()));
  return plain.isEmpty ? null : plain.first['src'] as String?;
}

String _html(String text) => const HtmlEscape().convert(text);

/// The offline page: everything inline (styles, icon, texts), so it works from the cache alone.
String offlineHtml(OfflineApp app) {
  final bg = app.background;
  final mid = lighten(bg, 0.06);
  final glow = lighten(bg, 0.14);
  final name = _html(app.name);
  final nameJs = jsonEncode(app.name);
  final icon = app.iconDataUri == null ? '' : '<img class="logo" src="${app.iconDataUri}" alt="">';
  return '''<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<meta name="theme-color" content="$bg">
<title>$name</title>
<style>
  html, body { margin: 0; height: 100%; background: $bg; }
  body {
    display: flex; flex-direction: column; align-items: center; justify-content: center;
    background: radial-gradient(120% 80% at 50% 38%, $glow 0%, $mid 45%, $bg 100%);
    color: #FFFFFF; text-align: center;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Tahoma, sans-serif;
    padding: env(safe-area-inset-top) 28px env(safe-area-inset-bottom); box-sizing: border-box;
  }
  .badge { position: relative; width: 88px; height: 88px; }
  .logo {
    width: 88px; height: 88px; border-radius: 24px; filter: saturate(0.6) brightness(0.9);
    box-shadow: 0 0 0 1px rgba(255, 255, 255, 0.08), 0 12px 40px ${_rgba(app.accent, 0.35)};
  }
  .off {
    position: absolute; right: -10px; bottom: -10px; width: 34px; height: 34px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    background: $mid; box-shadow: 0 0 0 3px $bg, 0 6px 18px rgba(0, 0, 0, 0.35);
  }
  h1 { margin: 28px 0 8px; font-size: 22px; font-weight: 650; letter-spacing: 0.2px; }
  p { margin: 0; max-width: 320px; font-size: 15px; line-height: 1.55; color: rgba(255, 255, 255, 0.66); }
  button {
    margin-top: 30px; min-width: 180px; height: 50px; padding: 0 28px; border: 0; border-radius: 25px;
    font: inherit; font-size: 16px; font-weight: 650; color: #FFFFFF; cursor: pointer;
    background: linear-gradient(135deg, ${lighten(app.accent, 0.12)}, ${app.accent});
    box-shadow: 0 10px 30px ${_rgba(app.accent, 0.45)}, inset 0 1px 0 rgba(255, 255, 255, 0.18);
    display: inline-flex; align-items: center; justify-content: center; gap: 10px;
    -webkit-tap-highlight-color: transparent; transition: transform 120ms ease, opacity 200ms ease;
  }
  button:active { transform: scale(0.97); }
  button[disabled] { opacity: 0.75; }
  .spin {
    display: none; width: 16px; height: 16px; border-radius: 50%;
    border: 2px solid rgba(255, 255, 255, 0.35); border-top-color: #FFFFFF; animation: spin 0.8s linear infinite;
  }
  button[disabled] .spin { display: inline-block; }
  .foot {
    position: absolute; bottom: calc(env(safe-area-inset-bottom) + 24px); left: 0; right: 0;
    font-size: 12px; letter-spacing: 0.4px; color: rgba(255, 255, 255, 0.38);
  }
  @keyframes spin { to { transform: rotate(360deg); } }
  @media (prefers-reduced-motion: reduce) { .spin { animation: none; } }
</style>
</head>
<body>
  <div class="badge">
    $icon
    <div class="off" aria-hidden="true">
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M2 2l20 20"/><path d="M8.5 16.5a5 5 0 0 1 7 0"/><path d="M2 8.82a15 15 0 0 1 4.17-2.65"/>
        <path d="M10.66 5c4.01-.36 8.14.9 11.34 3.76"/><path d="M16.85 11.25a10 10 0 0 1 2.22 1.68"/>
        <path d="M5 13a10 10 0 0 1 5.24-2.76"/><path d="M12 20h.01"/>
      </svg>
    </div>
  </div>
  <h1 id="title">You’re offline</h1>
  <p id="body"></p>
  <button id="retry" type="button"><span class="spin"></span><span id="retry-text">Try again</span></button>
  <div class="foot" id="foot"></div>
<script>
(function () {
  var name = $nameJs;
  var t = { title: 'You’re offline', body: 'Check your connection. ' + name + ' opens as soon as you’re back online.', retry: 'Try again' };
  document.getElementById('title').textContent = t.title;
  document.getElementById('body').textContent = t.body;
  document.getElementById('retry-text').textContent = t.retry;
  document.getElementById('foot').textContent = location.hostname;
  var button = document.getElementById('retry');
  var checking = false;
  function check(manual) {
    if (checking) return;
    checking = true;
    if (manual) button.disabled = true;
    fetch('./?abrova_online=' + Date.now(), { method: 'HEAD', cache: 'no-store' })
      .then(function (r) { if (r.ok) location.reload(); else throw 0; })
      .catch(function () { setTimeout(function () { button.disabled = false; }, manual ? 600 : 0); })
      .then(function () { checking = false; });
  }
  button.addEventListener('click', function () { check(true); });
  window.addEventListener('online', function () { check(false); });
  setInterval(function () { if (document.visibilityState === 'visible') check(false); }, 5000);
})();
</script>
</body>
</html>
''';
}

String _rgba(String hex, double alpha) {
  final v = int.parse(hex.substring(1), radix: 16);
  return 'rgba(${(v >> 16) & 0xFF}, ${(v >> 8) & 0xFF}, ${v & 0xFF}, $alpha)';
}

/// The block added to the root service worker: opening the app with no network shows offline.html. [version] changes
/// with the page, so the worker updates and caches the new page.
String offlineWorkerBlock(String version) => '''
$offlineBegin (dart run rivium_web:setup) — opening the app with no network shows offline.html.
(() => {
  const cacheName = 'rivium-web-offline-$version';
  const page = new URL('offline.html', self.registration.scope).href;
  const save = () => caches.open(cacheName).then((cache) => cache.add(new Request(page, { cache: 'reload' }))).catch(() => {});
  self.addEventListener('install', (event) => event.waitUntil(save()));
  self.addEventListener('activate', (event) => event.waitUntil(caches.keys().then((keys) => Promise.all(
    keys.filter((key) => key.startsWith('rivium-web-offline-') && key !== cacheName).map((key) => caches.delete(key)),
  ))));
  self.addEventListener('fetch', (event) => {
    if (event.request.mode !== 'navigate') return;
    event.respondWith(fetch(event.request).then((response) => {
      event.waitUntil(caches.match(page, { cacheName }).then((hit) => hit || save()));
      return response;
    }, (error) => caches.match(page, { cacheName }).then((offline) => offline || Promise.reject(error))));
  });
})();
$offlineEnd
''';

/// [worker] with the offline block (replacing an older one).
String withOfflineBlock(String worker, String version) {
  final start = worker.indexOf(offlineBegin);
  final end = worker.indexOf(offlineEnd);
  var base = worker;
  if (start >= 0 && end > start) {
    base = worker.substring(0, start) + worker.substring(end + offlineEnd.length).replaceFirst(RegExp(r'^\n'), '');
  }
  return '${base.trimRight()}\n\n${offlineWorkerBlock(version)}';
}
