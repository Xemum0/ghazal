// The fields of the application form (web `HL-PROV-01.tsx`, the form step): business name in both languages, categories (up to three) plus the open
// "Other" note for a provider, the governorate as wrapping chips, contact person, phone, email, a short description and the optional licence
// reference. Every field shows its own inline error after a first try; notes on top say what happened (resubmit reason, fix the marked fields,
// nothing was sent). Signed out (round 2b) the screen passes [account] ("Your account" with its own email field, which is also the contact email,
// so the business section does not ask for it again) and a "Your business" heading follows it.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' hide FieldError;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/application_form.dart';
import '../../application/provider_data.dart';
import 'account_cards.dart';
import 'category_sheet.dart';
import 'prov_bits.dart';

class ApplicationFields extends StatelessWidget {
  const ApplicationFields({
    required this.form,
    required this.setup,
    required this.tried,
    required this.failed,
    required this.onChanged,
    required this.onRetry,
    this.resubmitNote,
    this.account,
    this.accountBad = false,
    super.key,
  });

  final ApplicationForm form;
  final ApplicationSetup setup;
  final bool tried;
  final bool failed;
  final ValueChanged<ApplicationForm> onChanged;
  final VoidCallback onRetry;

  /// The staff note of a rejected application ("Not approved: ..."), shown on top of "Edit and resubmit".
  final String? resubmitNote;

  /// The "Your account" section of the signed-out form (it holds the email of the application); null when signed in.
  final Widget? account;

  /// The account part has a problem: the "fix the marked fields" note shows with the business ones.
  final bool accountBad;

  void _categories(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => CategorySheet(
        categories: setup.categories,
        value: form.cats,
        max: kMaxCategories,
        onApply: (v) {
          onChanged(form.copyWith(cats: v));
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelProviderProfileCategories),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final c = context.gz.colors;
    final required = l.hotelProviderRequired;
    final missing = form.missing;
    final showFix = tried && (missing.any || accountBad);
    ServiceCategory? cat(ServiceCategoryId id) => setup.categories.where((x) => x.id == id).firstOrNull;
    const gap = SizedBox(height: GzSpace.s5);
    const small = SizedBox(height: GzSpace.s3);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failed) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderSubmitError, actionLabel: l.hotelProviderRetryShort, onAction: onRetry), gap],
          if (resubmitNote != null) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderFormResubmitNote(resubmitNote!)), gap],
          if (showFix) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderFormFix), gap],
          if (account != null) ...[
            account!,
            const SizedBox(height: GzSpace.s5 + GzSpace.s3),
            GzText(l.hotelProviderFormBusinessTitle, role: GzTextRole.title, color: c.textStrong, header: true),
            gap,
          ],
          BilingualField(
            label: l.hotelProviderProfileName,
            ar: form.nameAr,
            en: form.nameEn,
            onAr: (v) => onChanged(form.copyWith(nameAr: v)),
            onEn: (v) => onChanged(form.copyWith(nameEn: v)),
            errorAr: tried && missing.nameAr ? required : null,
            errorEn: tried && missing.nameEn ? required : null,
            maxLength: 60,
          ),
          gap,
          if (!form.isHall) ...[
            GzText(l.hotelProviderProfileCategories, role: GzTextRole.label, color: c.textSecondary),
            small,
            if (form.cats.isNotEmpty) ...[
              Wrap(
                spacing: GzSpace.s2,
                runSpacing: GzSpace.s2,
                children: [for (final id in form.cats) SelectedCategory(icon: GzIcons.byName[cat(id)?.icon] ?? GzIcons.flower, label: cat(id)?.name.of(lang) ?? '')],
              ),
              small,
            ],
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzButton(
                label: form.cats.isEmpty ? l.hotelProviderCatsChoose : l.hotelProviderCatsEdit,
                variant: GzButtonVariant.secondary,
                iconStart: form.cats.isEmpty ? GzIcons.plus : GzIcons.edit,
                onPressed: () => _categories(context),
              ),
            ),
            small,
            GzTextField(
              label: l.hotelProviderFormOther,
              helper: l.hotelProviderFormOtherHelper,
              maxLength: 60,
              value: form.otherNote,
              onValueChange: (v) => onChanged(form.copyWith(otherNote: v)),
            ),
            if (tried && missing.cats) ...[small, FieldError(required)],
            gap,
          ],
          GzText(l.hotelProviderProfileGovernorate, role: GzTextRole.label, color: c.textSecondary),
          small,
          GzChipGroup<String>(
            label: l.hotelProviderProfileGovernorate,
            layout: GzChipLayout.wrap,
            value: form.gov,
            onChanged: (v) {
              if (v != null) onChanged(form.copyWith(gov: v));
            },
            options: [for (final g in setup.governorates) GzChipOption<String>(value: g.id, label: g.name.of(lang), figures: false)],
          ),
          if (tried && missing.gov) ...[small, FieldError(required)],
          gap,
          GzTextField(
            label: l.hotelProviderFormContact,
            maxLength: 60,
            value: form.contact,
            onValueChange: (v) => onChanged(form.copyWith(contact: v)),
            error: tried && missing.contact ? required : null,
          ),
          gap,
          GzPhoneField(
            label: l.hotelProviderProfilePhone,
            value: form.phone,
            onChange: (n, _) => onChanged(form.copyWith(phone: n)),
            error: tried && missing.phone ? l.hotelProviderPhoneError : null,
            validateOnBlur: false,
          ),
          gap,
          if (account == null) ...[
            GzTextField(
              label: l.hotelProviderFormEmail,
              dir: GzFieldDir.ltr,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const ['email'],
              value: form.email,
              onValueChange: (v) => onChanged(form.copyWith(email: v)),
              error: tried && missing.email ? l.hotelProviderFormEmailError : null,
            ),
            gap,
          ],
          GzTextArea(
            label: l.hotelProviderFormAbout,
            rows: 3,
            maxLength: kAboutMax,
            value: form.about,
            onValueChange: (v) => onChanged(form.copyWith(about: v)),
            error: tried && missing.about ? required : null,
          ),
          gap,
          GzTextField(
            label: l.hotelProviderFormLicence,
            optional: true,
            dir: GzFieldDir.ltr,
            maxLength: 40,
            value: form.licence,
            onValueChange: (v) => onChanged(form.copyWith(licence: v)),
          ),
        ],
      ),
    );
  }
}
