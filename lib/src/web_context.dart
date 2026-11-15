import 'platform/platform.dart' as platform;

/// What the user has to do to have the app installed.
enum RiviumInstallNeed {
  /// Nothing: installed already, a native app, or a computer.
  none,

  /// iPhone or iPad browser: Share › Add to Home Screen. Web Push works only there.
  iosAddToHomeScreen,

  /// Android browser: install the app (the browser's install prompt, or its menu).
  androidInstall,

  /// The page is open inside another app (Instagram, …), which cannot install it: open it in the browser first.
  openInBrowser,
}

/// Where a Flutter web app is running.
class RiviumWebContext {
  const RiviumWebContext({
    required this.isWeb,
    required this.isIos,
    required this.isAndroid,
    required this.installed,
    this.isIpad = false,
    this.safariVersion,
    this.inAppBrowser,
    this.canPromptInstall = false,
  });

  /// A native (Android, iOS, desktop) build: nothing to install.
  static const native = RiviumWebContext(isWeb: false, isIos: false, isAndroid: false, installed: true);

  final bool isWeb;

  /// iPhone or iPad (iPadOS reports itself as a Mac with a touch screen).
  final bool isIos;
  final bool isAndroid;

  /// iPad (Safari's Share button is at the top there).
  final bool isIpad;

  /// Safari's major version on iPhone and iPad (`Version/26`); null when unknown. From 26 the Share button is under ⋯.
  final int? safariVersion;

  /// Opened as an installed app (from the Home Screen), not in a browser tab.
  final bool installed;

  /// The app whose built-in browser shows the page ('Instagram', 'Facebook', …; 'an app' when unknown), null in a real
  /// browser.
  final String? inAppBrowser;

  /// Android: the browser offered its install prompt, so [RiviumWeb.promptInstall] shows it.
  final bool canPromptInstall;

  RiviumInstallNeed get installNeed {
    if (!isWeb || installed) return RiviumInstallNeed.none;
    if (inAppBrowser != null && (isIos || isAndroid)) return RiviumInstallNeed.openInBrowser;
    if (isIos) return RiviumInstallNeed.iosAddToHomeScreen;
    if (isAndroid) return RiviumInstallNeed.androidInstall;
    return RiviumInstallNeed.none;
  }

  static const _inAppTokens = <String, String>{
    'Instagram': 'Instagram',
    'FBAN': 'Facebook',
    'FBAV': 'Facebook',
    'FB_IAB': 'Facebook',
    'LinkedInApp': 'LinkedIn',
    'BytedanceWebview': 'TikTok',
    'musical_ly': 'TikTok',
    'Snapchat': 'Snapchat',
    'Line/': 'LINE',
    'Telegram': 'Telegram',
  };

  /// Reads a browser's user agent. [maxTouchPoints] tells an iPad (which says "Macintosh") from a Mac.
  static RiviumWebContext fromUserAgent(
    String userAgent, {
    required bool installed,
    int maxTouchPoints = 0,
    bool canPromptInstall = false,
  }) {
    final isIpad = userAgent.contains('iPad') || (userAgent.contains('Macintosh') && maxTouchPoints > 1);
    final isIos = isIpad || RegExp('iPhone|iPod').hasMatch(userAgent);
    final isAndroid = !isIos && userAgent.contains('Android');
    String? inApp;
    for (final entry in _inAppTokens.entries) {
      if (userAgent.contains(entry.key)) {
        inApp = entry.value;
        break;
      }
    }
    // Android WebView ("; wv)"), or an iOS web view: every iOS browser says "Safari/", an app's web view does not.
    if (inApp == null && !installed) {
      if (isAndroid && userAgent.contains('; wv)')) inApp = 'an app';
      if (isIos && !userAgent.contains('Safari/')) inApp = 'an app';
    }
    // Safari's own version: from iOS 26 the user agent keeps saying "OS 18_6", only "Version/26" tells.
    final safari = isIos ? int.tryParse(RegExp(r'Version/(\d+)').firstMatch(userAgent)?.group(1) ?? '') : null;
    return RiviumWebContext(
      isWeb: true,
      isIos: isIos,
      isAndroid: isAndroid,
      isIpad: isIpad,
      safariVersion: safari,
      installed: installed,
      inAppBrowser: inApp,
      canPromptInstall: canPromptInstall,
    );
  }
}

/// Entry points.
abstract final class RiviumWeb {
  /// Where the app runs now ([RiviumWebContext.native] outside the web).
  static RiviumWebContext get context => platform.readContext();

  /// Android: shows the browser's install prompt. True when the user installed the app.
  static Future<bool> promptInstall() => platform.promptInstall();

  /// "Not now" for the install guide, kept in the browser for [days].
  static void dismissInstallGuide({int days = 7}) =>
      platform.setDismissedUntil(DateTime.now().add(Duration(days: days)));

  /// Whether "Not now" is still in effect.
  static bool get installGuideDismissed {
    final until = platform.dismissedUntil();
    return until != null && until.isAfter(DateTime.now());
  }
}
