// CL-PROF-01 Profile (tab root). Port of CL-PROF-01.tsx. Requirements: CA-PROF-01 .. 05, 07, 10, 11, 12, CA-VCH-06.
// The hub of the Profile tab, text-diet edition (ADR 0034): the monogram and the verified number, one wedding card (rings, the date and the
// days to go as facts), then three quiet lists of one-word rows with a glyph, no group titles and no captions. Counts are figures at the end
// of the row, the request is a status glyph, Receipts shows the KD 2 paid to Ghazal (ADR 0033). Every row goes somewhere. Sign out asks
// first and returns to Home as a guest. A guest sees one doorway card with Sign in, Language, Terms and Privacy.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider, localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show DateMode, WeddingProfile;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../application/profile_activity.dart';
import '../application/profile_identity.dart';
import '../application/profile_state.dart';
import 'widgets/profile_parts.dart';
import 'widgets/profile_sheets.dart';

class ClProf01Screen extends ConsumerWidget {
  const ClProf01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final session = ref.watch(sessionProvider);
    final top = GzTopBar(variant: GzTopBarVariant.largeTitle, title: l.clientProfileHubTitle, back: GzTopBarBack.hide);
    final Widget body = session is ClientSession
        ? GzAsyncView<(ProfileActivity, WeddingProfile?)>(
            value: ref.watch(profileHubProvider),
            loading: const _HubSkeleton(),
            onRetry: () => ref.invalidate(profileHubProvider),
            data: (d) => _SignedIn(activity: d.$1, wedding: d.$2),
          )
        : const _Guest();
    return GzScreen(top: top, child: body);
  }
}

class _HubColumn extends StatelessWidget {
  const _HubColumn({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final f = context.gz.colors;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
          const SizedBox(height: GzSpace.s6),
          Consumer(
            builder: (context, ref, _) => GzText(context.l10n.clientProfileSharedVersion(kProfileAppVersion), role: GzTextRole.figCaption, color: f.textSecondary, textAlign: TextAlign.center, figures: true),
          ),
        ],
      ),
    );
  }
}

class _HubSkeleton extends StatelessWidget {
  const _HubSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.gzL10n.commonStateLoading,
      container: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8, start: GzSpace.gutter, end: GzSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Row(
              children: [
                GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: GzSize.avatarMd),
                SizedBox(width: GzSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [GzSkeleton(inlineSize: 160, blockSize: 28), SizedBox(height: GzSpace.s2), GzSkeleton(inlineSize: 120, blockSize: 20)],
                  ),
                ),
              ],
            ),
            const SizedBox(height: GzSpace.s6),
            const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
            for (final rows in const <int>[5, 4, 3]) ...[
              const SizedBox(height: GzSpace.s6),
              for (var i = 0; i < rows; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64)],
            ],
          ],
        ),
      ),
    );
  }
}

/// The rows every visitor sees: Language, Terms, Privacy.
class _CommonRows {
  static Widget language(BuildContext context, WidgetRef ref) {
    final code = ref.watch(localeProvider).languageCode;
    return GzIconListRow(
      icon: GzIcons.translate,
      title: context.l10n.commonLabelLanguage,
      trailing: Directionality(textDirection: code == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: Text(profileNativeName(context, code), locale: Locale(code))),
      chevron: true,
      onPressed: () => context.gzNav.openLanguageSheet(context),
    );
  }

  static Widget terms(BuildContext context) =>
      GzIconListRow(icon: GzIcons.document, title: context.l10n.clientProfileSharedTerms, chevron: true, onPressed: () => context.gzNav.openLegalSheet(context, LegalKind.terms));

  static Widget privacy(BuildContext context) =>
      GzIconListRow(icon: GzIcons.shieldCheck, title: context.l10n.clientProfileSharedPrivacy, chevron: true, last: true, onPressed: () => context.gzNav.openLegalSheet(context, LegalKind.privacy));
}

class _Guest extends ConsumerWidget {
  const _Guest();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.gz.colors;
    return _HubColumn(
      children: [
        Padding(
          padding: kProfPad,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s6, horizontal: GzSpace.panelPad),
            decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: GzIllustration(GzIllustrationName.doorway, size: GzIllustrationSize.lg)),
                const SizedBox(height: GzSpace.s5),
                GzButton(
                  label: context.l10n.clientProfileSharedSignIn,
                  fullWidth: true,
                  onPressed: () => context.gzNav.openSheet('CL-AUTH-01', options: const GzSheetOptions(params: <String, Object?>{'reason': 'none'})),
                ),
              ],
            ),
          ),
        ),
        Column(children: [_CommonRows.language(context, ref), _CommonRows.terms(context), _CommonRows.privacy(context)]),
      ],
    );
  }
}

class _SignedIn extends ConsumerWidget {
  const _SignedIn({required this.activity, required this.wedding});

  final ProfileActivity activity;
  final WeddingProfile? wedding;

