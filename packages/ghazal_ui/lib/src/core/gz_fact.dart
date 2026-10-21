import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_fig_text.dart';
import 'gz_format_scope.dart';
import 'gz_glyph_baseline.dart';

enum GzFactLayout { stack, inline }

/// KeyFact: icon + label + value, the venue facts row (guests, session, capacity, area). `stack` puts the label above the value
/// (caption over title); `inline` runs them on one line. Give [value] a string, or [valueWidget] (a price) for a composed value.
class GzKeyFact extends StatelessWidget {
  const GzKeyFact({required this.icon, required this.label, this.value, this.valueWidget, this.layout = GzFactLayout.stack, super.key})
      : assert(value != null || valueWidget != null, 'GzKeyFact needs a value or a valueWidget');

  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;
  final GzFactLayout layout;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final labelW = GzText(label, role: GzTextRole.caption, color: c.textSecondary);
    final valueW = valueWidget ?? GzText(value!, role: GzTextRole.title, color: c.textStrong, figures: true);
    final text = layout == GzFactLayout.stack
        ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [labelW, valueW])
        : Row(
            mainAxisSize: MainAxisSize.min,
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [labelW, const SizedBox(width: GzSpace.s2), Flexible(child: valueW)],
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary),
        const SizedBox(width: GzSpace.s3),
        Flexible(child: text),
      ],
    );
  }
}

/// Tag: a quiet, non-interactive label with an icon (amenities, hall features). 32 high, so never a target.
class GzTag extends StatelessWidget {
  const GzTag({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.disk),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.smAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[GzIcon(icon!, size: GzIconSize.xs, color: c.iconSecondary), const SizedBox(width: GzSpace.s2)],
          GzText(label, role: GzTextRole.caption, color: c.textPrimary, softWrap: false),
        ],
      ),
    );
  }
}

enum GzFactTone { normal, accent, muted }

final RegExp _arabicLetters = RegExp('[؀-ۿ]');

/// FactChip (ADR 0034, docs/design/02-text-diet.md section 2): a fact is an icon and a value, no label. The [label] moves into
/// the accessible name ("Guests 350" for a screen reader, `[users] 350` on screen). A value may be a formatter string (its digits
/// become figure islands) or a [valueWidget]. A [unit] is quiet and follows the value. Not a control: no target size.
/// A pure figure, code or phone is an LTR isolate; a string that mixes figures and Arabic words takes the language direction.
class GzFactChip extends StatelessWidget {
  const GzFactChip({required this.icon, required this.label, this.value, this.valueWidget, this.unit, this.tone = GzFactTone.normal, this.small = false, super.key});

  final IconData icon;

  /// What the fact is (guests, area, session ...). Read by assistive technology, not shown.
  final String label;
  final String? value;
  final Widget? valueWidget;

  /// A quiet unit after the value.
  final String? unit;

  /// `accent` = gold-700 glyph (ratings, held), `muted` = secondary value (a fact that is background).
  final GzFactTone tone;

  /// `false` = 16 value (rows, cards); `true` = 13 caption (dense lists).
  final bool small;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final role = small ? GzTextRole.figCaption : GzTextRole.figBodyS;
    final color = tone == GzFactTone.muted ? c.textSecondary : c.textStrong;
    Widget? v;
    if (valueWidget != null) {
      v = valueWidget;
    } else if (value != null && value!.isNotEmpty) {
      final words = _arabicLetters.hasMatch(GzBidi.strip(value!));
      final t = GzText(value!, role: role, color: color, figures: true, softWrap: false);
      v = words ? t : Directionality(textDirection: TextDirection.ltr, child: t);
    }
    return Semantics(
      label: [label, if (value != null) GzBidi.strip(value!), ?unit].join(' '),
      excludeSemantics: valueWidget == null,
      // The first flex item is the glyph, so the web baseline of a chip is the bottom edge of its icon.
      child: GzGlyphBaseline(
        glyphSize: small ? GzSize.iconXs : GzSize.iconSm,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GzIcon(icon, size: small ? GzIconSize.xs : GzIconSize.sm, color: tone == GzFactTone.accent ? c.iconAccent : c.iconSecondary),
            if (v != null) ...[const SizedBox(width: GzSpace.s1), v],
            if (unit != null) ...[const SizedBox(width: GzSpace.s1), GzText(unit!, role: GzTextRole.caption, color: c.textSecondary)],
          ],
        ),
      ),
    );
  }
}

/// Two to five facts on one line. Order is always: guests, area, session, rating, price. Unknown facts are omitted, never dashed.
/// [scroll] keeps one line and scrolls sideways (a rail of facts); the default wraps only when the width runs out.
class GzFactRow extends StatelessWidget {
  const GzFactRow({required this.children, this.label, this.scroll = false, super.key});

  final List<Widget> children;

  /// Names the group for assistive technology ("Details").
  final String? label;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final Widget body = scroll
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s4), children[i]],
              ],
            ),
          )
        : Wrap(spacing: GzSpace.s4, runSpacing: GzSpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: children);
    return Semantics(container: true, label: label, child: body);
  }
}

/// IconStat (ADR 0034): a big number with its icon, the KPI and summary primitive that replaces a caption over a number.
/// `stack` puts the glyph in a quiet disk over the figure (tiles); `inline` puts glyph and figure on one line (headers, rows).
/// The [label] is the accessible name, not shown. [delta] is a trend glyph and a signed percent (the glyph never mirrors).
class GzIconStat extends StatelessWidget {
  const GzIconStat({required this.icon, required this.value, required this.label, this.unit, this.delta, this.layout = GzFactLayout.stack, this.accent = false, super.key});

  final IconData icon;

  /// The figure: a formatter string.
  final String value;
  final String label;

  /// A quiet unit after the figure (`h`, `m²`).
  final String? unit;

  /// Change against the previous period, in percent points (12 = +12%).
  final num? delta;
  final GzFactLayout layout;

  /// Gold-700 glyph.
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final stack = layout == GzFactLayout.stack;
    final disk = stack ? GzSize.avatarSm : GzSize.disk;
    final glyph = Container(
      width: disk,
      height: disk,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
      child: GzIcon(icon, size: stack ? GzIconSize.md : GzIconSize.sm, color: accent ? c.iconAccent : c.iconPrimary),
    );
    final figure = gzFigText(context, value, role: GzTextRole.kpi, color: c.textStrong);
    final unitW = unit == null ? null : GzText(unit!, role: GzTextRole.caption, color: c.textSecondary);
    Widget? deltaW;
    if (delta != null) {
      final d = delta!;
      final f = context.gzFormat;
      final pct = f.percent(d.abs(), maxFraction: 1);
      final signed = d == 0 ? pct : '${d > 0 ? '+' : '−'}$pct';
      final color = d > 0 ? c.textSuccess : (d < 0 ? c.textDanger : c.textSecondary);
      deltaW = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(d > 0 ? GzIcons.trendUp : (d < 0 ? GzIcons.trendDown : GzIcons.minus), size: GzIconSize.xs, color: color, mirror: false),
          const SizedBox(width: GzSpace.s1),
          gzFigText(context, signed, role: GzTextRole.figCaption, color: color),
        ],
      );
    }
    final parts = <Widget>[glyph, figure, ?unitW, ?deltaW];
    return Semantics(
      label: '$label ${GzBidi.strip(value)}',
      excludeSemantics: true,
      child: stack
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              for (var i = 0; i < parts.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s2), parts[i]],
            ])
          : Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
              for (var i = 0; i < parts.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s2), parts[i]],
            ]),
    );
  }
}
