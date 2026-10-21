import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions;

import '../foundation.dart';
import 'gz_chrome_baseline.dart';
import 'gz_format_scope.dart';
import 'gz_money.dart';

/// A standard price, quiet and struck through (web `<Money inline className="gz-t-fig-* gz-strike">` and the plain
/// `<bdi dir="ltr">{f.money(...)}</bdi>` of the booking Review): currency and figure in one ink (secondary), a 1 dp line through
/// both, one LTR island. The shared [GzPrice] strikes only the figure.
///
/// [mode] is the money mode: [GzMoneyMode.exact] prints all three decimals (`18,200.000`, the Review's full precision), `browse` drops a
/// zero fraction. In English the currency comes before the figure. In Arabic it follows the web part you copy: the `Money` part draws the
/// currency first in both languages (the default), the plain formatter text of the Review draws the figure first and the currency after
/// it (figure `18,200.000`, then `د.ك`): pass [arabicFigureFirst] for that one. [semanticLabel] replaces the spoken price (the Review says "Standard
/// price"). A struck price is never an action: it carries no target.
class GzStruckMoney extends StatelessWidget {
  const GzStruckMoney({
    required this.fils,
    this.role = GzTextRole.figBodyS,
    this.mode = GzMoneyMode.browse,
    this.arabicFigureFirst = false,
    this.semanticLabel,
    super.key,
  });

  /// Integer fils (ADR 0010 D6).
  final int fils;
  final GzTextRole role;
  final GzMoneyMode mode;
  final bool arabicFigureFirst;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final parts = context.gzFormat.moneyParts(fils, MoneyOptions(mode: mode == GzMoneyMode.exact ? MoneyMode.exact : MoneyMode.browse));
    final style = gz.text(role).copyWith(color: c.textSecondary, decoration: TextDecoration.lineThrough, decorationColor: c.textSecondary, decorationThickness: 1);
    const gap = ' ';
    final amount = '${parts.integer}${parts.fraction}';
    final figureFirst = arabicFigureFirst && gz.isAr;
    final currency = gzSnappedText(parts.currency, style: style, softWrap: false);
    final figure = gzSnappedText(amount, style: style, softWrap: false);
    return Semantics(
      label: semanticLabel ?? GzBidi.strip(parts.text),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: figureFirst ? [figure, gzSnappedText(gap, style: style), currency] : [currency, gzSnappedText(gap, style: style), figure],
        ),
      ),
    );
  }
}
