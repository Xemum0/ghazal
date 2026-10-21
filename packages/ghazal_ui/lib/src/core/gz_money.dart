import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyMode, MoneyOptions, MoneyParts;

import '../foundation.dart';
import 'gz_chrome_baseline.dart';
import 'gz_format_scope.dart';

/// `browse`: integer dinars when the fils are zero, else three decimals (cards, shelves, compare cells, KPIs).
/// `exact`: always three decimals; a trailing `.000` is set quiet (ink-600, 0.8 x size, minimum 12).
enum GzMoneyMode { browse, exact }

MoneyMode _core(GzMoneyMode m) => m == GzMoneyMode.exact ? MoneyMode.exact : MoneyMode.browse;

/// Money: the one shared money part (ADR 0010 D7). Integer fils in, the formatter's parts out: [currency][amount.fils] as one
/// LTR island, so the figure is isolated and the Arabic currency reads after it (`12 د.ك` is drawn `د.ك 12`): the currency sits
/// visually before (left of) the figure in BOTH languages. Price, compare cells, card price lines and struck standard prices all
/// render through this part, so the currency can never land on a different side in two places.
///
/// [amountRole] is the type role of the figure (`price`, `figCaption`, ...); [filsRole] the role of the quiet `.000`.
/// [inline] makes the currency take the surrounding size and ink (struck prices, chips, facts) instead of the label voice.
class GzMoney extends StatelessWidget {
  const GzMoney({
    required this.fils,
    this.mode = GzMoneyMode.browse,
    this.amountRole = GzTextRole.price,
    this.filsRole = GzTextRole.filsPrice,
    this.amountColor,
    this.amountStyle,
    this.inline = false,
    super.key,
  });

  /// Integer fils (ADR 0010 D6). Never a float.
  final int fils;
  final GzMoneyMode mode;
  final GzTextRole amountRole;
  final GzTextRole filsRole;
  final Color? amountColor;

  /// Replaces the style of [amountRole] (the display and hero voices of Price use the serif roles).
  final TextStyle? amountStyle;
  final bool inline;

  /// The web `.gz-money__fils` sets a face and a size but no line height, so the quiet fils inherit the page line (body: 24 in English, 28 in
  /// Arabic): its box is taller than the figure's own role line, and the baseline row of figure and fils grows with it (the exact price is 25
  /// and 28 high on the web, 24 and 26 with the fils role's own 16 line).
  TextStyle _filsStyle(GzThemeData gz, GzColors c) {
    final fils = gz.text(filsRole);
    final body = gz.text(GzTextRole.body);
    final line = (body.height ?? 1) * (body.fontSize ?? 16);
    return fils.copyWith(
      fontWeight: (amountStyle ?? gz.text(amountRole)).fontWeight,
      color: c.textSecondary,
      decoration: TextDecoration.none,
      height: line / (fils.fontSize ?? 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final MoneyParts parts = context.gzFormat.moneyParts(fils, MoneyOptions(mode: _core(mode)));
    final quiet = mode == GzMoneyMode.exact && parts.fractionIsZero;
    final amount = (amountStyle ?? gz.text(amountRole)).copyWith(color: amountColor ?? c.textStrong, decoration: TextDecoration.none);
    final amountText = '${parts.negative ? '−' : ''}${parts.integer}${quiet ? '' : parts.fraction}';
    final TextStyle currency = inline
        ? amount.copyWith(color: amountColor ?? c.textStrong)
        : gz.text(GzTextRole.label).copyWith(color: c.textSecondary, decoration: TextDecoration.none);
    final filsStyle = _filsStyle(gz, c);
    final cur = inline || gz.isAr ? parts.currency : parts.currency.toUpperCase();
    return Semantics(
      label: GzBidi.strip(parts.text),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          children: [
            // Each text keeps the browser's whole-pixel baseline, so the baseline row is a whole number of dp high like the web line box.
            GzChromeBaseline(style: currency, child: Text(cur, style: currency, softWrap: false)),
            SizedBox(width: inline ? GzSpace.s1 : GzSpace.s1),
            GzChromeBaseline(style: amount, child: Text(amountText, style: amount, softWrap: false)),
            if (quiet) GzChromeBaseline(style: filsStyle, child: Text(parts.fraction, style: filsStyle, softWrap: false)),
          ],
        ),
      ),
    );
  }
}
