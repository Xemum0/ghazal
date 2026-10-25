// HL-PROV-01 Choose your account type (web `HL-PROV-01.tsx`): first-run onboarding of a new partner. Hotel or wedding hall, or Service
// provider; then the profile (business name in Arabic and English, categories for a provider, venue type and area for a venue, contact phone)
// and a submit that puts the account under review. Fee exemption is never chosen here: Ghazal sets it. Requirements: PA-ACC-01..03, PA-REV-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/provider_actions.dart';
import 'widgets/account_cards.dart';
import 'widgets/profile_form.dart';

enum _Step { choose, profile, submitted }

class HlProv01Screen extends ConsumerStatefulWidget {
  const HlProv01Screen({super.key});

  @override
  ConsumerState<HlProv01Screen> createState() => _HlProv01State();
}

class _HlProv01State extends ConsumerState<HlProv01Screen> {
  PartnerAccountType? _kind;
  _Step _step = _Step.choose;
  ProfileDraft _p = const ProfileDraft();
  bool _tried = false;
  bool _failed = false;

  bool get _isVenue => _kind == PartnerAccountType.venue;

  Future<void> _submit() async {
    setState(() => _tried = true);
    if (_p.incomplete(venue: _isVenue)) return;
    final nav = GzNavigatorScope.of(context);
    final g = context.gzL10n;
    final r = await ref.read(listingActionsProvider.notifier).chooseAccountType(_kind!, LocalizedText(en: _p.nameEn.trim(), ar: _p.nameAr.trim()));
    if (!mounted) return;
    switch (r) {
      case ActionSuccess():
        setState(() {
          _step = _Step.submitted;
          _failed = false;
        });
      case ActionFailure(:final problem):
        setState(() => _failed = true);
        nav.toast(GzToastSpec(message: gzProblemMessage(g, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
  }

  static const EdgeInsetsDirectional _pad = EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8);

  Widget _choose(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzText(l.hotelProviderChooseTitle, role: GzTextRole.uiXl, color: context.gz.colors.textStrong),
          const SizedBox(height: GzSpace.s5),
          AccountCard(
            icon: GzIcons.hotel,
            title: l.hotelProviderTypeHotelTitle,
            facts: const [GzIcons.calendar, GzIcons.chat, GzIcons.ticket],
            selected: _kind == PartnerAccountType.venue,
            onTap: () => setState(() => _kind = PartnerAccountType.venue),
          ),
          const SizedBox(height: GzSpace.s4),
          AccountCard(
            icon: GzIcons.megaphone,
            title: l.hotelProviderTypeProviderTitle,
            facts: const [GzIcons.catering, GzIcons.flower, GzIcons.camera],
            selected: _kind == PartnerAccountType.serviceProvider,
            onTap: () => setState(() => _kind = PartnerAccountType.serviceProvider),
          ),
        ],
      ),
    );
  }

  Widget _submitted(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final ar = context.gz.locale.languageCode == 'ar';
    final first = ar ? _p.nameAr : _p.nameEn;
    final name = (first.trim().isEmpty ? (ar ? _p.nameEn : _p.nameAr) : first).trim();
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: GzIllustration(GzIllustrationName.partnerReview, size: GzIllustrationSize.hero)),
          const SizedBox(height: GzSpace.s3),
          GzText(l.hotelProviderSubmittedTitle, role: GzTextRole.uiXl, color: c.textStrong),
          const SizedBox(height: GzSpace.s5),
          Row(
            children: [
              GzAvatar(name: name, voice: GzAvatarVoice.sans),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzText(name, role: GzTextRole.title, color: c.textStrong)),
              GzIcon(_isVenue ? GzIcons.hotel : GzIcons.megaphone, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final busy = ref.watch(listingActionsProvider).isBusy;

    final GzTopBar top;
    final GzActionBar bottom;
    final Widget body;
    switch (_step) {
      case _Step.choose:
        top = const GzTopBar();
        bottom = GzActionBar(
          action: GzActionBarAction(
            label: l.hotelProviderContinue,
            iconEnd: GzIcons.chevronRight,
            onPressed: () => setState(() => _step = _Step.profile),
            disabled: _kind == null,
            reason: _kind == null ? l.hotelProviderChooseReason : null,
          ),
        );
        body = _choose(context);
      case _Step.submitted:
        top = GzTopBar(title: l.hotelProviderSubmittedBar, back: GzTopBarBack.hide);
        bottom = GzActionBar(
          action: _isVenue
              ? GzActionBarAction(label: l.hotelProviderSubmittedToday, iconEnd: GzIcons.chevronRight, onPressed: () => nav.reset('HL-TODY-01'))
              : GzActionBarAction(label: l.hotelProviderSubmittedFirst, iconEnd: GzIcons.chevronRight, onPressed: () => nav.push('HL-PROV-03', params: {'account': 'provider'})),
          noteWidget: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s6,
            children: [
              GzButton(
                label: l.hotelProviderSubmittedStatus,
                variant: GzButtonVariant.tertiary,
                onPressed: () => nav.push('HL-ACCS-04', params: {'variant': 'under-review', 'account': _isVenue ? 'hotel' : 'provider'}),
              ),
              if (!_isVenue) GzButton(label: l.hotelProviderSubmittedToday, variant: GzButtonVariant.tertiary, onPressed: () => nav.reset('HL-TODY-01')),
            ],
          ),
        );
        body = _submitted(context);
      case _Step.profile:
        top = GzTopBar(title: _isVenue ? l.hotelProviderTypeHotelTitle : l.hotelProviderTypeProviderTitle, onBack: () => setState(() => _step = _Step.choose));
        bottom = GzActionBar(action: GzActionBarAction(label: l.hotelProviderSubmit, iconEnd: GzIcons.check, loading: busy, onPressed: _submit));
        body = ProfileForm(
          venue: _isVenue,
          draft: _p,
          tried: _tried,
          failed: _failed,
          onChanged: (d) => setState(() => _p = d),
          onRetry: () => setState(() => _failed = false),
        );
    }
    return GzScreen(top: top, bottom: bottom, child: body);
  }
}
