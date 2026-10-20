import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

/// The wire money of the contract (`MoneyAmount`, pure Dart in `ghazal_domain`) and the display money of `ghazal_core` (`Money`, formatted only
/// by `GzFormat`). Same value, two types: the domain package cannot depend on the Flutter core package, so this is the bridge.
extension MoneyAmountToMoney on MoneyAmount {
  Money toMoney() => Money(fils, CurrencyCode.fromCode(currency));
}

extension MoneyToMoneyAmount on Money {
  MoneyAmount toAmount() => MoneyAmount(fils, currency.code);
}
