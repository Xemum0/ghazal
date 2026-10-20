import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;

import '../foundation.dart';
import 'gz_fig_text.dart';
import 'gz_format_scope.dart';
import 'gz_money.dart';

/// card 17/16 500, strong 17/16 600, total 22 600, kpi 32 600, display d1 (serif: sticky bar, plate), hero d3 (serif).
enum GzPriceSize { card, strong, total, kpi, display, hero }

/// The unit that must follow a price (ADR 0010 D9).
enum GzPriceUnit { perGuest, perNight, perDay, perHour }

/// Price: the figures voice around the shared formatter (ADR 0010). The component never builds a price string: it takes integer
/// fils and asks the formatter for the pieces. `[prefix] [currency amount.fils] [unit] [was]`; the currency sits visually before
/// the amount in both languages; the fils size is round(0.8 x amount), minimum 12, always ink-600, never opacity.
class GzPrice extends StatelessWidget {
  const GzPrice({
    required this.fils,
    this.mode = GzMoneyMode.browse,
    this.size = GzPriceSize.card,
    this.unit,
    this.was,
    this.prefix,
    super.key,
  });

  /// Integer fils (ADR 0010 D6). Never a float.
  final int fils;
  final GzMoneyMode mode;
  final GzPriceSize size;
  final GzPriceUnit? unit;

  /// A real previous price (ADR 0018 D4), struck through in caption ink-600.
  final int? was;

  /// Leading text such as "From" (the formatter owns the wording; pass the string).
  final String? prefix;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final (GzTextRole role, GzTextRole fils0) = switch (size) {
      GzPriceSize.card => (GzTextRole.price, GzTextRole.filsPrice),
      GzPriceSize.strong => (GzTextRole.priceStrong, GzTextRole.filsPrice),
      GzPriceSize.total => (GzTextRole.priceTotal, GzTextRole.filsTotal),
      GzPriceSize.kpi => (GzTextRole.kpi, GzTextRole.figXl),
      GzPriceSize.display => (GzTextRole.d1, GzTextRole.figBodyS),
      GzPriceSize.hero => (GzTextRole.d3, GzTextRole.figXl),
    };
    final caption = gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, decoration: TextDecoration.none);
    final unitText = switch (unit) {
      GzPriceUnit.perGuest => l.commonUnitPerGuest,
      GzPriceUnit.perNight => l.commonUnitPerNight,
      GzPriceUnit.perDay => l.commonUnitPerDay,
      GzPriceUnit.perHour => l.commonUnitPerHour,
      null => null,
    };
    String? struck;
    if (was != null) {
      final p = context.gzFormat.moneyParts(was!, MoneyOptions(mode: mode == GzMoneyMode.exact ? MoneyMode.exact : MoneyMode.browse));
      struck = '${p.integer}${p.fraction}';
    }
    const gap = SizedBox(width: GzSpace.s2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      textBaseline: TextBaseline.alphabetic,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      children: [
        if (prefix != null) ...[Text(prefix!, style: caption), gap],
        GzMoney(fils: fils, mode: mode, amountRole: role, filsRole: fils0),
        if (unitText != null) ...[gap, Text(unitText, style: caption)],
        if (struck != null) ...[
          gap,
          ExcludeSemantics(
            child: gzFigText(context, struck, role: GzTextRole.figCaption, color: c.textSecondary, decoration: TextDecoration.lineThrough),
          ),
        ],
      ],
    );
  }
}
