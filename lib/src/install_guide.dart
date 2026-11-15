import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'card.dart';
import 'install_strings.dart';
import 'web_context.dart';

/// Shows how to install the web app where that is needed, and nothing elsewhere: iPhone Safari (Share › Add to Home
/// Screen), Android (the browser's Install prompt, or its menu), an app's in-app browser (open it in the browser,
/// with Copy link). Hidden when installed, on a computer, in a native build, and for 7 days after "Not now".
///
/// ```dart
/// RiviumInstallGuide(appName: 'Lino', icon: Image.asset('assets/icon.png'))
/// ```
class RiviumInstallGuide extends StatelessWidget {
  const RiviumInstallGuide({
    super.key,
    required this.appName,
    this.icon,
    this.accentColor,
    this.strings,
    this.context,
    this.margin = const EdgeInsets.all(16),
    this.dismissDays = 7,
  });

  /// Your app's name, as on its Home Screen icon.
  final String appName;

  /// Your app's icon (for example `Image.asset('assets/icon.png')`), shown in the header.
  final Widget? icon;

  /// The header's colour; default: the theme's primary colour.
  final Color? accentColor;

  /// Texts; default: English.
  final RiviumInstallStrings? strings;

  /// Where the app runs; default [RiviumWeb.context] (pass one to preview the guide).
  final RiviumWebContext? context;
  final EdgeInsetsGeometry margin;

  /// How long "Not now" hides the guide.
  final int dismissDays;

  static final _dismissed = ValueNotifier<bool>(false);

  @override
  Widget build(BuildContext buildContext) {
    final where = context ?? RiviumWeb.context;
    final need = where.installNeed;
    if (need == RiviumInstallNeed.none) return const SizedBox.shrink();
    return ValueListenableBuilder<bool>(
      valueListenable: _dismissed,
      builder: (buildContext, dismissed, _) {
        if (dismissed || (context == null && RiviumWeb.installGuideDismissed)) return const SizedBox.shrink();
        final text = strings ??
            RiviumInstallStrings.forLanguage(Localizations.maybeLocaleOf(buildContext)?.languageCode ?? 'en');
        final inApp = need == RiviumInstallNeed.openInBrowser;
        final steps = switch (need) {
          RiviumInstallNeed.iosAddToHomeScreen => [
              // Safari 26 put Share under ⋯; on iPad the button is at the top.
              if (!where.isIpad && (where.safariVersion ?? 0) >= 26)
                _Step(text.iosShareMore, cue: const _ShareCue(more: true))
              else
                _Step(where.isIpad ? text.iosShareIpad : text.iosShare, cue: const _ShareCue()),
              _Step(text.iosAdd, cue: _MenuRowCue(text.menuAddToHome, caption: text.menuCaption)),
              _Step(text.openFromIcon(appName)),
            ],
          RiviumInstallNeed.androidInstall when !where.canPromptInstall => [
              _Step(text.androidMenu, cue: const _IconCue(Icons.more_vert)),
              _Step(text.androidAdd, cue: const _IconCue(Icons.install_mobile)),
              _Step(text.openFromIcon(appName)),
            ],
          _ => const <_Step>[],
        };
        final primary = switch (need) {
          RiviumInstallNeed.androidInstall when where.canPromptInstall => (Icons.download_rounded, text.install, () async {
              if (await RiviumWeb.promptInstall()) _dismissed.value = true;
            }),
          RiviumInstallNeed.openInBrowser => (Icons.link_rounded, text.copyLink, () async {
              await Clipboard.setData(ClipboardData(text: Uri.base.toString()));
              if (buildContext.mounted) {
                ScaffoldMessenger.maybeOf(buildContext)?.showSnackBar(SnackBar(content: Text(text.linkCopied)));
              }
            }),
          _ => null,
        };
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => Opacity(
            opacity: t,
            child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
          ),
          child: LuxuryCard(
            margin: margin,
            accent: accentColor ?? Theme.of(buildContext).colorScheme.primary,
            icon: icon,
            title: inApp ? text.inAppTitle(where.inAppBrowser ?? 'an app') : appName,
            subtitle: inApp ? text.title(appName) : text.subtitle,
            features: inApp
                ? const []
                : [
                    (Icons.notifications_active_rounded, text.featureNotifications),
                    (Icons.bolt_rounded, text.featureFast),
                    (Icons.fullscreen_rounded, text.featureFullScreen),
                  ],
            body: [
              if (inApp || steps.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(inApp ? text.inAppBody : text.benefit,
                      style: Theme.of(buildContext).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(buildContext).colorScheme.onSurfaceVariant, height: 1.45)),
                ),
              for (final (index, step) in steps.indexed)
                StepRow(
                  number: index + 1,
                  text: step.text,
                  cue: step.cue,
                  last: index == steps.length - 1,
                  accent: accentColor ?? Theme.of(buildContext).colorScheme.primary,
                  deep: shade(accentColor ?? Theme.of(buildContext).colorScheme.primary, 0.55),
                ),
            ],
            secondary: (text.notNow, () {
              RiviumWeb.dismissInstallGuide(days: dismissDays);
              _dismissed.value = true;
            }),
            primary: primary,
          ),
        );
      },
    );
  }

  /// Shows the guide again after "Not now" (tests, or a "How to install" item in your settings).
  static void resetDismissed() => _dismissed.value = false;
}

class _Step {
  const _Step(this.text, {this.cue});
  final String text;

  /// A small look-alike of the control to tap.
  final Widget? cue;
}

/// The iPhone Share button, as Safari draws it ([more]: Safari 26's ⋯ first).
class _ShareCue extends StatelessWidget {
  const _ShareCue({this.more = false});
  final bool more;

  Widget _button(IconData icon) => Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0A84FF)),
      );

  @override
  Widget build(BuildContext context) {
    if (!more) return _button(Icons.ios_share);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _button(Icons.more_horiz),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.arrow_forward_rounded, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        _button(Icons.ios_share),
      ],
    );
  }
}

/// The "Add to Home Screen" row of the iPhone share menu, as iOS draws it.
class _MenuRowCue extends StatelessWidget {
  const _MenuRowCue(this.label, {required this.caption});
  final String label;

  /// "In Safari's Share menu:" — the row is a picture of what to find there, not a button.
  final String caption;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(caption,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        _row(dark),
      ],
    );
  }

  Widget _row(bool dark) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 260),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: dark ? Colors.white12 : const Color(0x14000000)),
          boxShadow: const [BoxShadow(color: Color(0x12000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    color: dark ? Colors.white : Colors.black,
                    fontFamily: '.SF Pro Text',
                    fontFamilyFallback: const ['Roboto', 'Helvetica', 'Arial'],
                  )),
            ),
            Icon(Icons.add_box_outlined, size: 22, color: dark ? Colors.white : Colors.black87),
          ],
        ),
      ),
    );
  }
}

class _IconCue extends StatelessWidget {
  const _IconCue(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(color: scheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, size: 20, color: scheme.primary),
    );
  }
}

