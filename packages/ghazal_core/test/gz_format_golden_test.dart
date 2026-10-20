import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:ghazal_core/ghazal_core.dart';

/// Runs packages/contracts/fixtures/format-cases.json (generated from the TypeScript formatters) against GzFormat.
void main() {
  final file = File('../contracts/fixtures/format-cases.json');
  final doc = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
  final fixed = DateTime.parse(doc['now']! as String);
  final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

  test('fixture is present and large', () => expect(cases.length, greaterThan(1500)));

  for (final c in cases) {
    test(c['id']! as String, () {
      final lang = c['lang']! as String;
      final fmt = GzFormat(
        locale: Locale(lang),
        digitStyle: DigitStyle.fromName(c['digitStyle'] as String?),
        now: () => fixed,
      );
      final actual = _call(fmt, c['fn']! as String, (c['args']! as List).cast<Object?>());
      expect(jsonEncode(actual), jsonEncode(c['expect']));
    });
  }
}

MoneyOptions _mo(Object? j) => MoneyOptions.fromJson(j as Map<String, Object?>?);
DecimalOptions _do(Object? j) => DecimalOptions.fromJson(j as Map<String, Object?>?);
Object? _at(List<Object?> a, int i) => i < a.length ? a[i] : null;
DateStyle _ds(Object? j) => j == null ? DateStyle.full : DateStyle.values.byName(j as String);

Object? _call(GzFormat f, String fn, List<Object?> a) {
  switch (fn) {
    case 'money':
      return f.money(a[0]! as int, _mo(_at(a, 1)));
    case 'moneyParts':
      return f.moneyParts(a[0]! as int, _mo(_at(a, 1))).toJson();
    case 'moneySet':
      return f.moneySet((a[0]! as List).cast<int>(), _mo(_at(a, 1)));
    case 'moneyRange':
      return f.moneyRange(a[0]! as int, a[1]! as int, _mo(_at(a, 2)));
    case 'moneyAxis':
      return f.moneyAxis(a[0]! as int, _mo(_at(a, 1)));
    case 'priceUnit':
      return f.priceUnit(a[0]! as int, PriceUnit.values.byName(a[1]! as String), _mo(_at(a, 2)));
    case 'flatFee':
      return f.flatFee(a[0]! as int, a[1]! as String, _mo(_at(a, 2)));
    case 'priceForGuests':
      return f.priceForGuests(a[0]! as int, a[1]! as int, a.length > 2 ? PricePrefix.values.byName(a[2]! as String) : PricePrefix.none, _mo(_at(a, 3)));
    case 'fromPriceMin':
      return f.fromPriceMin(a[0]! as int, a[1]! as int, _mo(_at(a, 2)));
    case 'guests':
      return f.guests(a[0]! as int, afterPreposition: (_at(a, 1) as Map?)?['afterPreposition'] == true);
    case 'minGuests':
      return f.minGuests(a[0]! as int);
    case 'number':
      return f.number(a[0]! as num, _do(_at(a, 1)));
    case 'integer':
      return f.integer(a[0]! as num);
    case 'percent':
      return f.percent(a[0]! as num, maxFraction: ((_at(a, 1) as Map?)?['maxFraction'] as num?)?.toInt() ?? 0);
    case 'numberRange':
      return f.numberRange(a[0]! as num, a[1]! as num, _do(_at(a, 2)));
    case 'counter':
      return f.counter(a[0]! as num, a[1]! as num);
    case 'pluralCategory':
      return f.pluralCategory(a[0]! as num).name;
    case 'plural':
      return f.plural(a[0]! as num, (a[1]! as Map).cast<String, String>());
    case 'list':
      return f.list((a[0]! as List).cast<String>(), or: _at(a, 1) == 'or');
    case 'date':
      return f.date(a[0]!, _ds(_at(a, 1)));
    case 'dateTime':
      return f.dateTime(a[0]!, a.length > 1 ? _ds(a[1]) : DateStyle.short);
    case 'hijri':
      return f.hijri(a[0]!);
    case 'hijriShort':
      return f.hijriShort(a[0]!);
    case 'dateWithHijri':
      final d = f.dateWithHijri(a[0]!);
      return {'primary': d.primary, 'secondary': d.secondary, 'joined': d.joined};
    case 'time':
      return f.time(a[0]!, clock24h: _at(a, 1) == null ? null : _at(a, 1) == '24h');
    case 'timeRange':
      return f.timeRange(a[0]!, a[1]!);
    case 'relativeDay':
      return f.relativeDay(a[0]!);
    case 'daysUntil':
      return f.daysUntil(a[0]!);
    case 'countdownDays':
      return f.countdownDays(a[0]! as num);
    case 'duration':
      return f.duration(a[0]! as num);
    case 'ago':
      return f.ago(a[0]!);
    case 'weekdayName':
      return f.weekdayName(a[0]! as int, a.length > 1 ? NameStyle.values.byName(a[1]! as String) : NameStyle.long);
    case 'monthName':
      return f.monthName(a[0]! as int, short: _at(a, 1) == 'short');
    case 'weekdayHeaders':
      return f.weekdayHeaders();
    case 'weekdayLabels':
      return f.weekdayLabels();
    case 'monthGrid':
      return [for (final w in f.monthGrid(a[0]! as int, a[1]! as int)) [for (final d in w) d.toJson()]];
    case 'civil':
      return f.civil(a[0]!).toJson();
    case 'isoDay':
      return f.isoDay(a[0]!);
    case 'addDays':
      return f.addDays(a[0]!, a[1]! as int).toIso8601String().replaceAll(RegExp(r'\.0+Z$'), '.000Z');
    case 'phone':
      return f.phone(a[0]! as String);
    case 'phoneNational':
      return f.phoneNational(a[0]! as String);
    case 'normalizePhone':
      return f.normalizePhone(a[0]! as String);
    case 'e164':
      return f.e164(a[0]! as String);
    case 'telHref':
      return f.telHref(a[0]! as String);
    case 'whatsappHref':
      return f.whatsappHref(a[0]! as String);
    case 'isValidPhone':
      return f.isValidPhone(a[0]! as String);
    case 'normalizeDigits':
      return f.normalizeDigits(a[0]! as String);
    case 'plain':
      return f.plain(a[0]! as String);
  }
  fail('no dispatcher for GzFormat.$fn');
}
