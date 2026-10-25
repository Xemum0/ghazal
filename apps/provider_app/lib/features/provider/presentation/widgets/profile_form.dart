// The profile form of HL-PROV-01: business name in both languages, then categories (a provider) or venue type, governorate and area (a venue),
// then the contact phone and, for a provider, the logo row (a monogram is generated). Lists load behind the pickers; the form itself never waits.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show venuesRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' hide FieldError;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/provider_data.dart';
import 'account_cards.dart';
import 'category_sheet.dart';
import 'prov_bits.dart';

@immutable
final class ProfileDraft {
  const ProfileDraft({this.nameAr = '', this.nameEn = '', this.cats = const [], this.venueType, this.gov, this.area, this.phone = ''});

  final String nameAr;
  final String nameEn;
  final List<ServiceCategoryId> cats;
  final String? venueType;
  final String? gov;
  final String? area;
  final String phone;

  ProfileDraft copyWith({String? nameAr, String? nameEn, List<ServiceCategoryId>? cats, String? venueType, String? gov, String? area, bool clearArea = false, String? phone}) => ProfileDraft(
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    cats: cats ?? this.cats,
    venueType: venueType ?? this.venueType,
    gov: gov ?? this.gov,
    area: clearArea ? null : (area ?? this.area),
    phone: phone ?? this.phone,
  );

  bool incomplete({required bool venue}) =>
      nameAr.trim().isEmpty || nameEn.trim().isEmpty || (!venue && cats.isEmpty) || (venue && (venueType == null || gov == null || area == null)) || phone.length != 8;
}

final FutureProvider<AreasResponse> _areasProvider = FutureProvider.autoDispose<AreasResponse>((ref) => ref.read(venuesRepositoryProvider).listAreas());

class ProfileForm extends ConsumerWidget {
  const ProfileForm({required this.venue, required this.draft, required this.tried, required this.failed, required this.onChanged, required this.onRetry, super.key});

  final bool venue;
  final ProfileDraft draft;
  final bool tried;
  final bool failed;
  final ValueChanged<ProfileDraft> onChanged;
  final VoidCallback onRetry;

