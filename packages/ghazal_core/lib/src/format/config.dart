// Per-country configuration (ADR 0010 D6, ADR 0011 D4, ADR 0012 D1). Dart twin of packages/i18n/src/config.ts.
// Nothing is read from the device locale or time zone: digits, week start, weekend, currency exponent and phone shape
// are explicit so the Dart and web formatters cannot drift, and GCC expansion is configuration.

/// `western` is the default in both languages; `easternArabic` is the Settings switch (ADR 0010 D2), Arabic only.
enum DigitStyle {
  western,
  easternArabic;

  static DigitStyle fromName(String? name) =>
      DigitStyle.values.firstWhere((s) => s.name == name, orElse: () => DigitStyle.western);
}

/// The two UI languages (ADR 0022 E).
enum Lang {
  en,
  ar;

  static Lang fromCode(String code) => code == 'ar' ? Lang.ar : Lang.en;
}

enum CurrencyCode {
  kwd('KWD', 3, 'KD', 'د.ك'),
  bhd('BHD', 3, 'BD', 'د.ب'),
  omr('OMR', 3, 'OMR', 'ر.ع'),
  aed('AED', 2, 'AED', 'د.إ'),
  sar('SAR', 2, 'SAR', 'ر.س'),
  qar('QAR', 2, 'QAR', 'ر.ق');

  const CurrencyCode(this.code, this.exponent, this.consumerEn, this.consumerAr);

  /// ISO code, also the legal label (invoices, bank settings, API).
  final String code;

  /// Minor-unit exponent: 3 for KWD/BHD/OMR (1,000 fils), 2 for AED/SAR/QAR.
  final int exponent;

  /// Consumer label per language (ADR 0010 D7): `KD` in English, `د.ك` in Arabic, no trailing period.
  final String consumerEn;
  final String consumerAr;

  int get unit => switch (exponent) { 3 => 1000, _ => 100 };

  String consumer(Lang lang) => lang == Lang.ar ? consumerAr : consumerEn;

  static CurrencyCode fromCode(String code) =>
      CurrencyCode.values.firstWhere((c) => c.code == code, orElse: () => throw FormatException('Unknown currency: $code'));
}

/// Weekday as the JavaScript convention: 0 = Sunday ... 6 = Saturday.
typedef Weekday = int;

class PhoneConfig {
  const PhoneConfig({required this.callingCode, required this.nationalPattern, required this.groups});

  /// Calling code without the plus.
  final String callingCode;

  /// Loose shape check on the national number (ADR 0012 D1): never a libphonenumber `isValid`.
  final RegExp nationalPattern;

  /// Display grouping of the national number (ADR 0012 D2: 4 + 4).
  final List<int> groups;
}

class CountryConfig {
  const CountryConfig({
    required this.id,
    required this.currency,
    required this.timeZone,
    required this.utcOffsetMinutes,
    required this.weekStartsOn,
    required this.weekend,
    required this.peakBand,
    required this.phone,
    this.clock24h = false,
  });

  final String id;
  final CurrencyCode currency;

  /// IANA name, informational. Every GCC zone is a fixed offset (no DST).
  final String timeZone;

  /// Minutes east of UTC. Kuwait is UTC+3 all year.
  final int utcOffsetMinutes;
  final Weekday weekStartsOn;
  final List<Weekday> weekend;
  final List<Weekday> peakBand;
  final PhoneConfig phone;

  /// Display clock: always 12-hour in the apps (ADR 0011 D3).
  final bool clock24h;
}

final CountryConfig kKuwait = CountryConfig(
  id: 'KW',
  currency: CurrencyCode.kwd,
  timeZone: 'Asia/Kuwait',
  utcOffsetMinutes: 180,
  weekStartsOn: 0,
  weekend: const [5, 6],
  peakBand: const [4, 5, 6],
  phone: PhoneConfig(callingCode: '965', nationalPattern: RegExp(r'^(?:[2569]\d{7}|41\d{6})$'), groups: const [4, 4]),
);

/// Language names as each language writes them: the one place Arabic script appears in an English UI and the reverse.
const Map<Lang, String> kLanguageNativeName = {Lang.en: 'English', Lang.ar: 'العربية'};
