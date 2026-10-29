// HL-ACCS-04 Account status (web `HL-ACCS-04.tsx`): a specific, calm screen for every moment the app cannot open normally. One drawing per
// variant, a title of one or two words, the venue as a quiet line, the sentence behind an info glyph, and exactly one next step.
// Partner application (PA-ACC-07, ADR 0038): a service provider or a private hall waits here after sending the form of HL-PROV-01. Three variants
// follow the application of the account (not the route param, which only names the frame): in review (the wait), not approved (the staff note and
// "Edit and resubmit" back to the prefilled form) and approved (Continue to Today). Staff decide in the Super Admin web (out of scope here).
// Requirements: HA-AUTH-02, HA-AUTH-04, PA-ACC-07.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show ApplicationStatus, PartnerApplication;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import 'widgets/access_support.dart';

enum StatusVariant { underReview, applicationReview, applicationRejected, applicationApproved, suspended, deactivated, sessionRevoked, noAccess }

StatusVariant parseStatusVariant(Object? v) => switch (v) {
  'application-review' => StatusVariant.applicationReview,
  'application-rejected' => StatusVariant.applicationRejected,
  'application-approved' => StatusVariant.applicationApproved,
  'suspended' => StatusVariant.suspended,
  'deactivated' => StatusVariant.deactivated,
  'session-revoked' => StatusVariant.sessionRevoked,
  'no-access' => StatusVariant.noAccess,
  _ => StatusVariant.underReview,
};

/// The variant an application dictates, null while there is none (then the route param names it).
StatusVariant? variantOfApplication(PartnerApplication? a) => switch (a?.status) {
  ApplicationStatus.pending => StatusVariant.applicationReview,
  ApplicationStatus.rejected => StatusVariant.applicationRejected,
  ApplicationStatus.accepted => StatusVariant.applicationApproved,
  _ => null,
};

class HlAccs04Screen extends ConsumerWidget {
  const HlAccs04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final asked = parseStatusVariant(nav.params['variant']);
    final isApplicationFrame = asked == StatusVariant.applicationReview || asked == StatusVariant.applicationRejected || asked == StatusVariant.applicationApproved;
    final application = ref.watch(partnerApplicationProvider).value;
    // an application variant follows the data (a decision changes it under the screen); every other variant is what the route asked for
    final variant = isApplicationFrame ? (variantOfApplication(application) ?? asked) : asked;
    final isApplication = variant == StatusVariant.applicationReview || variant == StatusVariant.applicationRejected || variant == StatusVariant.applicationApproved;
    final provider = nav.params['account'] == 'provider' || application?.accountType.value == 'service_provider';
    final fullScreen = variant != StatusVariant.noAccess;
    final venueVariant = variant == StatusVariant.underReview ||
        variant == StatusVariant.suspended ||
        variant == StatusVariant.deactivated ||
        variant == StatusVariant.applicationReview ||
        variant == StatusVariant.applicationApproved;
    final lang = context.gz.locale.languageCode;
    final session = ref.watch(sessionProvider);
    String? name;
    if (isApplication) {
      name = application?.name.of(lang);
    } else if (venueVariant) {
      if (session is PartnerSession && session.accountName != null) {
        name = session.accountName!.of(lang);
      } else if (!provider) {
        name = ref.watch(_venueNameProvider(lang)).value;
      }
    }
    if (variant == StatusVariant.applicationApproved || variant == StatusVariant.applicationReview) name ??= (session is PartnerSession ? session.accountName?.of(lang) : null);

    final title = switch (variant) {
      StatusVariant.underReview => l.hotelAccessStatusUnderReviewTitle,
      StatusVariant.applicationReview => l.hotelAccessStatusApplicationTitle,
      StatusVariant.applicationRejected => l.hotelAccessStatusRejectedTitle,
      StatusVariant.applicationApproved => l.hotelAccessStatusApprovedTitle,
      StatusVariant.suspended => l.hotelAccessStatusSuspendedTitle,
      StatusVariant.deactivated => l.hotelAccessStatusDeactivatedTitle,
      _ => l.hotelAccessStatusRevokedTitle,
    };
    final detail = switch (variant) {
      StatusVariant.underReview => l.hotelAccessStatusUnderReviewBody,
      StatusVariant.applicationReview => l.hotelAccessStatusApplicationBody,
      StatusVariant.applicationRejected || StatusVariant.applicationApproved => null,
      StatusVariant.suspended => l.hotelAccessStatusSuspendedBody,
      StatusVariant.deactivated => l.hotelAccessStatusDeactivatedBody,
      _ => l.hotelAccessStatusRevokedBody,
    };
    final art = switch (variant) {
      StatusVariant.underReview || StatusVariant.applicationReview => GzIllustrationName.hourglass,
      StatusVariant.suspended || StatusVariant.applicationRejected => GzIllustrationName.warning,
      StatusVariant.applicationApproved => GzIllustrationName.seal,
      StatusVariant.deactivated => GzIllustrationName.key,
      StatusVariant.sessionRevoked => GzIllustrationName.doorway,
      StatusVariant.noAccess => GzIllustrationName.shield,
    };

