import 'dart:ui';

import 'package:flutter/material.dart';

import 'card.dart';
import 'update_strings.dart';
import 'updates.dart';

String _shown(String version) => version.split('+').first;

RiviumUpdateStrings _strings(BuildContext context, RiviumUpdateStrings? strings) =>
    strings ?? RiviumUpdateStrings.forLanguage(Localizations.maybeLocaleOf(context)?.languageCode ?? 'en');

List<Widget> _body(BuildContext context, RiviumUpdateStrings text, RiviumUpdateInfo info, String lead) {
  final theme = Theme.of(context);
  final notes = info.notesFor(Localizations.maybeLocaleOf(context)?.languageCode ?? 'en');
  return [
    Text(lead, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45)),
    if (notes != null && notes.isNotEmpty) ...[
      const SizedBox(height: 14),
      Text(text.whatsNew, style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 6),
      Text(notes, style: theme.textTheme.bodyMedium?.copyWith(height: 1.45)),
    ],
  ];
}

/// "New version available" with Reload, once [RiviumWebUpdates] finds a newer build. "Later" hides it until an even
/// newer one appears. A required update is [RiviumUpdateGate]'s, not this card's.
///
/// ```dart
/// RiviumUpdatePrompt(icon: Image.asset('assets/icon.png'))
/// ```
class RiviumUpdatePrompt extends StatelessWidget {
  const RiviumUpdatePrompt({
    super.key,
    this.icon,
    this.accentColor,
    this.strings,
    this.margin = const EdgeInsets.all(16),
  });

  final Widget? icon;
  final Color? accentColor;
  final RiviumUpdateStrings? strings;
  final EdgeInsetsGeometry margin;

  /// The version "Later" was pressed for.
  static final _later = ValueNotifier<String?>(null);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RiviumUpdateInfo?>(
      valueListenable: RiviumWebUpdates.available,
      builder: (context, info, _) => ValueListenableBuilder<String?>(
        valueListenable: _later,
        builder: (context, later, _) {
          if (info == null || info.required || later == info.latest) return const SizedBox.shrink();
          final text = _strings(context, strings);
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
              accent: accentColor ?? Theme.of(context).colorScheme.primary,
              icon: icon ?? const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 28),
              title: text.title,
              subtitle: text.version(_shown(info.latest)),
              body: _body(context, text, info, text.body),
              secondary: (text.later, () => _later.value = info.latest),
              primary: (Icons.refresh_rounded, text.reload, RiviumWebUpdates.reload),
            ),
          );
        },
      ),
    );
  }

  @visibleForTesting
  static void resetLater() => _later.value = null;
}

/// Wraps the app: when the running version is below `minimum` of update.json, a blurred screen that cannot be
/// dismissed asks to reload. Otherwise just [child].
///
/// ```dart
/// MaterialApp(builder: (context, child) => RiviumUpdateGate(child: child!))
/// ```
class RiviumUpdateGate extends StatelessWidget {
  const RiviumUpdateGate({super.key, required this.child, this.icon, this.accentColor, this.strings});

  final Widget child;
  final Widget? icon;
  final Color? accentColor;
  final RiviumUpdateStrings? strings;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<RiviumUpdateInfo?>(
      valueListenable: RiviumWebUpdates.available,
      child: child,
      builder: (context, info, child) {
        if (info == null || !info.required) return child!;
        final text = _strings(context, strings);
        return Stack(
          children: [
            child!,
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: ColoredBox(color: Colors.black.withValues(alpha: 0.45)),
              ),
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: LuxuryCard(
                          margin: const EdgeInsets.all(20),
                          accent: accentColor ?? Theme.of(context).colorScheme.primary,
                          icon: icon ?? const Icon(Icons.system_update_rounded, color: Colors.white, size: 28),
                          title: text.requiredTitle,
                          subtitle: text.version(_shown(info.latest)),
                          body: _body(context, text, info, text.requiredBody),
                          primary: (Icons.refresh_rounded, text.reload, RiviumWebUpdates.reload),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
