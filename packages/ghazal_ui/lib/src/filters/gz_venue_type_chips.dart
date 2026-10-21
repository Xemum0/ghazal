import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/inputs.dart';

/// The venue types of the filter (web `VenueTypeValue`): a private hall, a governmental facility, a hotel.
enum GzVenueType { privateHall, governmental, hotel }

/// VenueTypeChips (CL-DISC filters, CA-FLT venue type): Private hall, Governmental facility, Hotel. Multi-select chips (a couple may
/// want a hall or a hotel), each with its glyph so the type reads at a glance. A governmental facility is browse-only (no voucher, no
/// visit), which the chip does not say: the card and the detail do. [layout] is `wrap` (a filter sheet) or `rail` (a results
/// header row). The anatomy is the [GzChip] one (44 high, radius 8, hairline; selected = ink border, gold bead, weight 500); the
/// group draws its own body because a [GzChip] label cannot carry the glyph inside the label. Arrow keys rove like [GzChipGroup].
class GzVenueTypeChips extends StatefulWidget {
  const GzVenueTypeChips({this.values, this.defaultValues, this.onChanged, this.layout = GzChipLayout.wrap, super.key});

  final List<GzVenueType>? values;
  final List<GzVenueType>? defaultValues;
  final ValueChanged<List<GzVenueType>>? onChanged;
  final GzChipLayout layout;

  @override
  State<GzVenueTypeChips> createState() => _GzVenueTypeChipsState();
}

class _GzVenueTypeChipsState extends State<GzVenueTypeChips> {
  final GzFocusNodes _focus = GzFocusNodes();
  late List<GzVenueType> _inner = List.of(widget.defaultValues ?? const []);

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _toggle(GzVenueType v) {
    final cur = widget.values ?? _inner;
    final next = cur.contains(v) ? [for (final x in cur) if (x != v) x] : [...cur, v];
    if (widget.values == null) setState(() => _inner = next);
    widget.onChanged?.call(next);
  }

  static (IconData, String) _meta(GzL10n l, GzVenueType v) => switch (v) {
    GzVenueType.privateHall => (GzIcons.hall, l.commonVenueTypePrivateHall),
    GzVenueType.governmental => (GzIcons.bank, l.commonVenueTypeGovernmental),
    GzVenueType.hotel => (GzIcons.hotel, l.commonVenueTypeHotel),
  };

  @override
  Widget build(BuildContext context) {
    final l = context.gzL10n;
    final rtl = context.gz.isRtl;
    final selected = widget.values ?? _inner;
    const none = [false, false, false];
    final chips = <Widget>[
      for (var i = 0; i < GzVenueType.values.length; i++)
        Focus(
          focusNode: _focus[i],
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, e) {
            final next = gzRovingIndex(e, i, none, rtl: rtl);
            if (next == null) return KeyEventResult.ignored;
            _focus[next].traversalDescendants.firstOrNull?.requestFocus();
            return KeyEventResult.handled;
          },
          child: _TypeChip(
            icon: _meta(l, GzVenueType.values[i]).$1,
            label: _meta(l, GzVenueType.values[i]).$2,
            selected: selected.contains(GzVenueType.values[i]),
            onPressed: () => _toggle(GzVenueType.values[i]),
          ),
        ),
    ];
    final body = widget.layout == GzChipLayout.rail
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < chips.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), chips[i]],
              ],
            ),
          )
        : Wrap(spacing: GzSpace.s2, runSpacing: GzSpace.s2, children: chips);
    return Semantics(container: true, label: l.commonFilterVenueType, child: body);
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.icon, required this.label, required this.selected, required this.onPressed});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      selected: selected,
      borderRadius: GzRadius.smAll,
      scale: 1,
      builder: (context, st) {
        final gz = context.gz;
        final c = gz.colors;
        final border = selected ? c.controlChipBorderSelected : c.controlChipBorder;
        final fg = selected ? c.textStrong : c.textPrimary;
        final bg = selected ? c.controlBg : (st.pressed ? c.surfaceQuiet : null);
        final base = gzResetLabelStyle(gz);
        final heavy = gz.text(GzTextRole.title).fontWeight;
        Widget content(TextStyle style) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(icon, size: GzIconSize.xs, color: style.color ?? fg),
            Text(label, style: style, softWrap: false),
          ],
        );
        final body = Stack(
          alignment: Alignment.center,
          children: [
            // The hidden 500 copy reserves the width of the selected label.
            Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true, child: content(base.copyWith(fontWeight: heavy))),
            AnimatedDefaultTextStyle(
              duration: GzMotion.durationBase,
              curve: GzMotion.easeStandard,
              style: base.copyWith(color: fg, fontWeight: selected ? heavy : base.fontWeight, decoration: TextDecoration.none),
              child: content(base.copyWith(color: fg, fontWeight: selected ? heavy : base.fontWeight, decoration: TextDecoration.none)),
            ),
          ],
        );
        return AnimatedContainer(
          duration: GzMotion.durationBase,
          curve: GzMotion.easeStandard,
          constraints: const BoxConstraints(minHeight: GzSize.controlSm),
          padding: EdgeInsetsDirectional.only(start: selected ? GzSpace.s3 : GzSpace.s4, end: GzSpace.s4),
          decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll, border: Border.all(color: border, width: GzStroke.hair)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[const GzBeadBox(), const SizedBox(width: GzSpace.s2)],
              body,
            ],
          ),
        );
      },
    );
  }
}
