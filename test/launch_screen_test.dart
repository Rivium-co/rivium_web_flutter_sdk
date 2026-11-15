import 'package:rivium_web/src/tool/launch_screen.dart';
import 'package:rivium_web/src/tool/offline_page.dart';
import 'package:flutter_test/flutter_test.dart';

const app = OfflineApp(name: 'Team <A>', background: '#10203A', accent: '#1C72C8');

const flutterIndex = '''<!DOCTYPE html>
<html>
<head>
  <title>t</title>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
''';

void main() {
  test('colours mix towards the accent', () {
    expect(mix('#000000', '#FFFFFF', 0.5), '#808080');
    expect(surfaceGradient(app), contains('#10203A 100%'));
  });

  test('the launch screen goes before the bootstrap script, the splash tags before </head>', () {
    final html = withLaunchScreen(flutterIndex, app, 'icons/Icon-192.png', withSplash: true);
    expect(html.indexOf(launchBegin), lessThan(html.indexOf('flutter_bootstrap.js')));
    expect(html.indexOf(splashEnd), lessThan(html.indexOf('</head>')));
    expect('apple-touch-startup-image'.allMatches(html).length, splashDevices.length);
    expect(html, contains('<h1>Team &lt;A&gt;</h1>'));
    expect(html, contains('src="icons/Icon-192.png"'));
    expect(html, contains('#rivium-launch[dir="rtl"] .bar::after'));
    expect(html, contains('flutter-first-frame'));
  });

  test('running again replaces the blocks', () {
    final once = withLaunchScreen(flutterIndex, app, 'icons/Icon-192.png', withSplash: true);
    final twice = withLaunchScreen(once, const OfflineApp(name: 'Other', background: '#000000', accent: '#FFFFFF'),
        'icons/Icon-192.png', withSplash: true);
    expect(launchBegin.allMatches(twice).length, 1);
    expect(splashBegin.allMatches(twice).length, 1);
    expect(twice, contains('<h1>Other</h1>'));
    expect(twice, isNot(contains('Team &lt;A&gt;')));
    expect(withLaunchScreen(twice, app, 'icons/Icon-192.png', withSplash: true), once);
  });

  test('without splash images the tags are left as they are', () {
    final html = withLaunchScreen(flutterIndex, app, 'i.png', withSplash: false);
    expect(html, isNot(contains(splashBegin)));
  });

  test('an index.html without the bootstrap script is refused', () {
    expect(() => withLaunchScreen('<html></html>', app, 'i.png', withSplash: false), throwsFormatException);
  });

  test('the splash page is the launch screen without moving parts', () {
    final page = splashPage(app, 'data:image/png;base64,AA==');
    expect(page, contains('data:image/png;base64,AA=='));
    expect(page, isNot(contains('class="bar"')));
  });
}
