import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DecimalOptions, MoneyMode, MoneyOptions;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, AreasResponse, HallSetting, HomeCategoryId, LocalDate, LuxuryLevel, PriceStructureFilter, ShelfId, VenueResult, VenueType;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show SearchBrief;
import '../../../../l10n/l10n.dart';
import '../../application/discover_chips.dart';
import '../../application/discover_filters.dart';
import '../../application/discover_search.dart' show hotelBrand;
import 'home_shelves.dart' show shelfDayLabel;

const List<Audience> kArrangements = <Audience>[Audience.women, Audience.men, Audience.mixed];
const List<HallSetting> kSettings = <HallSetting>[HallSetting.indoor, HallSetting.outdoor, HallSetting.mixed];
const List<LuxuryLevel> kLevels = <LuxuryLevel>[LuxuryLevel.prestige, LuxuryLevel.signature, LuxuryLevel.classic, LuxuryLevel.government];
const List<double> kRatings = <double>[3.5, 4, 4.5];
const List<int> kDistances = <int>[15, 30, 45];
const List<DiscoverSort> kSorts = DiscoverSort.values;

IconData arrangementIcon(Audience a) => switch (a) {
  Audience.women => GzIcons.sectionWomen,
  Audience.men => GzIcons.sectionMen,
  _ => GzIcons.sectionMixed,
};

IconData settingIcon(HallSetting s) => switch (s) {
  HallSetting.indoor => GzIcons.hall,
  HallSetting.outdoor => GzIcons.garden,
  _ => GzIcons.venue,
};

IconData facilityIcon(DiscoverFacility k) => switch (k) {
  DiscoverFacility.parking => GzIcons.parking,
  DiscoverFacility.valet => GzIcons.valet,
  DiscoverFacility.bridal => GzIcons.makeup,
  DiscoverFacility.buffet => GzIcons.buffet,
  DiscoverFacility.decor => GzIcons.decor,
  DiscoverFacility.photography => GzIcons.camera,
};

IconData typeIcon(VenueType t) => switch (t) {
  VenueType.governmental => GzIcons.bank,
  VenueType.hotel => GzIcons.hotel,
  _ => GzIcons.hall,
};

IconData levelIcon(LuxuryLevel l) => switch (l) {
  LuxuryLevel.prestige => GzIcons.crown,
  LuxuryLevel.signature => GzIcons.sparkle,
  LuxuryLevel.classic => GzIcons.star,
  _ => GzIcons.bank,
};

/// The words people read for a filter value: one place for the removable chips of Results and the summary lines of the Filters sheet, so the
/// two can never disagree. Words come from the message catalogue; numbers, money and dates from the shared formatter.
class DiscoverLabels {
  DiscoverLabels(this.context, {this.areas, this.brief = SearchBrief.empty});

  final BuildContext context;
  final AreasResponse? areas;
  final SearchBrief brief;

  AppL10n get _l => context.l10n;
  String get _lang => context.gz.locale.languageCode;

  String arrangement(Audience a) => switch (a) {
    Audience.women => _l.clientDiscoverArrangementWomen,
    Audience.men => _l.clientDiscoverArrangementMen,
    _ => _l.clientDiscoverArrangementMixed,
  };

  String setting(HallSetting s) => switch (s) {
    HallSetting.indoor => _l.clientDiscoverSettingIndoor,
    HallSetting.outdoor => _l.clientDiscoverSettingOutdoor,
    _ => _l.clientDiscoverSettingMixed,
  };

  String facility(DiscoverFacility k) => switch (k) {
    DiscoverFacility.parking => _l.clientDiscoverFacilityParking,
    DiscoverFacility.valet => _l.clientDiscoverFacilityValet,
    DiscoverFacility.bridal => _l.clientDiscoverFacilityBridal,
    DiscoverFacility.buffet => _l.clientDiscoverFacilityBuffet,
    DiscoverFacility.decor => _l.clientDiscoverFacilityDecor,
    DiscoverFacility.photography => _l.clientDiscoverFacilityPhotography,
  };

  String level(LuxuryLevel l) => switch (l) {
    LuxuryLevel.prestige => _l.clientDiscoverLevelPrestige,
    LuxuryLevel.signature => _l.clientDiscoverLevelSignature,
    LuxuryLevel.classic => _l.clientDiscoverLevelClassic,
    _ => _l.clientDiscoverLevelGovernment,
  };

  String category(HomeCategoryId id) => switch (id) {
    HomeCategoryId.luxuryHotels => _l.clientDiscoverCategoryLuxuryHotels,
    HomeCategoryId.weddingHalls => _l.clientDiscoverCategoryWeddingHalls,
    HomeCategoryId.government => _l.clientDiscoverCategoryGovernment,
    HomeCategoryId.beach => _l.clientDiscoverCategoryBeach,
    HomeCategoryId.outdoor => _l.clientDiscoverCategoryOutdoor,
    HomeCategoryId.vip => _l.clientDiscoverCategoryVip,
    HomeCategoryId.unknown => '',
  };

  String sort(DiscoverSort s) => switch (s) {
    DiscoverSort.recommended => _l.clientDiscoverSortRecommended,
    DiscoverSort.voucherPrice => _l.clientDiscoverSortVoucher,
    DiscoverSort.rating => _l.clientDiscoverSortRating,
    DiscoverSort.newest => _l.clientDiscoverSortNewest,
    DiscoverSort.price => _l.clientDiscoverSortPrice,
    DiscoverSort.priceDesc => _l.clientDiscoverSortPriceDesc,
    DiscoverSort.distance => _l.clientDiscoverSortDistance,
  };

