import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_api/ghazal_api.dart';
import 'package:ghazal_core/ghazal_core.dart';
import 'package:ghazal_domain/ghazal_domain.dart';

void main() {
  test('wire money and display money are the same value', () {
    const wire = MoneyAmount(15400000);
    final money = wire.toMoney();
    expect(money, const Money(15400000));
    expect(money.toAmount(), wire);
    expect(MoneyAmount.fromJson({'fils': 2000, 'currency': 'KWD'}).toMoney(), Money.major(2));
  });
}
