// HL-ACCS-04 Account status (web `HL-ACCS-04.tsx`): a specific, calm screen for every moment the app cannot open normally. One drawing per
// variant, a title of one or two words, the venue as a quiet line, the sentence behind an info glyph, and exactly one next step.
// Requirements: HA-AUTH-02, HA-AUTH-04.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import 'widgets/access_support.dart';

enum StatusVariant { underReview, suspended, deactivated, sessionRevoked, noAccess }

StatusVariant parseStatusVariant(Object? v) => switch (v) {
  'suspended' => StatusVariant.suspended,
  'deactivated' => StatusVariant.deactivated,
  'session-revoked' => StatusVariant.sessionRevoked,
  'no-access' => StatusVariant.noAccess,
  _ => StatusVariant.underReview,
};

class HlAccs04Screen extends ConsumerWidget {
  const HlAccs04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final variant = parseStatusVariant(nav.params['variant']);
    final provider = nav.params['account'] == 'provider';
    final fullScreen = variant != StatusVariant.noAccess;
    final venueVariant = variant == StatusVariant.underReview || variant == StatusVariant.suspended || variant == StatusVariant.deactivated;
    final lang = context.gz.locale.languageCode;
    final session = ref.watch(sessionProvider);
    String? name;
    if (venueVariant) {
      if (session is PartnerSession && session.accountName != null) {
        name = session.accountName!.of(lang);
      } else if (!provider) {
        name = ref.watch(_venueNameProvider(lang)).value;
      }
    }

    final title = switch (variant) {
      StatusVariant.underReview => l.hotelAccessStatusUnderReviewTitle,
      StatusVariant.suspended => l.hotelAccessStatusSuspendedTitle,
      StatusVariant.deactivated => l.hotelAccessStatusDeactivatedTitle,
      _ => l.hotelAccessStatusRevokedTitle,
    };
    final detail = switch (variant) {
      StatusVariant.underReview =>
        provider ? '${l.hotelAccessStatusUnderReviewBody}\n\n${l.hotelAccessStatusUnderReviewProviderNote}' : l.hotelAccessStatusUnderReviewBody,
      StatusVariant.suspended => l.hotelAccessStatusSuspendedBody,
      StatusVariant.deactivated => l.hotelAccessStatusDeactivatedBody,
      _ => l.hotelAccessStatusRevokedBody,
    };
    final art = switch (variant) {
      StatusVariant.underReview => GzIllustrationName.hourglass,
      StatusVariant.suspended => GzIllustrationName.warning,
      StatusVariant.deactivated => GzIllustrationName.key,
      StatusVariant.sessionRevoked => GzIllustrationName.doorway,
      StatusVariant.noAccess => GzIllustrationName.shield,
    };

    Future<void> signOut() async {
      await ref.read(sessionProvider.notifier).signOut();
      nav.reset('HL-ACCS-01');
    }

    final GzActionBarAction primary = switch (variant) {
      StatusVariant.underReview ||
      StatusVariant.suspended => GzActionBarAction(label: l.hotelAccessSupportAction, onPressed: accessSupportAction(context, ref)),
      StatusVariant.deactivated => GzActionBarAction(label: l.hotelAccessAdminAction, onPressed: accessContactAdminAction(context)),
      StatusVariant.sessionRevoked => GzActionBarAction(label: l.hotelAccessSigninSubmit, onPressed: signOut),
      StatusVariant.noAccess => GzActionBarAction(label: l.commonLabelToday, iconEnd: GzIcons.arrowRight, onPressed: () => nav.reset('HL-TODY-01')),
    };
    final quiet = fullScreen && variant != StatusVariant.sessionRevoked
        ? <Widget>[GzButton(label: l.hotelAccessStatusSignOut, variant: GzButtonVariant.tertiary, size: GzButtonSize.sm, onPressed: signOut)]
        : const <Widget>[];

    final safeTop = MediaQuery.paddingOf(context).top;
    return GzScreen(
      top: fullScreen ? null : const GzTopBar(),
      bottom: _StatusBottom(action: primary, quiet: quiet),
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
                        body: name,
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

/// The pinned bar of the status screens: the one gold action, then quiet links (the system action bar takes a sentence under the button, not links).
class _StatusBottom extends StatelessWidget {
  const _StatusBottom({required this.action, required this.quiet});

  final GzActionBarAction action;
  final List<Widget> quiet;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: c.surfaceCanvas,
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s3 + bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzButton(label: action.label, onPressed: action.onPressed, iconEnd: action.iconEnd, fullWidth: true),
                if (quiet.isNotEmpty) ...[
                  const SizedBox(height: GzSpace.s2),
                  Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.center, spacing: GzSpace.s6, children: quiet),
                ],
              ],
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            top: 0,
            height: GzStroke.hair,
            child: ColoredBox(color: c.borderHairline),
          ),
        ],
      ),
    );
  }
}