  Widget _count(BuildContext context, int n, String label) {
    if (n <= 0) return const SizedBox.shrink();
    final f = context.gzFormat;
    return Semantics(
      label: '$label ${f.integer(n)}',
      excludeSemantics: true,
      child: GzNum(f.integer(n), role: GzTextRole.figBody, color: context.gz.colors.textSecondary),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final nav = context.gzNav;
    final who = ref.watch(profileIdentityProvider);
    final saved = ref.watch(favouritesProvider).value?.venue.length ?? 0;
    final scheduled = ref.watch(profileDeletionAfterProvider);
    final weddingDate = wedding == null || wedding!.dateMode == DateMode.undecided ? null : wedding!.weddingDate.toString();
    final daysToGo = weddingDate == null ? 0 : f.daysUntil(weddingDate);
    final paidFils = activity.paidFils;
    final paid = paidFils > 0;

    return _HubColumn(
      children: [
        if (who != null)
          Padding(
            padding: kProfPad,
            child: Semantics(
              container: true,
              label: l.clientProfileHubAccount,
              child: Row(
                children: [
                  GzAvatar(name: who.name, initial: who.monogram, size: GzAvatarSize.md),
                  const SizedBox(width: GzSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GzText(who.name, role: GzTextRole.d1, color: c.textStrong, header: true),
                        const SizedBox(height: GzSpace.s1),
                        Row(
                          children: [
                            Flexible(child: GzNum(f.phone(who.phone), role: GzTextRole.figCaption, color: c.textSecondary)),
                            const SizedBox(width: GzSpace.s2),
                            Semantics(label: l.clientProfileHubVerified, image: true, excludeSemantics: true, child: GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (scheduled != null)
          Padding(
            padding: kProfPad,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.panelPad),
              decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
              child: GzIconListRow(
                flush: true,
                last: true,
                icon: GzIcons.calendarX,
                title: l.clientProfileDelScheduledTitle,
                trailing: GzFactChip(icon: GzIcons.calendar, value: f.date(scheduled, DateStyle.dayMonth), label: l.clientProfileDelScheduledTitle),
                chevron: true,
                onPressed: () => nav.push('CL-PROF-06'),
              ),
            ),
          ),
        Padding(
          padding: kProfPad,
          child: Container(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.panelPad),
            decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
            child: GzIconListRow(
              flush: true,
              last: true,
              illustration: GzIllustrationName.rings,
              title: l.clientProfileHubRowWedding,
              facts: weddingDate != null
                  ? GzFactRow(
                      children: [
                        GzFactChip(icon: GzIcons.calendar, value: f.date(weddingDate, DateStyle.dayMonth), label: l.clientProfileWedDate),
                        if (daysToGo > 0) GzFactChip(icon: GzIcons.countdown, value: f.digits(context.gzL10n.commonCountDays(daysToGo)), label: l.clientProfileWedCountdown, tone: GzFactTone.accent),
                      ],
                    )
                  : GzText(context.gzL10n.commonLabelNotDecided, color: c.textSecondary),
              chevron: true,
              onPressed: () => nav.push('CL-PROF-02'),
            ),
          ),
        ),
        Column(
          children: [
            GzIconListRow(
              icon: GzIcons.calendarCheck,
              title: l.clientProfileHubRowBookings,
              trailing: activity.glyph == null ? null : GzStatusIcon(status: activity.glyph!),
              chevron: true,
              onPressed: () => nav.push('CL-BKNG-01'),
            ),
            GzIconListRow(
              icon: GzIcons.ticket,
              title: l.clientProfileHubRowVouchers,
              trailing: _count(context, activity.ready.length, l.clientProfileHubCountReady),
              chevron: true,
              onPressed: () => nav.push('CL-VCHR-02'),
            ),
            GzIconListRow(
              icon: GzIcons.calendarDots,
              title: l.clientProfileHubRowVisits,
              trailing: _count(context, activity.visitsAhead, l.clientProfileHubCountUpcoming),
              chevron: true,
              onPressed: () => nav.push('CL-VIST-04'),
            ),
            GzIconListRow(
              icon: GzIcons.receipt,
              title: l.clientProfileHubRowReceipts,
              trailing: paid
                  ? Semantics(label: '${l.clientProfileHubCountPaid} ${f.money(paidFils)}', excludeSemantics: true, child: GzText(f.money(paidFils), role: GzTextRole.figBody, color: c.textSecondary, figures: true))
                  : null,
              chevron: true,
              onPressed: () => nav.push('CL-BKNG-05'),
            ),
            GzIconListRow(
              icon: GzIcons.heart,
              title: l.clientProfileHubRowSaved,
              trailing: _count(context, saved, l.clientProfileHubCountHalls),
              chevron: true,
              last: true,
              onPressed: () => nav.switchTab('saved'),
            ),
          ],
        ),
        Column(
          children: [
            GzIconListRow(icon: GzIcons.user, title: l.clientProfileHubRowPersonal, chevron: true, onPressed: () => nav.push('CL-PROF-03')),
            GzIconListRow(icon: GzIcons.bell, title: l.clientProfileHubRowNotifications, chevron: true, onPressed: () => nav.push('CL-PROF-04')),
            _CommonRows.language(context, ref),
            GzIconListRow(icon: GzIcons.settings, title: l.commonLabelSettings, chevron: true, last: true, onPressed: () => nav.push('CL-PROF-05')),
          ],
        ),
        Column(
          children: [
            GzIconListRow(icon: GzIcons.chatText, title: l.clientProfileSharedSupport, chevron: true, onPressed: () => nav.push('CL-MSGS-02', params: const <String, Object?>{'support': true})),
            _CommonRows.terms(context),
            _CommonRows.privacy(context),
          ],
        ),
        Padding(
          padding: kProfPad,
          child: GzButton(label: l.clientProfileSharedSignOut, variant: GzButtonVariant.secondary, iconStart: GzIcons.signOut, fullWidth: true, onPressed: () => confirmProfileSignOut(context, ref)),
        ),
      ],
    );
  }
}