  void _pick(BuildContext context, String title, List<GzSelectOption<String>> options, String? selected, ValueChanged<String> onPick, {bool searchable = false}) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => GzPickerList<String>(
        options: options,
        selected: [?selected],
        searchable: searchable,
        onPick: (v) {
          onPick(v);
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: title),
    );
  }

  void _categories(BuildContext context, List<ServiceCategory> all) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => CategorySheet(
        categories: all,
        value: draft.cats,
        max: 3,
        onApply: (v) {
          onChanged(draft.copyWith(cats: v));
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelProviderProfileCategories),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final required = l.hotelProviderRequired;
    final cats = ref.watch(allServiceCategoriesProvider).value ?? const <ServiceCategory>[];
    final areas = ref.watch(_areasProvider).value;
    final govs = [for (final g in areas?.governorates ?? const <Governorate>[]) GzSelectOption<String>(value: g.id, label: g.name.of(lang))];
    final areaOptions = [for (final a in (areas?.areas ?? const <Area>[]).where((a) => a.governorateId == draft.gov)) GzSelectOption<String>(value: a.id, label: a.name.of(lang))];
    const gap = SizedBox(height: GzSpace.s5);
    const small = SizedBox(height: GzSpace.s3);
    ServiceCategory? cat(ServiceCategoryId id) => cats.where((x) => x.id == id).firstOrNull;
    final logoName = draft.nameEn.trim().isNotEmpty ? draft.nameEn : (draft.nameAr.trim().isNotEmpty ? draft.nameAr : '·');

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderSubmitErrorTitle, actionLabel: l.hotelProviderRetryShort, onAction: onRetry), gap],
          BilingualField(
            label: l.hotelProviderProfileName,
            ar: draft.nameAr,
            en: draft.nameEn,
            onAr: (v) => onChanged(draft.copyWith(nameAr: v)),
            onEn: (v) => onChanged(draft.copyWith(nameEn: v)),
            errorAr: tried && draft.nameAr.trim().isEmpty ? required : null,
            errorEn: tried && draft.nameEn.trim().isEmpty ? required : null,
            maxLength: 60,
          ),
          gap,
          if (venue) ...[
            GzText(l.hotelProviderProfileVenueType, role: GzTextRole.label, color: c.textSecondary),
            small,
            GzChipGroup<String>(
              label: l.hotelProviderProfileVenueType,
              value: draft.venueType,
              onChanged: (v) => onChanged(draft.copyWith(venueType: v)),
              options: [
                GzChipOption<String>(value: 'private-hall', label: l.hotelProviderVenueTypeHall),
                GzChipOption<String>(value: 'hotel', label: l.hotelProviderVenueTypeHotel),
              ],
            ),
            if (tried && draft.venueType == null) ...[small, FieldError(required)],
            gap,
            GzSelectRow<String>(
              label: l.hotelProviderProfileGovernorate,
              options: govs,
              values: [if (draft.gov != null) draft.gov!],
              placeholder: l.hotelProviderProfileChoose,
              error: tried && draft.gov == null ? required : null,
              onTap: () => _pick(context, l.hotelProviderProfileGovernorate, govs, draft.gov, (v) => onChanged(draft.copyWith(gov: v, clearArea: true))),
            ),
            gap,
            GzSelectRow<String>(
              label: l.hotelProviderProfileArea,
              options: areaOptions,
              values: [if (draft.area != null) draft.area!],
              placeholder: l.hotelProviderProfileChoose,
              disabled: draft.gov == null,
              error: tried && draft.gov != null && draft.area == null ? required : null,
              onTap: () => _pick(context, l.hotelProviderProfileArea, areaOptions, draft.area, (v) => onChanged(draft.copyWith(area: v)), searchable: true),
            ),
          ] else ...[
            GzText(l.hotelProviderProfileCategories, role: GzTextRole.label, color: c.textSecondary),
            small,
            if (draft.cats.isNotEmpty) ...[
              Wrap(
                spacing: GzSpace.s2,
                runSpacing: GzSpace.s2,
                children: [for (final id in draft.cats) SelectedCategory(icon: GzIcons.byName[cat(id)?.icon] ?? GzIcons.flower, label: cat(id)?.name.of(lang) ?? '')],
              ),
              small,
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzButton(
                label: draft.cats.isEmpty ? l.hotelProviderCatsChoose : l.hotelProviderCatsEdit,
                variant: GzButtonVariant.secondary,
                iconStart: draft.cats.isEmpty ? GzIcons.plus : GzIcons.edit,
                onPressed: cats.isEmpty ? null : () => _categories(context, cats),
              ),
            ),
            if (tried && draft.cats.isEmpty) ...[small, FieldError(required)],
          ],
          gap,
          GzPhoneField(
            valueAlign: GzPhoneValueAlign.chip,
            label: l.hotelProviderProfilePhone,
            value: draft.phone,
            onChange: (n, _) => onChanged(draft.copyWith(phone: n)),
            error: tried && draft.phone.length != 8 ? l.hotelProviderPhoneError : null,
            validateOnBlur: false,
          ),
          if (!venue) ...[
            gap,
            Row(
              children: [
                GzAvatar(name: logoName, voice: GzAvatarVoice.sans),
                const SizedBox(width: GzSpace.s3),
                Expanded(child: GzText(l.hotelProviderLogoTitle, role: GzTextRole.title, color: c.textStrong)),
                GzButton(
                  label: l.hotelProviderLogoUpload,
                  variant: GzButtonVariant.tertiary,
                  onPressed: () => GzNavigatorScope.of(context).toast(GzToastSpec(message: l.hotelProviderLogoToast, icon: GzIcons.info)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
