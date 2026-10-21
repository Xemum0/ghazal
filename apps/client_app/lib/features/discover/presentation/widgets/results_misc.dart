import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// The Map pill that floats above the list (the tray pill look: a raised capsule, a glyph and one word).
class MapPill extends StatelessWidget {
  const MapPill({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final label = context.l10n.clientDiscoverResultsMap;
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.pillAll,
      builder: (context, st) => DecoratedBox(
        key: const ValueKey<String>('discover.map.toggle'),
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.pillAll, boxShadow: GzElevation.e2),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.touchMin),
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(GzIcons.map, size: GzIconSize.sm, color: c.iconPrimary),
                const SizedBox(width: GzSpace.s2),
                Text(label, style: gz.text(GzTextRole.button).copyWith(color: c.textStrong, decoration: TextDecoration.none)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An info glyph that opens a small sheet with a title and one rule (the web `InfoButton`; a system component is requested).
class InfoSheetButton extends StatelessWidget {
  const InfoSheetButton({required this.title, required this.text, super.key});

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final nav = context.gzNav;
    return GzIconButton(
      key: const ValueKey<String>('discover.info'),
      icon: GzIcons.info,
      label: title,
      onPressed: () => nav.openSheetBuilder(
        (ctx) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSheetHeader(title: title, onClose: nav.closeSheet),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
              child: GzText(text, role: GzTextRole.body, color: ctx.gz.colors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Results while they load: two static 16:10 blocks with text lines, nothing shimmers.
class ResultsSkeleton extends StatelessWidget {
  const ResultsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width - 2 * GzSpace.gutter;
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: ExcludeSemantics(
        child: Padding(
          key: const ValueKey<String>('discover.results.loading'),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 2; i++) ...[
                if (i > 0) const SizedBox(height: GzSpace.s6),
                GzSkeleton(variant: GzSkeletonVariant.block, blockSize: w * 10 / 16),
                const SizedBox(height: GzSpace.s3),
                const GzSkeleton(inlineSize: 220, blockSize: 28),
                const SizedBox(height: GzSpace.s2),
                const GzSkeleton(inlineSize: 160, blockSize: 20),
                const SizedBox(height: GzSpace.s2),
                const GzSkeleton(inlineSize: 200, blockSize: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
