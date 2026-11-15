import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
              _Step(text.iosShare, cue: const _ShareCue()),
              _Step(text.iosAdd, cue: _MenuRowCue(text.menuAddToHome)),
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
          child: _GuideCard(
            margin: margin,
            accent: accentColor ?? Theme.of(buildContext).colorScheme.primary,
            icon: icon,
            appName: inApp ? text.inAppTitle(where.inAppBrowser ?? 'an app') : appName,
            subtitle: inApp ? text.title(appName) : text.subtitle,
            features: inApp
                ? const []
                : [
                    (Icons.notifications_active_rounded, text.featureNotifications),
                    (Icons.bolt_rounded, text.featureFast),
                    (Icons.fullscreen_rounded, text.featureFullScreen),
                  ],
            lead: inApp ? text.inAppBody : (steps.isEmpty ? text.benefit : null),
            steps: steps,
            primary: primary,
            notNow: (text.notNow, () {
              RiviumWeb.dismissInstallGuide(days: dismissDays);
              _dismissed.value = true;
            }),
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

/// Mixes [c] toward black (amount > 0) or white (amount < 0).
Color _shade(Color c, double amount) {
  final target = amount > 0 ? Colors.black : Colors.white;
  return Color.lerp(c, target, amount.abs())!;
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.margin,
    required this.accent,
    required this.icon,
    required this.appName,
    required this.subtitle,
    required this.features,
    required this.lead,
    required this.steps,
    required this.primary,
    required this.notNow,
  });

  final EdgeInsetsGeometry margin;
  final Color accent;
  final Widget? icon;
  final String appName;
  final String subtitle;
  final List<(IconData, String)> features;
  final String? lead;
  final List<_Step> steps;
  final (IconData, String, VoidCallback)? primary;
  final (String, VoidCallback) notNow;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deep = _shade(accent, 0.55);
    final light = _shade(accent, -0.18);
    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: deep.withValues(alpha: 0.28), blurRadius: 32, offset: const Offset(0, 14)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: brand gradient, the app's icon with a glow, its name, what installing gives.
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.topStart,
                    end: AlignmentDirectional.bottomEnd,
                    colors: [deep, accent, light],
                    stops: const [0, 0.62, 1],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _AppIcon(icon: icon, glow: light),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appName,
                                  style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 2),
                              Text(subtitle,
                                  style: textTheme.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.78))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (features.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [for (final (i, label) in features) _Pill(icon: i, label: label)],
                      ),
                    ],
                  ],
                ),
              ),
              // Body: the steps, with look-alikes of the controls to tap.
              ColoredBox(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (lead != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Text(lead!, style: textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, height: 1.45)),
                        ),
                      for (final (index, step) in steps.indexed)
                        _StepRow(
                          number: index + 1,
                          text: step.text,
                          cue: step.cue,
                          last: index == steps.length - 1,
                          accent: accent,
                          deep: deep,
                        ),
                      if (steps.isNotEmpty) const SizedBox(height: 10),
                      Row(
                        children: [
                          TextButton(
                            onPressed: notNow.$2,
                            style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                            child: Text(notNow.$1),
                          ),
                          const Spacer(),
                          if (primary != null)
                            _GradientButton(
                              icon: primary!.$1,
                              label: primary!.$2,
                              onPressed: primary!.$3,
                              colors: [deep, accent],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.icon, required this.glow});
  final Widget? icon;
  final Color glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [BoxShadow(color: glow.withValues(alpha: 0.55), blurRadius: 22, spreadRadius: -2)],
      ),
      clipBehavior: Clip.antiAlias,
      child: icon ?? const Icon(Icons.apps_rounded, color: Colors.white, size: 30),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 5),
          Text(label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.text,
    required this.cue,
    required this.last,
    required this.accent,
    required this.deep,
  });

  final int number;
  final String text;
  final Widget? cue;
  final bool last;
  final Color accent;
  final Color deep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // The line down to the next step is drawn behind the row, so the row can be any height.
    return Stack(
      children: [
        if (!last)
          PositionedDirectional(
            start: 13,
            top: 32,
            bottom: 4,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [accent.withValues(alpha: 0.45), accent.withValues(alpha: 0.08)],
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.only(bottom: last ? 4 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [deep, accent], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Text('$number',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurface, height: 1.35)),
                      if (cue != null) ...[const SizedBox(height: 8), cue!],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The iPhone Share button, as Safari draws it.
class _ShareCue extends StatelessWidget {
  const _ShareCue();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF0A84FF).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.ios_share, size: 20, color: Color(0xFF0A84FF)),
    );
  }
}

/// The "Add to Home Screen" row of the iPhone share menu, as iOS draws it.
class _MenuRowCue extends StatelessWidget {
  const _MenuRowCue(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
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

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.icon, required this.label, required this.onPressed, required this.colors});
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(colors: colors),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.4), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
