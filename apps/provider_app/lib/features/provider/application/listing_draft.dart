// The editor's draft (web `provider/_components/store.ts` + `money.ts`): what the person typed for a listing and its packages, the checks
// that stop a listing going to review (PA-LST-02), and the KD text <-> integer fils conversion of the price fields (ADR 0010: numeric keypad,
// Eastern digits normalised, up to three decimals; money is never a float).
import 'package:flutter/foundation.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart';

/// `"52"`, `"52.5"`, `"٥٢٫٥٠٠"` to fils; null when empty or not an amount with at most three decimals.
int? parseKd(GzFormat f, String text) {
  final plain = f.normalizeDigits(text).replaceAll(RegExp('[٫،]'), '.').replaceAll(RegExp(r'[\s,]'), '');
  final m = RegExp(r'^(\d{1,6})(?:\.(\d{1,3}))?$').firstMatch(plain);
  if (m == null) return null;
  final whole = int.parse(m.group(1)!);
  if (whole > 999999) return null;
  final frac = (m.group(2) ?? '').padRight(3, '0');
  return whole * 1000 + int.parse(frac);
}

/// Fils as editable text: `52` for whole dinars, `52.500` when any fils exist. Latin digits: the field is an LTR island.
String kdText(int? fils) {
  if (fils == null) return '';
  final whole = fils ~/ 1000;
  final rest = fils % 1000;
  return rest == 0 ? '$whole' : '$whole.${rest.toString().padLeft(3, '0')}';
}

bool isArabicText(String s) => RegExp('[؀-ۿݐ-ݿ]').hasMatch(s);

/// One package of the editor: both languages of its name, the basis, the two prices and the inclusions as typed.
@immutable
final class PackageDraft {
  const PackageDraft({
    required this.id,
    this.nameAr = '',
    this.nameEn = '',
    this.structure = PriceStructure.package,
    this.standardFils,
    this.voucherFils,
    this.includes = const <LocalizedText>[],
    this.isNew = false,
  });

  factory PackageDraft.of(ProviderPackage p) => PackageDraft(
        id: p.id,
        nameAr: p.name.ar ?? '',
        nameEn: p.name.en ?? '',
        structure: p.priceStructure,
        standardFils: p.price.fils,
        voucherFils: p.voucherPrice?.fils,
        includes: p.includes,
      );

  final String id;
  final String nameAr;
  final String nameEn;
  final PriceStructure structure;
  final int? standardFils;
  final int? voucherFils;
  final List<LocalizedText> includes;

  /// Not saved on the server yet (the id is local).
  final bool isNew;

  PackageDraft copyWith({
    String? nameAr,
    String? nameEn,
    PriceStructure? structure,
    Object? standardFils = _unset,
    Object? voucherFils = _unset,
    List<LocalizedText>? includes,
  }) =>
      PackageDraft(
        id: id,
        nameAr: nameAr ?? this.nameAr,
        nameEn: nameEn ?? this.nameEn,
        structure: structure ?? this.structure,
        standardFils: identical(standardFils, _unset) ? this.standardFils : standardFils as int?,
        voucherFils: identical(voucherFils, _unset) ? this.voucherFils : voucherFils as int?,
        includes: includes ?? this.includes,
        isNew: isNew,
      );

  /// The name in [lang], falling back to the other language.
  String nameIn(String lang) => lang == 'ar' ? (nameAr.isEmpty ? nameEn : nameAr) : (nameEn.isEmpty ? nameAr : nameEn);

  int? get savingFils => standardFils != null && voucherFils != null ? standardFils! - voucherFils! : null;

  /// A voucher is offered only when the saving is more than the fee (voucher-model 4.1).
  bool voucherOffered(int feeFils) => (savingFils ?? 0) > feeFils;

  bool get complete =>
      nameAr.trim().isNotEmpty && nameEn.trim().isNotEmpty && standardFils != null && standardFils! > 0 && voucherFils != null && voucherFils! <= standardFils!;

