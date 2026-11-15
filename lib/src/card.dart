import 'package:flutter/material.dart';

// Building blocks shared by the install guide and the update prompt (not exported).

/// Mixes [c] toward black (amount > 0) or white (amount < 0).
Color shade(Color c, double amount) {
  final target = amount > 0 ? Colors.black : Colors.white;
  return Color.lerp(c, target, amount.abs())!;
}

/// The premium card of rivium_web: a brand-gradient header (icon with a glow, title, subtitle, feature pills), a body,
/// and a quiet secondary action next to a gradient primary one.
class LuxuryCard extends StatelessWidget {
  const LuxuryCard({
    super.key,
    required this.margin,
    required this.accent,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.features = const [],
    this.body = const [],
    this.secondary,
    this.primary,
  });

  final EdgeInsetsGeometry margin;
  final Color accent;
  final Widget? icon;
  final String title;
  final String subtitle;
  final List<(IconData, String)> features;
  final List<Widget> body;
  final (String, VoidCallback)? secondary;
  final (IconData, String, VoidCallback)? primary;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final deep = shade(accent, 0.55);
    final light = shade(accent, -0.18);
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
                        AppIconBox(icon: icon, glow: light),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title,
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
                        children: [for (final (i, label) in features) FeaturePill(icon: i, label: label)],
                      ),
                    ],
                  ],
                ),
              ),
              ColoredBox(
                color: scheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ...body,
                      if (body.isNotEmpty) const SizedBox(height: 10),
                      Row(
                        children: [
                          if (secondary != null)
                            TextButton(
                              onPressed: secondary!.$2,
                              style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                              child: Text(secondary!.$1),
                            ),
                          const Spacer(),
                          if (primary != null)
                            GradientButton(
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

class AppIconBox extends StatelessWidget {
  const AppIconBox({
    super.key,required this.icon, required this.glow});
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

class FeaturePill extends StatelessWidget {
  const FeaturePill({
    super.key,required this.icon, required this.label});
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

class StepRow extends StatelessWidget {
  const StepRow({
    super.key,
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

class GradientButton extends StatelessWidget {
  const GradientButton({
    super.key,required this.icon, required this.label, required this.onPressed, required this.colors});
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
