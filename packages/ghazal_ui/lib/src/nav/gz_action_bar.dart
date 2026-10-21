import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_nav_scope.dart';

/// The one primary action of a [GzActionBar].
@immutable
class GzActionBarAction {
  const GzActionBarAction({required this.label, this.onPressed, this.iconEnd, this.loading = false, this.disabled = false, this.reason});

  final String label;
  final VoidCallback? onPressed;
  final IconData? iconEnd;
  final bool loading;
  final bool disabled;

  /// A disabled primary states why (caption under it).
  final String? reason;
}

/// ActionBar (direction section 2.5 and 3): the pinned CTA bar. Canvas with a 1 dp ink-200 top rule, never ink. Anatomy 12 + 52 + 12 +
/// safe: an optional summary at inline-start (label over value, e.g. a price), the ONE primary button filling the rest, and an optional
/// note under the row. When a tab bar sits below ([GzBottomChrome.tabBar]) the bar adds no home-indicator inset; when it is the
/// bottom-most thing (venue details) it adds the inset. It reports its height to the [GzBarInsetRegistry] so toasts float above it.
class GzActionBar extends StatefulWidget {
  const GzActionBar({
    required this.action,
    this.summaryLabel,
    this.summaryValue,
    this.secondary,
    this.note,
    this.noteWidget,
    this.safeBottom,
    super.key,
  });

  /// Caption above the value ("From", "Total for 350 guests").
  final String? summaryLabel;

  /// The value (a `GzPrice` or other node). Rendered as given: the bar never formats money.
  final Widget? summaryValue;
  final GzActionBarAction action;

  /// A second, equal-weight action beside the primary (the pair is equal width, ADR 0014 D7: primary at inline-end).
  final GzActionBarAction? secondary;

  /// Caption under the row.
  final String? note;

  /// The same slot as a widget (the web `note` is a ReactNode): a quiet link or two text buttons under the primary. It takes the caption
  /// type and the secondary ink as its default text style and the full width of the bar (centre or align it yourself); wins over [note].
  final Widget? noteWidget;

  /// Gallery only: force the bottom inset on or off. Default follows what is below (tab bar or not).
  final bool? safeBottom;

  @override
  State<GzActionBar> createState() => _GzActionBarState();
}

class _GzActionBarState extends State<GzActionBar> {
  final Object _key = Object();
  GzBarInsetRegistry? _registry;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = GzBarInsets.maybeOf(context);
    if (next != _registry) {
      _registry?.clear(_key);
      _registry = next;
    }
  }

  @override
  void dispose() {
    final registry = _registry;
    if (registry != null) WidgetsBinding.instance.addPostFrameCallback((_) => registry.clear(_key));
    super.dispose();
  }

  void _measure() {
    final box = context.findRenderObject();
    if (box is RenderBox && box.hasSize) _registry?.report(_key, box.size.height);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final w = widget;
    final inset = w.safeBottom ?? !GzBottomChrome.tabBarOf(context);
    final bottom = inset ? MediaQuery.paddingOf(context).bottom : 0.0;
    final hasSummary = w.summaryLabel != null || w.summaryValue != null;

    Widget primary(GzActionBarAction a) => GzButton(
          label: a.label,
          onPressed: a.disabled ? null : a.onPressed,
          iconEnd: a.iconEnd,
          loading: a.loading,
          reason: a.reason,
          fullWidth: true,
        );

    final buttons = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (w.secondary != null) ...[
          Expanded(
            child: GzButton(
              label: w.secondary!.label,
              onPressed: w.secondary!.onPressed,
              variant: GzButtonVariant.secondary,
              size: GzButtonSize.cta,
              fullWidth: true,
            ),
          ),
          const SizedBox(width: GzSpace.s3),
        ],
        Expanded(child: primary(w.action)),
      ],
    );

    final row = Row(
      children: [
        if (hasSummary) ...[
          Column(
            key: const ValueKey('gz:actionbar.summary'),
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (w.summaryLabel != null) GzText(w.summaryLabel!, role: GzTextRole.caption, color: c.textSecondary),
              if (w.summaryValue != null) w.summaryValue!,
            ],
          ),
          const SizedBox(width: GzSpace.s4),
        ],
        Expanded(child: buttons),
      ],
    );

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _measure();
        });
        return false;
      },
      child: SizeChangedLayoutNotifier(
        child: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _measure();
            });
            return ColoredBox(
              color: c.surfaceCanvas,
              child: Stack(
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: bottom),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          row,
                          if (w.noteWidget != null) ...[
                            const SizedBox(height: GzSpace.s2),
                            DefaultTextStyle.merge(style: context.gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, decoration: TextDecoration.none), child: w.noteWidget!),
                          ] else if (w.note != null) ...[
                            const SizedBox(height: GzSpace.s2),
                            GzText(w.note!, role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.start),
                          ],
                        ],
                      ),
                    ),
                  ),
                  PositionedDirectional(start: 0, end: 0, top: 0, height: GzStroke.hair, child: ColoredBox(color: c.borderHairline)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
