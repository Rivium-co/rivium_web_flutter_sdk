/// The texts of [RiviumInstallGuide]. English is built in; pass your own for other wording or languages.
class RiviumInstallStrings {
  const RiviumInstallStrings({
    required this.subtitle,
    required this.featureNotifications,
    required this.featureFast,
    required this.featureFullScreen,
    required this.menuAddToHome,
    required this.title,
    required this.benefit,
    required this.iosShare,
    required this.iosAdd,
    required this.openFromIcon,
    required this.androidMenu,
    required this.androidAdd,
    required this.install,
    required this.inAppTitle,
    required this.inAppBody,
    required this.copyLink,
    required this.linkCopied,
    required this.notNow,
  });

  /// Under the app name in the header: "Install the app".
  final String subtitle;
  final String featureNotifications;
  final String featureFast;
  final String featureFullScreen;

  /// The iPhone menu row the user looks for.
  final String menuAddToHome;

  /// "Add {app} to your Home Screen".
  final String Function(String app) title;

  /// Why: notifications, faster opening.
  final String benefit;
  final String iosShare;
  final String iosAdd;

  /// "Open {app} from its new icon".
  final String Function(String app) openFromIcon;
  final String androidMenu;
  final String androidAdd;
  final String install;

  /// "This page is open inside {browser}".
  final String Function(String browser) inAppTitle;
  final String inAppBody;
  final String copyLink;
  final String linkCopied;
  final String notNow;

  static final en = RiviumInstallStrings(
    subtitle: 'Install the app',
    featureNotifications: 'Notifications',
    featureFast: 'Opens instantly',
    featureFullScreen: 'Full screen',
    menuAddToHome: 'Add to Home Screen',
    title: (app) => 'Add $app to your Home Screen',
    benefit: 'Get notifications and open it faster, like an app.',
    iosShare: 'Tap the Share button',
    iosAdd: 'Choose “Add to Home Screen”',
    openFromIcon: (app) => 'Open $app from its new icon',
    androidMenu: 'Tap the browser menu ⋮',
    androidAdd: 'Choose “Install app” or “Add to Home screen”',
    install: 'Install',
    inAppTitle: (browser) => 'This page is open inside $browser',
    inAppBody: 'To install it, open it in Safari or Chrome: tap the menu (⋯) and choose “Open in browser”, or copy the link and paste it there.',
    copyLink: 'Copy link',
    linkCopied: 'Link copied',
    notNow: 'Not now',
  );

  /// The built-in texts for a language (English).
  static RiviumInstallStrings forLanguage(String languageCode) => en;
}
