import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/services.dart' show TextInputAction, TextInputType;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show ClientSession, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingFor;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_fields.dart';
import 'widgets/booking_info.dart';
import 'widgets/booking_layout.dart';
import 'widgets/step_scaffold.dart';

/// CL-BOOK-04 Your details (step 4 of 5). Covers CA-BOOK-07, CA-BOOK-08, CA-AUTH-05, CA-AUTH-06, CA-AUTH-10.
///
/// Fields with one-word labels and no helpers. Who the booking is for is a two-glyph switch, the relation a row of glyph chips, the common
/// special requests glyph chips whose words are accessible names, and who sees the phone is one sentence behind a "Privacy" row. A request
/// cannot be sent without a verified phone: a person signed in by WhatsApp arrives verified, a changed number is verified by a code sheet.
/// One primary action: Continue (errors appear on tap, blameless and specific).
class ClBook04Screen extends ConsumerStatefulWidget {
  const ClBook04Screen({super.key});

  @override
  ConsumerState<ClBook04Screen> createState() => _ClBook04State();
}

class _ClBook04State extends ConsumerState<ClBook04Screen> {
  bool _showErrors = false;
  final _form = GlobalKey<_DetailsFormState>();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(bookingFlowProvider);
    final flow = keepStale(async).value;
    void retry() => ref.invalidate(bookingFlowProvider);
    final failed = async.hasError && flow == null;
    return BookingStepScaffold(
      step: 4,
      venueName: flow == null ? '' : context.bi(flow.venue.name),
      title: l10n.clientBookingDetailsTitle,
      showBar: !failed,
      action: failed
          ? null
          : GzActionBarAction(
              label: l10n.commonActionContinue,
              loading: flow == null,
              onPressed: () => setState(() => _showErrors = _form.currentState?.next(_showErrors) ?? false),
            ),
      children: [
        BookingAsync<FlowModel>(
          value: async,
          onRetry: retry,
          loading: const StepSection(
            gap: GzSpace.s5,
            children: [
              GzSkeleton(blockSize: 76),
              GzSkeleton(blockSize: 76),
              GzSkeleton(blockSize: 76),
              GzSkeleton(blockSize: 44),
              GzSkeleton(blockSize: 96),
            ],
          ),
          data: (flow) => _DetailsForm(key: _form, flow: flow, showErrors: _showErrors),
        ),
      ],
    );
  }
}

class _DetailsForm extends ConsumerStatefulWidget {
  const _DetailsForm({required this.flow, required this.showErrors, super.key});

  final FlowModel flow;
  final bool showErrors;

  @override
  ConsumerState<_DetailsForm> createState() => _DetailsFormState();
}

