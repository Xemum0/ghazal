// The pieces of the analytics screen (web `MetricTile.tsx`, `AnalyticsSheets.tsx`): a selectable metric tile, the legend sheet and the custom-range
// sheet. A tile is a glyph in a quiet disk, the figure and the change against the previous period: no caption, the name is the accessible name.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

enum Dir { up, down, flat }

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.icon,
    required this.label,
    required this.figure,
    this.deltaText,
    this.dir = Dir.flat,
    this.spoken,
    this.sub,
    this.selected = false,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final String figure;
  final String? deltaText;
  final Dir dir;
  final String? spoken;
  final Widget? sub;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final deltaColor = switch (dir) {
      Dir.up => c.textSuccess,
      Dir.down => c.textDanger,
      Dir.flat => c.textSecondary,
    };
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $figure${spoken != null ? ' $spoken' : ''}',
      excludeSemantics: true,
      // A plain detector, not GzPressable: its centring box would keep a tile at its own height inside an equal-height row.
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsetsDirectional.all(GzSpace.s3),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: selected ? c.textStrong : c.borderStrong, width: GzStroke.hair),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: GzSize.disk,
                    height: GzSize.disk,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(color: selected ? c.actionSelectedBg : c.surfaceTintSoft, shape: BoxShape.circle),
                    child: GzIcon(icon, size: GzIconSize.sm, color: selected ? c.iconOnDark : c.iconPrimary),
                  ),
                  const SizedBox(height: GzSpace.s2),
                  GzText(figure, role: GzTextRole.figXl, color: c.textStrong, figures: true),
                  if (sub != null) ...[const SizedBox(height: GzSpace.s2), sub!],
                  if (deltaText != null) ...[
                    const SizedBox(height: GzSpace.s2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzIcon(
                          dir == Dir.up ? GzIcons.trendUp : (dir == Dir.down ? GzIcons.trendDown : GzIcons.minus),
                          size: GzIconSize.xs,
                          color: deltaColor,
                        ),
                        const SizedBox(width: GzSpace.s1),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: GzText(deltaText!, role: GzTextRole.caption, color: deltaColor, figures: true),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              if (selected)
                PositionedDirectional(
                  top: 0,
                  end: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: c.markState, shape: BoxShape.circle),
                    child: const SizedBox(width: GzSize.knotBead, height: GzSize.knotBead),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef LegendRow = ({IconData icon, String name});

/// How we count: a glyph and a name per figure, then the definitions.
class DefinitionsSheet extends StatelessWidget {
  const DefinitionsSheet({required this.rows, super.key});

  final List<LegendRow> rows;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final defs = [l.hotelGrowAnDefViews(30), l.hotelGrowAnDefClicks, l.hotelGrowAnDefVouchers, l.hotelGrowAnDefConversion(30)];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        Wrap(
          spacing: GzSpace.s4,
          runSpacing: GzSpace.s3,
          children: [
            for (final r in rows)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GzIcon(r.icon, size: GzIconSize.sm, color: c.iconPrimary),
                  const SizedBox(width: GzSpace.s2),
                  GzText(r.name, role: GzTextRole.bodyS, color: c.textStrong),
                ],
              ),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        for (final d in defs)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: GzText(d, role: GzTextRole.bodyS, color: c.textPrimary, figures: true),
          ),
        GzButton(label: l.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: GzNavigatorScope.of(context).closeSheet),
      ],
    );
  }
}

/// A custom period: a range calendar and Apply.
class RangeSheet extends StatefulWidget {
  const RangeSheet({required this.initial, required this.today, required this.minDate, required this.onApply, super.key});

  final GzDateRange initial;
  final String today;
  final String? minDate;
  final ValueChanged<GzDateRange> onApply;

  @override
  State<RangeSheet> createState() => _RangeSheetState();
}

class _RangeSheetState extends State<RangeSheet> {
  late GzDateRange _r = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final ready = _r.start != null && _r.end != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzCalendar.range(
          value: _r,
          onChanged: (v) => setState(() => _r = v),
          today: widget.today,
          minDate: widget.minDate,
          maxDate: widget.today,
          legend: false,
          summary: true,
          label: l.hotelGrowAnCustomTitle,
        ),
        const SizedBox(height: GzSpace.s3),
        GzButton(
          label: l.commonActionApply,
          fullWidth: true,
          onPressed: !ready
              ? null
              : () {
                  widget.onApply(_r);
                  nav.closeSheet();
                },
        ),
      ],
    );
  }
}
