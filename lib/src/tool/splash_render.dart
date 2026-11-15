// Used by `dart run rivium_web:setup` (bin/setup.dart): renders the splash images in headless Chrome.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'launch_screen.dart';

/// Google Chrome or Chromium on this machine: $CHROME, else the usual places.
String? findChrome() {
  final fromEnv = Platform.environment['CHROME'];
  if (fromEnv != null && File(fromEnv).existsSync()) return fromEnv;
  const mac = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
  ];
  for (final path in mac) {
    if (File(path).existsSync()) return path;
  }
  for (final name in ['google-chrome', 'google-chrome-stable', 'chromium', 'chromium-browser']) {
    final which = Process.runSync('which', [name]);
    if (which.exitCode == 0) return (which.stdout as String).trim();
  }
  return null;
}

/// Renders [page] at every size of [splashDevices] into [webDir]/splash/. Returns the number of images.
Future<int> renderSplashes(String chrome, String page, String webDir) async {
  final profile = Directory.systemTemp.createTempSync('rivium-web-splash-');
  final process = await Process.start(chrome, [
    '--headless=new',
    '--remote-debugging-port=0',
    '--user-data-dir=${profile.path}',
    '--hide-scrollbars',
    '--no-first-run',
    '--no-default-browser-check',
    'about:blank',
  ]);
  unawaited(process.stdout.drain<void>());
  unawaited(process.stderr.drain<void>());
  WebSocket? socket;
  try {
    // Chrome writes the port it picked into the profile.
    final portFile = File('${profile.path}/DevToolsActivePort');
    for (var i = 0; i < 100 && !portFile.existsSync(); i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    if (!portFile.existsSync()) throw StateError('Chrome did not start');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final port = portFile.readAsLinesSync().first.trim();
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:$port/json/version'));
    final version = jsonDecode(await (await request.close()).transform(utf8.decoder).join()) as Map<String, dynamic>;
    client.close();
    socket = await WebSocket.connect(version['webSocketDebuggerUrl'] as String);

    var id = 0;
    final pending = <int, Completer<Map<String, dynamic>>>{};
    socket.listen((data) {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final waiting = pending.remove(message['id']);
      if (waiting == null) return;
      if (message['error'] != null) {
        waiting.completeError(StateError('Chrome: ${message['error']}'));
      } else {
        waiting.complete((message['result'] as Map?)?.cast<String, dynamic>() ?? const {});
      }
    });
    Future<Map<String, dynamic>> send(String method, [Map<String, dynamic> params = const {}, String? session]) {
      final completer = Completer<Map<String, dynamic>>();
      pending[++id] = completer;
      socket!.add(jsonEncode({'id': id, 'method': method, 'params': params, if (session != null) 'sessionId': session}));
      return completer.future.timeout(const Duration(seconds: 30));
    }

    final target = await send('Target.createTarget', {'url': 'about:blank'});
    final attached = await send('Target.attachToTarget', {'targetId': target['targetId'], 'flatten': true});
    final session = attached['sessionId'] as String;
    await send('Page.enable', {}, session);
    final frames = await send('Page.getFrameTree', {}, session);
    final frameId = (frames['frameTree'] as Map)['frame']['id'];
    await send('Page.setDocumentContent', {'frameId': frameId, 'html': page}, session);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final dir = Directory('$webDir/splash');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    for (final d in splashDevices) {
      await send('Emulation.setDeviceMetricsOverride',
          {'width': d.$1, 'height': d.$2, 'deviceScaleFactor': d.$3, 'mobile': true}, session);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final shot = await send('Page.captureScreenshot', {'format': 'png', 'captureBeyondViewport': false}, session);
      File('$webDir/${splashFile(d)}').writeAsBytesSync(base64Decode(shot['data'] as String));
    }
    return splashDevices.length;
  } finally {
    await socket?.close();
    process.kill();
    await process.exitCode.timeout(const Duration(seconds: 5), onTimeout: () => 0);
    try {
      profile.deleteSync(recursive: true);
    } catch (_) {
      // Chrome may still hold a file for a moment; the temp folder is cleaned by the system.
    }
  }
}

/// A navy gradient needs few colours: a 256-colour palette (dithered, so no banding) makes the PNGs about a fifth of
/// the size. Needs python3 with Pillow; without it the images stay as Chrome wrote them. True when shrunk.
bool shrinkSplashes(String webDir) {
  try {
    final result = Process.runSync('python3', [
      '-c',
      '''
import sys, glob
from PIL import Image
for path in glob.glob(sys.argv[1] + '/splash/*.png'):
    img = Image.open(path).convert('RGB')
    img.quantize(colors=256, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.FLOYDSTEINBERG).save(path, optimize=True)
''',
      webDir,
    ]);
    return result.exitCode == 0;
  } catch (_) {
    return false;
  }
}
