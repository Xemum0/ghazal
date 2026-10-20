import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Initialises the `intl` date symbols for `ar` and `en` explicitly (the generated `AppL10n` and any `DateFormat` need
/// them) and pins `Intl.defaultLocale`. Call once in `bootstrap()` before `runApp`. Formatting of user-facing numbers,
/// dates and money does not go through intl: use `GzFormat`. Western digits are the default for `ar`.
Future<void> initGzIntl({String defaultLocale = 'ar'}) async {
  await initializeDateFormatting('ar');
  await initializeDateFormatting('en');
  Intl.defaultLocale = defaultLocale;
}
