/// The wire form of money: integer fils plus a currency (ADR 0010), exactly `{ "fils": 18200000, "currency": "KWD" }`.
///
/// This is a transport value. Formatting and display arithmetic belong to `Money` and `GzFormat` in `ghazal_core` (a Flutter package, so this
/// pure-Dart package cannot depend on it); the type is named `MoneyAmount` so that screens can import both without a name clash.
/// `ghazal_api` offers the one-line conversion once `ghazal_core` exports its `Money`.
final class MoneyAmount implements Comparable<MoneyAmount> {
  const MoneyAmount(this.fils, [this.currency = 'KWD']);

  factory MoneyAmount.fromJson(Map<String, Object?> json) {
    final fils = json['fils'];
    if (fils is! num || fils != fils.truncate()) throw FormatException('money.fils must be an integer, got $fils');
    final currency = json['currency'];
    return MoneyAmount(fils.toInt(), currency is String ? currency : 'KWD');
  }

  static const MoneyAmount zero = MoneyAmount(0);

  /// Integer minor units (fils for KWD; 1 KD = 1000 fils).
  final int fils;
  final String currency;

  Map<String, Object?> toJson() => {'fils': fils, 'currency': currency};

  bool get isZero => fils == 0;
  bool get isNegative => fils < 0;

  MoneyAmount operator +(MoneyAmount o) => MoneyAmount(fils + _same(o).fils, currency);
  MoneyAmount operator -(MoneyAmount o) => MoneyAmount(fils - _same(o).fils, currency);
  MoneyAmount operator *(int quantity) => MoneyAmount(fils * quantity, currency);
  bool operator <(MoneyAmount o) => compareTo(o) < 0;
  bool operator >(MoneyAmount o) => compareTo(o) > 0;
  bool operator <=(MoneyAmount o) => compareTo(o) <= 0;
  bool operator >=(MoneyAmount o) => compareTo(o) >= 0;

  MoneyAmount _same(MoneyAmount o) => o.currency == currency ? o : throw ArgumentError('currency mismatch: $currency and ${o.currency}');

  @override
  int compareTo(MoneyAmount other) => fils.compareTo(_same(other).fils);

  @override
  bool operator ==(Object other) => other is MoneyAmount && other.fils == fils && other.currency == currency;

  @override
  int get hashCode => Object.hash(fils, currency);

  @override
  String toString() => 'MoneyAmount($fils $currency)';
}