    Future<void> signOut() async {
      await ref.read(sessionProvider.notifier).signOut();
      nav.reset('HL-ACCS-01');
    }

    final account = isApplication && application != null ? (application.accountType.value == 'venue' ? 'hotel' : 'provider') : (nav.params['account'] ?? (provider ? 'provider' : 'hotel'));
    final GzActionBarAction primary = switch (variant) {
      StatusVariant.underReview ||
      StatusVariant.applicationReview ||
      StatusVariant.suspended => GzActionBarAction(label: l.hotelAccessSupportAction, onPressed: accessSupportAction(context, ref)),
      StatusVariant.applicationRejected => GzActionBarAction(
        label: l.hotelAccessStatusEditResubmit,
        iconEnd: GzIcons.chevronRight,
        onPressed: () => nav.push('HL-PROV-01', params: {'resubmit': true, 'account': account}),
      ),
      StatusVariant.applicationApproved => GzActionBarAction(
        label: l.commonActionContinue,
        iconEnd: GzIcons.chevronRight,
        onPressed: () => nav.reset('HL-TODY-01', params: {'account': account}),
      ),
      StatusVariant.deactivated => GzActionBarAction(label: l.hotelAccessAdminAction, onPressed: accessContactAdminAction(context)),
      StatusVariant.sessionRevoked => GzActionBarAction(label: l.hotelAccessSigninSubmit, onPressed: signOut),
      StatusVariant.noAccess => GzActionBarAction(label: l.commonLabelToday, iconEnd: GzIcons.arrowRight, onPressed: () => nav.reset('HL-TODY-01')),
    };
    final quiet = fullScreen && variant != StatusVariant.sessionRevoked && variant != StatusVariant.applicationApproved
        ? <Widget>[GzButton(label: l.hotelAccessStatusSignOut, variant: GzButtonVariant.tertiary, size: GzButtonSize.sm, onPressed: signOut)]
        : const <Widget>[];

    // the staff note of a rejection (bilingual, in the language of the app)
    final note = variant == StatusVariant.applicationRejected ? application?.rejectionReason?.of(lang) : null;
    final facts = note == null || note.trim().isEmpty
        ? null
        : Semantics(container: true, label: l.hotelAccessStatusReasonsLabel, child: GzText(note, role: GzTextRole.body, color: context.gz.colors.textPrimary, textAlign: TextAlign.center));

    final safeTop = MediaQuery.paddingOf(context).top;
    return GzScreen(
      top: fullScreen ? null : const GzTopBar(),
      bottom: GzActionBar(
        action: primary,
        // the one gold action, then quiet links under it (the shared bar takes a widget under the button)
        noteWidget: quiet.isEmpty ? null : Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: GzSpace.s6, children: quiet),
      ),
      fixed: true,
      child: Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: fullScreen ? safeTop : GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (fullScreen)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzWordmark(size: GzWordmarkSize.md, script: context.gz.isAr ? GzWordmarkScript.arabic : GzWordmarkScript.latin),
                ),
              ),
            const SizedBox(height: GzSpace.s4),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(top: variant == StatusVariant.noAccess ? 0 : GzSpace.s12),
                child: variant == StatusVariant.noAccess
                    ? GzErrorState(kind: GzErrorKind.noAccess, body: l.hotelAccessStatusNoAccessBody, fill: true)
                    : GzEmptyState(
                        illustration: art,
                        title: title,
                        body: venueVariant ? name : null,
                        facts: facts,
                        detail: detail,
                        detailTitle: title,
                        size: GzIllustrationSize.hero,
                        flush: true,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The hero venue's name, for a status screen opened without a session (the story default).
final _venueNameProvider = FutureProvider.autoDispose.family<String, String>((ref, lang) async {
  final detail = await ref.read(venuesRepositoryProvider).getVenue(venueId: 'V01');
  return detail.venue.name.of(lang);
});