  @override
  bool operator ==(Object other) =>
      other is PackageDraft &&
      other.id == id &&
      other.nameAr == nameAr &&
      other.nameEn == nameEn &&
      other.structure == structure &&
      other.standardFils == standardFils &&
      other.voucherFils == voucherFils &&
      listEquals(other.includes, includes);

  @override
  int get hashCode => Object.hash(id, nameAr, nameEn, structure, standardFils, voucherFils, Object.hashAll(includes));
}

const Object _unset = Object();

/// What the editor holds for a listing. [photos] is the cover the API knows about; [chat] and [showPhone] are the browse-only contact
/// options (the API has no field for them yet: requests.md).
@immutable
final class ListingDraft {
  const ListingDraft({
    this.categoryId,
    this.titleAr = '',
    this.titleEn = '',
    this.descAr = '',
    this.descEn = '',
    this.photos = const <ImageRef>[],
    this.packages = const <PackageDraft>[],
    this.chat = true,
    this.showPhone = true,
  });

  factory ListingDraft.of(Listing l, List<ProviderPackage> all) => ListingDraft(
        categoryId: l.categoryId,
        titleAr: l.title.ar ?? '',
        titleEn: l.title.en ?? '',
        descAr: l.description.ar ?? '',
        descEn: l.description.en ?? '',
        photos: [?l.cover],
        packages: [for (final p in all) if (l.packageIds.contains(p.id)) PackageDraft.of(p)],
      );

  final ServiceCategoryId? categoryId;
  final String titleAr;
  final String titleEn;
  final String descAr;
  final String descEn;
  final List<ImageRef> photos;
  final List<PackageDraft> packages;
  final bool chat;
  final bool showPhone;

  ListingDraft copyWith({
    Object? categoryId = _unset,
    String? titleAr,
    String? titleEn,
    String? descAr,
    String? descEn,
    List<ImageRef>? photos,
    List<PackageDraft>? packages,
    bool? chat,
    bool? showPhone,
  }) =>
      ListingDraft(
        categoryId: identical(categoryId, _unset) ? this.categoryId : categoryId as ServiceCategoryId?,
        titleAr: titleAr ?? this.titleAr,
        titleEn: titleEn ?? this.titleEn,
        descAr: descAr ?? this.descAr,
        descEn: descEn ?? this.descEn,
        photos: photos ?? this.photos,
        packages: packages ?? this.packages,
        chat: chat ?? this.chat,
        showPhone: showPhone ?? this.showPhone,
      );

  String titleIn(String lang) => lang == 'ar' ? (titleAr.isEmpty ? titleEn : titleAr) : (titleEn.isEmpty ? titleAr : titleEn);

  @override
  bool operator ==(Object other) =>
      other is ListingDraft &&
      other.categoryId == categoryId &&
      other.titleAr == titleAr &&
      other.titleEn == titleEn &&
      other.descAr == descAr &&
      other.descEn == descEn &&
      listEquals(other.photos, photos) &&
      listEquals(other.packages, packages) &&
      other.chat == chat &&
      other.showPhone == showPhone;

  @override
  int get hashCode => Object.hash(categoryId, titleAr, titleEn, descAr, descEn, Object.hashAll(photos), Object.hashAll(packages), chat, showPhone);
}

/// What stops a listing being sent for review (PA-LST-02): both languages, a category, at least one complete package.
@immutable
final class DraftProblems {
  const DraftProblems({this.category = false, this.titleAr = false, this.titleEn = false, this.descAr = false, this.descEn = false, this.packages = false});

  final bool category;
  final bool titleAr;
  final bool titleEn;
  final bool descAr;
  final bool descEn;
  final bool packages;

  bool get any => category || titleAr || titleEn || descAr || descEn || packages;
}

DraftProblems problemsOf(ListingDraft d) => DraftProblems(
      category: d.categoryId == null,
      titleAr: d.titleAr.trim().isEmpty,
      titleEn: d.titleEn.trim().isEmpty,
      descAr: d.descAr.trim().isEmpty,
      descEn: d.descEn.trim().isEmpty,
      packages: d.packages.isEmpty || !d.packages.every((p) => p.complete),
    );
