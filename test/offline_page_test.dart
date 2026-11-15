import 'package:rivium_web/src/tool/offline_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('colours', () {
    expect(parseHex('#10203a'), '#10203A');
    expect(parseHex('blue'), isNull);
    expect(lighten('#000000', 0.5), '#808080');
    expect(lighten('#10203A', 0), '#10203A');
  });

  test('the icon is the plain one closest to 192px', () {
    expect(
      manifestIcon({
        'icons': [
          {'src': 'icons/Icon-512.png', 'sizes': '512x512'},
          {'src': 'icons/Icon-maskable-192.png', 'sizes': '192x192', 'purpose': 'maskable'},
          {'src': 'icons/Icon-192.png', 'sizes': '192x192'},
        ],
      }),
      'icons/Icon-192.png',
    );
    expect(manifestIcon({}), isNull);
  });

  test('the page has the name (escaped), the texts and no outside files', () {
    final html = offlineHtml(const OfflineApp(name: 'Team <&>', background: '#10203A', accent: '#1C72C8'));
    expect(html, contains('<title>Team &lt;&amp;&gt;</title>'));
    expect(html, contains('"Team <&>"')); // the script's copy, as a JS string
    expect(html, contains('You’re offline'));
    expect(RegExp(r'(src|href)="(https?:)?//').hasMatch(html), isFalse);
  });

  test('the worker block is added once and replaced on the next run', () {
    const worker = "self.addEventListener('push', () => {});\n";
    final once = withOfflineBlock(worker, 'aaaa1111');
    expect(once, startsWith(worker.trimRight()));
    expect(once, contains("'rivium-web-offline-aaaa1111'"));

    final twice = withOfflineBlock(once, 'bbbb2222');
    expect(offlineBegin.allMatches(twice).length, 1);
    expect(twice, contains("'rivium-web-offline-bbbb2222'"));
    expect(twice, isNot(contains('aaaa1111')));
    expect(twice, startsWith(worker.trimRight()));
  });
}