class _DetailsFormState extends ConsumerState<_DetailsForm> {
  late String _name;
  late String _phone; // national digits
  late String _email;
  late String _requests;
  late bool _forOther;
  late String _otherName;
  late BookingFor _relation;
  bool _errors = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(effectiveBookingDraftProvider);
    final session = ref.read(sessionProvider);
    final user = session is ClientSession ? session.user : null;
    final f = ref.read(gzFormatProvider);
    final local = ref.read(bookingFlowLocalProvider);
    _name = draft.personal.name.isNotEmpty ? draft.personal.name : (user?.name ?? '');
    _phone = f.normalizePhone(draft.personal.phone.isNotEmpty ? draft.personal.phone : (user?.phone ?? ''));
    _email = draft.personal.email.isNotEmpty ? draft.personal.email : (user?.email ?? '');
    _requests = draft.requests;
    _forOther = local.forOther;
    _otherName = local.otherName;
    _relation = local.relation;
  }

  String get _signedPhone {
    final s = ref.read(sessionProvider);
    return s is ClientSession && s.phoneVerified ? ref.read(gzFormatProvider).normalizePhone(s.user.phone) : '';
  }

  bool get _verified {
    final f = ref.read(gzFormatProvider);
    final v = ref.read(bookingFlowLocalProvider).verifiedPhone;
    return f.isValidPhone(_phone) && (_phone == _signedPhone || (v != null && _phone == f.normalizePhone(v)));
  }

  void _save({String? name, String? phone, String? email, String? requests, BookingFor? relation}) {
    final f = ref.read(gzFormatProvider);
    patchBookingDraft(
      ref,
      (d) => d.copyWith(
        personal: d.personal.copyWith(name: name, phone: phone == null ? null : (f.e164(phone) ?? phone), email: email, bookingFor: relation),
        requests: requests,
      ),
    );
  }

  void _openVerify() {
    final f = ref.read(gzFormatProvider);
    final phone = _phone;
    context.gzNav.openSheet(
      'CL-AUTH-02',
      options: GzSheetOptions(
        params: const <String, Object?>{'presentation': 'sheet', 'reason': 'send-request'},
        onClose: () => ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(verifiedPhone: f.e164(phone) ?? phone)),
      ),
    );
  }

  /// The Continue tap: returns whether the errors are now showing.
  bool next(bool _) {
    final f = ref.read(gzFormatProvider);
    final phoneValid = f.isValidPhone(_phone);
    final bad = _name.trim().isEmpty || !phoneValid || (_forOther && _otherName.trim().isEmpty);
    if (bad) {
      setState(() => _errors = true);
      return true;
    }
    ref.read(bookingFlowLocalProvider.notifier).update((l) => l.copyWith(forOther: _forOther, otherName: _otherName.trim(), relation: _relation));
    patchBookingDraft(
      ref,
      (d) => d.copyWith(
        step: BookingStep.review,
        personal: d.personal.copyWith(
          name: _name.trim(),
          phone: f.e164(_phone) ?? _phone,
          email: _email.trim(),
          bookingFor: _forOther ? _relation : d.personal.bookingFor,
        ),
        requests: _requests.trim(),
      ),
    );
    if (!_verified) {
      _openVerify();
    } else {
      context.gzNav.push('CL-BOOK-05');
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final c = context.gz.colors;
    final flow = widget.flow;
    ref.watch(bookingFlowLocalProvider); // the verified phone redraws the status
    final phoneValid = f.isValidPhone(_phone);
    final showErrors = _errors || widget.showErrors;
    final nameError = showErrors && _name.trim().isEmpty ? l10n.clientBookingNameError : null;
    final phoneError = showErrors && !phoneValid ? f.digits(l10n.clientBookingPhoneDigits(8)) : null;
    final otherError = showErrors && _forOther && _otherName.trim().isEmpty ? l10n.clientBookingNameError : null;
    final verified = _verified;
    final kosha = l10n.clientBookingSuggestKosha(f.time('${flow.date}T12:00'));
    final suggestions = <(String, IconData, String, String)>[
      ('photographer', GzIcons.camera, l10n.clientBookingSuggestPhotographerShort, l10n.clientBookingSuggestPhotographer),
      ('kosha', GzIcons.armchair, l10n.clientBookingSuggestKoshaShort, kosha),
      ('wheelchair', GzIcons.accessible, l10n.clientBookingSuggestWheelchairShort, l10n.clientBookingSuggestWheelchair),
    ];
    final relations = <BookingFor, (IconData, String)>{
      BookingFor.bride: (GzIcons.dress, l10n.clientBookingRelationBride),
      BookingFor.groom: (GzIcons.groom, l10n.clientBookingRelationGroom),
      BookingFor.family: (GzIcons.team, l10n.clientBookingRelationFamily),
      BookingFor.planner: (GzIcons.checklist, l10n.clientBookingRelationPlanner),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StepSection(
          gap: GzSpace.s5,
          label: l10n.clientBookingReviewContact,
          children: [
            GzTextField(
              label: l10n.clientBookingNameLabel,
              defaultValue: _name,
              onValueChange: (v) {
                setState(() => _name = v);
                _save(name: v);
              },
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              error: nameError,
            ),
            BookingGap(
              gap: GzSpace.s3,
              children: [
                GzPhoneField(
                  label: l10n.clientBookingPhoneLabel,
                  defaultValue: _phone,
                  validateOnBlur: false,
                  error: phoneError,
                  onChange: (national, info) {
                    setState(() => _phone = national);
                    _save(phone: national);
                  },
                ),
                if (phoneValid)
                  verified
                      ? Semantics(
                          liveRegion: true,
                          child: Row(
                            children: [
                              GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSuccess),
                              const SizedBox(width: GzSpace.s2),
                              GzText(l10n.clientBookingPhoneVerified, role: GzTextRole.bodyS, color: c.textSuccess),
                            ],
                          ),
                        )
                      : Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: GzButton(
                            label: l10n.clientBookingPhoneVerify,
                            variant: GzButtonVariant.secondary,
                            iconStart: GzIcons.whatsapp,
                            onPressed: _openVerify,
                          ),
                        ),
              ],
            ),
            GzTextField(
              label: l10n.clientBookingEmailLabel,
              defaultValue: _email,
              dir: GzFieldDir.ltr,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onValueChange: (v) {
                setState(() => _email = v);
                _save(email: v);
              },
            ),
          ],
        ),
        StepSection(
          gap: GzSpace.s5,
          label: l10n.clientBookingForLabel,
          children: [
            GzIconSegmented<bool>(
              label: l10n.clientBookingForLabel,
              value: _forOther,
              onChanged: (v) => setState(() => _forOther = v),
              options: [
                GzIconSegmentedOption<bool>(value: false, icon: GzIcons.user, label: l10n.clientBookingForSelf),
                GzIconSegmentedOption<bool>(value: true, icon: GzIcons.userPlus, label: l10n.clientBookingForOther),
              ],
            ),
            if (_forOther) ...[
              GzTextField(
                label: l10n.clientBookingForNameLabel,
                defaultValue: _otherName,
                onValueChange: (v) => setState(() => _otherName = v),
                error: otherError,
              ),
              BookingGlyphChips<BookingFor>(
                label: l10n.clientBookingForRelationLabel,
                options: [for (final e in relations.entries) BookingGlyphOption<BookingFor>(value: e.key, label: e.value.$2, icon: e.value.$1)],
                selected: [_relation],
                onSelect: (v) {
                  setState(() => _relation = v);
                  _save(relation: v);
                },
              ),
            ],
          ],
        ),
        StepSection(
          gap: GzSpace.s5,
          label: l10n.clientBookingRequestsLabel,
          children: [
            GzTextArea(
              label: l10n.clientBookingRequestsLabel,
              defaultValue: _requests,
              rows: 3,
              onValueChange: (v) {
                setState(() => _requests = v);
                _save(requests: v);
              },
            ),
            BookingGlyphChips<String>(
              label: l10n.clientBookingRequestsSuggestions,
              options: [for (final s in suggestions) BookingGlyphOption<String>(value: s.$1, label: s.$3, icon: s.$2, semantic: s.$4)],
              selected: [
                for (final s in suggestions)
                  if (_requests.contains(s.$4)) s.$1,
              ],
              onSelect: (v) {
                final s = suggestions.firstWhere((x) => x.$1 == v);
                if (_requests.contains(s.$4)) return;
                final text = _requests.trim().isEmpty ? s.$4 : '${_requests.trim()}\n${s.$4}';
                setState(() => _requests = text);
                _save(requests: text);
              },
            ),
          ],
        ),
        StepSection(
          children: [
            BookingAsideInfo(
              icon: GzIcons.lock,
              word: l10n.clientBookingPrivacyWord,
              title: l10n.clientBookingPrivacyWord,
              paragraphs: [l10n.clientBookingPrivacy(context.bi(flow.venue.name))],
            ),
          ],
        ),
      ],
    );
  }
}
