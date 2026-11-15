import 'package:rivium_web/rivium_web.dart';
import 'package:flutter_test/flutter_test.dart';

const iPhoneSafari =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Mobile/15E148 Safari/604.1';
const iPhoneSafari26 =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Mobile/15E148 Safari/604.1';
const iPhoneInstagram =
    'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148 Instagram 350.0.0.0';
const iPhoneWebView = 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148';
const iPad = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.6 Safari/605.1.15';
const androidChrome =
    'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36';
const androidWebView =
    'Mozilla/5.0 (Linux; Android 10; K; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/131.0.0.0 Mobile Safari/537.36';
const macChrome = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36';

RiviumInstallNeed need(String ua, {bool installed = false, int touch = 0}) =>
    RiviumWebContext.fromUserAgent(ua, installed: installed, maxTouchPoints: touch).installNeed;

void main() {
  test('iPhone Safari tab: Add to Home Screen; installed: nothing', () {
    expect(need(iPhoneSafari), RiviumInstallNeed.iosAddToHomeScreen);
    expect(need(iPhoneSafari, installed: true), RiviumInstallNeed.none);
  });

  test('iPad says Macintosh but has a touch screen; a Mac does not', () {
    expect(need(iPad, touch: 5), RiviumInstallNeed.iosAddToHomeScreen);
    expect(need(iPad), RiviumInstallNeed.none);
  });

  test('Safari version: 26 says OS 18_6 but Version/26; iPad is an iPad', () {
    expect(RiviumWebContext.fromUserAgent(iPhoneSafari26, installed: false).safariVersion, 26);
    expect(RiviumWebContext.fromUserAgent(iPhoneSafari, installed: false).safariVersion, 18);
    expect(RiviumWebContext.fromUserAgent(iPad, installed: false, maxTouchPoints: 5).isIpad, isTrue);
    expect(RiviumWebContext.fromUserAgent(iPhoneSafari, installed: false).isIpad, isFalse);
  });

  test('in-app browsers: open in the browser first', () {
    final instagram = RiviumWebContext.fromUserAgent(iPhoneInstagram, installed: false);
    expect(instagram.installNeed, RiviumInstallNeed.openInBrowser);
    expect(instagram.inAppBrowser, 'Instagram');
    expect(RiviumWebContext.fromUserAgent(iPhoneWebView, installed: false).inAppBrowser, 'an app');
    expect(need(androidWebView), RiviumInstallNeed.openInBrowser);
  });

  test('Android Chrome: install; computers and native builds: nothing', () {
    expect(need(androidChrome), RiviumInstallNeed.androidInstall);
    expect(need(macChrome), RiviumInstallNeed.none);
    expect(RiviumWebContext.native.installNeed, RiviumInstallNeed.none);
  });
}
