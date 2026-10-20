import 'package:equatable/equatable.dart';

import '../format/config.dart';

/// Money is integer minor units (`fils` for KWD) plus a currency (ADR 0010, ADR 0004 D6). Floats never enter.
/// Formatting is done only by `GzFormat`; this class carries the value and does exact arithmetic.
class Money extends Equatable implements Comparable<Money> {
  const Money(this.fils, [this.currency = CurrencyCode.kwd]);

  const Money.kwd(int fils) : this(fils, CurrencyCode.kwd);

  static const Money zero = Money(0);

  /// Whole major units (dinars): `Money.major(2)` is 2,000 fils.
  factory Money.major(int units, [CurrencyCode currency = CurrencyCode.kwd]) => Money(units * currency.unit, currency);

  /// Parses `{"fils": 2000, "currency": "KWD"}`; also accepts `amount_fils` / `amountFils`. A non-integer is rejected.
  factory Money.fromJson(Map<String, Object?> json) {
    final raw = json['fils'] ?? json['amountFils'] ?? json['amount_fils'] ?? json['minor'];
    if (raw is! num || raw != raw.truncate()) {
      throw FormatException('money must be an integer number of minor units, got $raw');
    }
    final cur = json['currency'];
    return Money(raw.toInt(), cur is String ? CurrencyCode.fromCode(cur) : CurrencyCode.kwd);
  }

  /// Integer minor units: fils for KWD.
  final int fils;
  final CurrencyCode currency;

  Map<String, Object?> toJson() => {'fils': fils, 'currency': currency.code};

  bool get isZero => fils == 0;
  bool get isNegative => fils < 0;
  Money abs() => Money(fils.abs(), currency);

  Money _same(Money o, String op) {
    if (o.currency != currency) throw ArgumentError('cannot $op ${currency.code} and ${o.currency.code}');
    return o;
  }

  Money operator +(Money other) => Money(fils + _same(other, 'add').fils, currency);
  Money operator -(Money other) => Money(fils - _same(other, 'subtract').fils, currency);
  Money operator -() => Money(-fils, currency);

  /// Multiply by an integer quantity (guests, nights). Prices per guest times guests stay exact.
  Money operator *(int quantity) => Money(fils * quantity, currency);

  bool operator <(Money o) => compareTo(o) < 0;
  bool operator <=(Money o) => compareTo(o) <= 0;
  bool operator >(Money o) => compareTo(o) > 0;
  bool operator >=(Money o) => compareTo(o) >= 0;

  @override
  int compareTo(Money other) => fils.compareTo(_same(other, 'compare').fils);

  static Money sum(Iterable<Money> values, [CurrencyCode currency = CurrencyCode.kwd]) =>
      values.fold(Money(0, currency), (a, b) => a + b);

  @override
  List<Object?> get props => [fils, currency];

  @override
  String toString() => 'Money($fils ${currency.code})';
}
