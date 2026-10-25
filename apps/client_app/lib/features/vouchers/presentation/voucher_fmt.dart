import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The text of a bilingual value in the language of the screen (web `useBi`).
String voucherText(BuildContext context, LocalizedText? t) => t == null ? '' : t.of(context.gz.locale.languageCode);

/// The short figures of the voucher screens, all from the shared formatter (web `useVc`): `KD 2`, `KD 2.000`, `14 Jan`, `13 Nov 12:40 PM`.
extension VoucherFmt on GzFormat {
  /// Whole dinars, three decimals only when the fils are not zero.
  String moneyBrowse(int fils) => money(fils, const MoneyOptions());

  /// The exact amount (a receipt, the fee on the pay screen).
  String moneyExact(int fils) => money(fils, const MoneyOptions(mode: MoneyMode.exact));

  /// `14 Jan`.
  String dayMon(Object d) {
    final c = civil(d);
    return '${integer(c.day)} ${monthName(c.month, short: true)}';
  }

  /// `Thu 14 Jan 2027`: the date a voucher is bound to.
  String dayLong(Object d) => date(d, DateStyle.short);

  /// `13 Nov 12:40 PM`: an absolute deadline as a figure.
  String stamp(Object d) => '${dayMon(d)} ${time(d).replaceAll(RegExp(r'\s'), ' ')}';
}

/// An amount as the value of a fact chip, one LTR island: the currency before the figure in English, after it in Arabic.
Widget voucherMoneyValue(BuildContext context, GzFormat f, int fils, {bool exact = false, bool small = false, bool muted = false}) {
  final parts = f.moneyParts(fils, MoneyOptions(mode: exact ? MoneyMode.exact : MoneyMode.browse));
  final amount = '${parts.integer}${parts.fraction}';
  final text = context.gz.isAr ? '$amount ${parts.currency}' : GzBidi.strip(parts.text);
  return Directionality(
    textDirection: TextDirection.ltr,
    child: GzText(
      text,
      role: small ? GzTextRole.figCaption : GzTextRole.figBodyS,
      color: muted ? context.gz.colors.textSecondary : context.gz.colors.textStrong,
      figures: true,
      softWrap: false,
    ),
  );
}
