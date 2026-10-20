/// Bilingual date and time text for notifications and system messages ("Thu 14 Jan" / "الخميس 14 يناير"). Western digits, like the seeds.
library;

import '../engine/dates.dart';
import '../engine/json.dart';

const _enDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
const _arDays = ['الأحد', 'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
const _enMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _arMonths = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];

String dateText(String date, String lang) {
  final wd = weekdayOf(date);
  final d = int.parse(date.substring(8, 10));
  final m = int.parse(date.substring(5, 7)) - 1;
  return lang == 'ar' ? '${_arDays[wd]} $d ${_arMonths[m]}' : '${_enDays[wd]} $d ${_enMonths[m]}';
}

/// "5:00 PM" / "5:00 م" from an `HH:mm` time.
String timeText(String hhmm, String lang) {
  final h = int.parse(hhmm.substring(0, 2));
  final m = hhmm.substring(3, 5);
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final suffix = lang == 'ar' ? (h < 12 ? 'ص' : 'م') : (h < 12 ? 'AM' : 'PM');
  return '$h12:$m $suffix';
}

/// "Fri 13 Nov, 12:40 PM" of an instant.
String instantText(String instant, String lang) => '${dateText(kuwaitDateOf(instant), lang)}${lang == 'ar' ? '،' : ','} ${timeText(kuwaitTimeOf(instant), lang)}';

Json dateLT(String date) => {'en': dateText(date, 'en'), 'ar': dateText(date, 'ar')};

Json instantLT(String instant) => {'en': instantText(instant, 'en'), 'ar': instantText(instant, 'ar')};

Json timeLT(String hhmm) => {'en': timeText(hhmm, 'en'), 'ar': timeText(hhmm, 'ar')};

/// "KD 15,400" / "15,400 د.ك" of integer fils (whole dinars shown without decimals unless needed).
Json moneyLT(int fils) {
  final whole = fils ~/ 1000;
  final rest = fils % 1000;
  final digits = whole.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
  final num = rest == 0 ? digits : '$digits.${rest.toString().padLeft(3, '0')}';
  return {'en': 'KD $num', 'ar': '$num د.ك'};
}
