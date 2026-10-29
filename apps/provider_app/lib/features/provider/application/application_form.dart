// The application form of HL-PROV-01 (web `provider/_components/application.ts`, PA-ACC-07, PA-ACC-08, OQ-R2-03): a service provider or a private
// hall describes its business; Ghazal staff accept or reject. The form is a plain immutable value the screen edits; `missingOf` says which fields stop a
// submit (the same rules as the web), `toChooseInput` / `toResubmitInput` are the two bodies the API takes (first application, edit and resubmit).
import 'package:flutter/foundation.dart';
import 'package:ghazal_core/ghazal_core.dart' show PhoneKw;
import 'package:ghazal_domain/ghazal_domain.dart';

/// A hotel or a hall chain is onboarded by Ghazal as before (ADR 0038 D3): only these two apply from the app.
enum ApplicantKind { serviceProvider, privateHall }

const int kMaxCategories = 3;
const int kAboutMax = 240;

/// Which fields stop a submit. A provider needs a category or an "Other" note; a private hall needs neither.
@immutable
final class ApplicationMissing {
  const ApplicationMissing({
    required this.nameAr,
    required this.nameEn,
    required this.cats,
    required this.gov,
    required this.contact,
    required this.phone,
    required this.email,
    required this.about,
  });

  final bool nameAr;
  final bool nameEn;
  final bool cats;
  final bool gov;
  final bool contact;
  final bool phone;
  final bool email;
  final bool about;

  bool get any => nameAr || nameEn || cats || gov || contact || phone || email || about;
}

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

@immutable
final class ApplicationForm {
  const ApplicationForm({
    this.kind = ApplicantKind.serviceProvider,
    this.nameAr = '',
    this.nameEn = '',
    this.cats = const <ServiceCategoryId>[],
    this.otherNote = '',
    this.gov,
    this.contact = '',
    this.phone = '',
    this.email = '',
    this.about = '',
    this.licence = '',
  });

  /// The form of an application already sent (a rejected one comes back prefilled for "Edit and resubmit").
  factory ApplicationForm.fromApplication(PartnerApplication a) => ApplicationForm(
    kind: a.accountType == PartnerAccountType.venue ? ApplicantKind.privateHall : ApplicantKind.serviceProvider,
    nameAr: a.name.ar ?? '',
    nameEn: a.name.en ?? '',
    cats: a.categoryIds,
    otherNote: a.otherCategoryNote ?? '',
    gov: a.governorateId,
    contact: a.contactName,
    phone: PhoneKw.normalizeInput(a.phone),
    email: a.email,
    about: a.description,
    licence: a.licenceRef ?? '',
  );

  final ApplicantKind kind;
  final String nameAr;
  final String nameEn;

  /// Up to three registered categories (providers only).
  final List<ServiceCategoryId> cats;

  /// The open "Other / not in the list" note: staff add the category or reject (PA-ACC-08).
  final String otherNote;

  /// A governorate id of the reference data (`GET /areas`).
  final String? gov;
  final String contact;

  /// The 8 national digits after +965.
  final String phone;
  final String email;
  final String about;

  /// Optional commercial licence reference (OQ-R2-03).
  final String licence;

  bool get isHall => kind == ApplicantKind.privateHall;

  ApplicationForm copyWith({
    ApplicantKind? kind,
    String? nameAr,
    String? nameEn,
    List<ServiceCategoryId>? cats,
    String? otherNote,
    String? gov,
    String? contact,
    String? phone,
    String? email,
    String? about,
    String? licence,
  }) => ApplicationForm(
    kind: kind ?? this.kind,
    nameAr: nameAr ?? this.nameAr,
    nameEn: nameEn ?? this.nameEn,
    cats: cats ?? this.cats,
    otherNote: otherNote ?? this.otherNote,
    gov: gov ?? this.gov,
    contact: contact ?? this.contact,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    about: about ?? this.about,
    licence: licence ?? this.licence,
  );

  ApplicationMissing get missing => ApplicationMissing(
    nameAr: nameAr.trim().isEmpty,
    nameEn: nameEn.trim().isEmpty,
    cats: kind == ApplicantKind.serviceProvider && cats.isEmpty && otherNote.trim().isEmpty,
    gov: gov == null,
    contact: contact.trim().isEmpty,
    phone: phone.length != 8,
    email: !_email.hasMatch(email.trim()),
    about: about.trim().isEmpty,
  );

  bool get isComplete => !missing.any;

  /// The business name in the language of the viewer, falling back to the other one.
  String nameFor(String lang) {
    final first = lang == 'ar' ? nameAr : nameEn;
    return (first.trim().isEmpty ? (lang == 'ar' ? nameEn : nameAr) : first).trim();
  }

  PartnerAccountType get accountType => isHall ? PartnerAccountType.venue : PartnerAccountType.serviceProvider;

  List<ServiceCategoryId>? get _cats => isHall ? null : cats;
  String? get _other => isHall || otherNote.trim().isEmpty ? null : otherNote.trim();
  String? get _licence => licence.trim().isEmpty ? null : licence.trim();
  LocalizedText get _name => LocalizedText(en: nameEn.trim(), ar: nameAr.trim());
  String get _e164 => PhoneKw.toE164(phone) ?? phone;

  /// The body of the first application (`POST /partner/account-type`).
  ChooseAccountTypeInput toChooseInput() => ChooseAccountTypeInput(
    accountType: accountType,
    name: _name,
    categoryIds: _cats,
    otherCategoryNote: _other,
    governorateId: gov,
    contactName: contact.trim(),
    phone: _e164,
    email: email.trim(),
    description: about.trim(),
    licenceRef: _licence,
  );

  /// The body of the public application (`POST /partner/applications`, signed out): the account the applicant creates (the form's own email
  /// is the sign-in name and the contact email) and the business information.
  SubmitPartnerApplicationInput toSubmitInput({required String password, required WireLang locale}) => SubmitPartnerApplicationInput(
    account: PartnerApplicantAccount(email: email.trim(), password: password, locale: locale),
    accountType: accountType,
    application: toResubmitInput(),
  );

  /// The body of an edit of a rejected application (`PUT /partner/application`).
  PartnerApplicationInput toResubmitInput() => PartnerApplicationInput(
    name: _name,
    categoryIds: _cats,
    otherCategoryNote: _other,
    governorateId: gov!,
    contactName: contact.trim(),
    phone: _e164,
    email: email.trim(),
    description: about.trim(),
    licenceRef: _licence,
  );

  @override
  bool operator ==(Object other) =>
      other is ApplicationForm &&
      other.kind == kind &&
      other.nameAr == nameAr &&
      other.nameEn == nameEn &&
      listEquals(other.cats, cats) &&
      other.otherNote == otherNote &&
      other.gov == gov &&
      other.contact == contact &&
      other.phone == phone &&
      other.email == email &&
      other.about == about &&
      other.licence == licence;

  @override
  int get hashCode => Object.hash(kind, nameAr, nameEn, Object.hashAll(cats), otherNote, gov, contact, phone, email, about, licence);
}