  String venueType(VenueType t) => switch (t) {
    VenueType.governmental => _l.commonVenueTypeGovernmental,
    VenueType.hotel => _l.commonVenueTypeHotel,
    _ => _l.commonVenueTypePrivateHall,
  };

  String structure(PriceStructureFilter s) => s == PriceStructureFilter.package ? _l.commonPricingPackages : _l.commonPricingPerPerson;

  String governorate(String id) => areas?.governorates.where((g) => g.id == id).firstOrNull?.name.of(_lang) ?? '';

  String _list(Iterable<String> items) => context.gzFormat.list(items.where((e) => e.isNotEmpty).toList());

  String governorates(List<String> ids) => _list(ids.map(governorate));

  String within(int minutes) => _l.clientDiscoverMinutes(context.gzFormat.integer(minutes));

  String capacity(int lo, int hi) => context.gzFormat.numberRange(lo, hi);

  String money(num kd) => context.gzFormat.money((kd * 1000).round(), const MoneyOptions(mode: MoneyMode.browse));

  String moneyRange(int lo, int hi) => context.gzFormat.moneyRange(lo * 1000, hi * 1000, const MoneyOptions(mode: MoneyMode.browse));

  String rating(double r) => context.gzFormat.number(r, const DecimalOptions(minFraction: 1, maxFraction: 1));

  String ratingChip(double r) => _l.clientDiscoverChipRating(rating(r));

  /// A hotel brand in the current language (the filter keeps the English brand).
  String brand(String en, List<VenueResult> roster) {
    for (final r in roster) {
      if (hotelBrand(r.venue, 'en') == en) return hotelBrand(r.venue, _lang) ?? en;
    }
    return en;
  }

  String day(String iso) => shelfDayLabel(context, iso);

  String dateRange((LocalDate, LocalDate) r) => r.$1.toString() == r.$2.toString() ? day(r.$1.toString()) : '${day(r.$1.toString())} – ${day(r.$2.toString())}';

  String shelf(ShelfId id) => switch (id) {
    ShelfId.free => _l.clientDiscoverFreeTitle(brief.date == null ? '' : day(brief.date.toString())),
    ShelfId.featured => _l.clientDiscoverFeaturedTitle,
    ShelfId.voucher => _l.clientDiscoverVoucherTitle,
    ShelfId.week => _l.clientDiscoverWeekTitle,
    ShelfId.recommended => _l.clientDiscoverRecommendedTitle,
    ShelfId.trending => _l.clientDiscoverTrendingTitle,
    ShelfId.nearby => _l.clientDiscoverNearbyTitle,
    ShelfId.unknown => '',
  };

  /// The words of an applied chip.
  String chipLabel(ChipSpec c) {
    switch (c.kind) {
      case ChipKind.shelf:
        return shelf(c.arg! as ShelfId);
      case ChipKind.category:
        return category(c.arg! as HomeCategoryId);
      case ChipKind.governorates:
        final ids = c.arg! as List<String>;
        return ids.isEmpty ? _l.clientDiscoverChipGovernoratesAll : governorates(ids);
      case ChipKind.type:
        return venueType(c.arg! as VenueType);
      case ChipKind.available:
        return day(c.arg.toString());
      case ChipKind.dates:
        return dateRange(c.arg! as (LocalDate, LocalDate));
      case ChipKind.arrangement:
        return arrangement(c.arg! as Audience);
      case ChipKind.within:
        return within(c.arg! as int);
      case ChipKind.capacity:
        final r = c.arg! as (int, int);
        return capacity(r.$1, r.$2);
      case ChipKind.structure:
        return structure(c.arg! as PriceStructureFilter);
      case ChipKind.voucher:
        return _l.clientDiscoverChipVoucher;
      case ChipKind.voucherPrice || ChipKind.price:
        final r = c.arg! as (int, int);
        return moneyRange(r.$1, r.$2);
      case ChipKind.setting:
        return setting(c.arg! as HallSetting);
      case ChipKind.facility:
        return facility(c.arg! as DiscoverFacility);
      case ChipKind.rating:
        return ratingChip(c.arg! as double);
      case ChipKind.level:
        return level(c.arg! as LuxuryLevel);
      case ChipKind.brand:
        return c.arg! as String;
    }
  }

  /// The glyph that says what kind of filter an applied chip is (the label is a value).
  IconData? chipIcon(ChipSpec c) => switch (c.kind) {
    ChipKind.governorates => GzIcons.pin,
    ChipKind.type => typeIcon(c.arg! as VenueType),
    ChipKind.available || ChipKind.dates => GzIcons.calendarCheck,
    ChipKind.arrangement => arrangementIcon(c.arg! as Audience),
    ChipKind.within => GzIcons.car,
    ChipKind.capacity => GzIcons.usersThree,
    ChipKind.structure => c.arg == PriceStructureFilter.package ? GzIcons.package : GzIcons.perGuest,
    ChipKind.voucher || ChipKind.voucherPrice => GzIcons.ticket,
    ChipKind.price => GzIcons.perGuest,
    ChipKind.setting => settingIcon(c.arg! as HallSetting),
    ChipKind.facility => facilityIcon(c.arg! as DiscoverFacility),
    ChipKind.rating => GzIcons.star,
    ChipKind.level => levelIcon(c.arg! as LuxuryLevel),
    _ => null,
  };
}
