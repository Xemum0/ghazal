// HL-SETT-01 More (the More tab root; web `HL-SETT-01.tsx`): everything that is not the daily loop, two levels deep at most (ADR 0008 D11). The listing
// card on top shows the listing status, the language completeness as two threads (a hotel) or the listing counts (a provider) and the Billing row
// that replaced the payout row; below it the venue tiles (glyph, count, one word), Visits, Grow, Notifications, Business and Account, or for a
// service provider Listings, Notifications and Account. Content is role-aware and navigation is not: a row a role cannot use is hidden, never
// locked. Language is a per-user setting and flips the app on the spot. Logging out clears the device.
// Requirements: HA-AUTH-02..04, HA-SET-05, HA-VMGT-09, HA-VMGT-10, HA-MSG-05, PA-ACC-02, PA-ACC-04, PA-ACC-05, HA-SET-06, HA-VIS-05, PA-BIL-01.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffRole, VenueStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_data.dart';
import '../application/settings_model.dart';
import 'widgets/more_parts.dart';
import 'widgets/more_sheets.dart';

const String _kAppVersion = '1.0.0';

class HlSett01Screen extends ConsumerWidget {
  const HlSett01Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final top = GzTopBar(variant: GzTopBarVariant.largeTitle, title: l.hotelSettingsMoreTitle, back: GzTopBarBack.hide);
    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: top,
        child: GzAsyncView<MoreData>(
          value: ref.watch(moreDataProvider),
          loading: const _Skeleton(),
          onRetry: () => ref.invalidate(moreDataProvider),
          data: (d) => _Body(data: d),
        ),
      ),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: context.gzL10n.commonStateLoading,
      child: const ExcludeSemantics(
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 252),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, inlineSize: 160, blockSize: 24),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 48),
            ],
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.data});

  final MoreData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final nav = GzNavigatorScope.of(context);
    final lang = context.gz.locale.languageCode;
    final ctx = ref.watch(partnerContextProvider);
    final role = ctx?.role ?? StaffRole.manager;
    final access = accessOf(role);
    final isProvider = ctx?.isProvider == true;
    final venue = data.venue?.venue;
    final counts = data.counts;
    final biometric = ref.watch(biometricProvider);

    void push(String id, [Map<String, Object?> params = const {}]) => nav.push(id, params: params);
    Widget count(int n) => GzText(f.integer(n), role: GzTextRole.figBodyS, color: c.textSecondary);
    Widget? waiting(int n) => n > 0 ? GzCountBadge(count: n, max: 9) : null;

    Future<void> logout() async {
      final answer = await nav.openDialog(
        GzDialogSpec(title: l.hotelSettingsLogoutTitle, icon: GzIcons.signOut, confirmLabel: l.hotelSettingsMoreLogout, cancelLabel: context.gzL10n.commonActionCancel, tone: GzDialogTone.destructive),
      );
      if (answer != GzDialogResult.confirm) return;
      await ref.read(sessionProvider.notifier).signOut();
      nav.reset('HL-ACCS-01');
    }

    Future<void> toggleBiometric(bool on) async {
      if (!on) {
        ref.read(biometricProvider.notifier).set(false);
        nav.toast(GzToastSpec(message: l.hotelSettingsBiometricOff, icon: GzIcons.fingerprint));
        return;
      }
      final answer = await nav.openDialog(GzDialogSpec(title: l.hotelSettingsBiometricOnTitle, icon: GzIcons.faceId, confirmLabel: l.hotelSettingsBiometricOnConfirm, cancelLabel: context.gzL10n.commonActionCancel));
      if (answer != GzDialogResult.confirm) return;
      ref.read(biometricProvider.notifier).set(true);
      nav.toast(GzToastSpec(message: l.hotelSettingsBiometricOn, tone: GzToastTone.success, icon: GzIcons.checkCircle));
    }

    void openLanguage() {
      nav.openSheetBuilder(
        (_) => LanguageContent(
          onChosen: (code) {
            final changed = code != lang;
            nav.closeSheet();
            if (changed) {
              // The toast is worded after the switch, in the language just chosen: wait one frame for the new locale.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) nav.toast(GzToastSpec(message: context.l10n.hotelSettingsLanguageSaved, tone: GzToastTone.success, icon: GzIcons.checkCircle));
              });
            }
          },
        ),
        options: GzSheetOptions(title: l.hotelSettingsLanguageTitle),
      );
    }

    // ---- rows by role and account type (hidden, never locked)
    final tiles = <MoreTile>[];
    final rowsVisits = <MoreRow>[];
    final rowsGrow = <MoreRow>[];
    final rowsListings = <MoreRow>[];
    if (!isProvider) {
      if (access.media) tiles.add((id: 'media', icon: GzIcons.image, title: l.hotelSettingsMoreMedia, count: venue?.gallery.length, onPress: () => push('HL-VENU-01')));
      if (access.venue) {
        tiles.addAll([
          (id: 'packages', icon: GzIcons.offer, title: l.hotelSettingsMorePackages, count: counts.packages, onPress: () => push('HL-VENU-02')),
          (id: 'halls', icon: GzIcons.hall, title: l.hotelSettingsMoreHalls, count: venue?.halls.length, onPress: () => push('HL-VENU-04')),
          (id: 'policies', icon: GzIcons.document, title: l.hotelSettingsMorePolicies, count: null, onPress: () => push('HL-VENU-05')),
          (id: 'rules', icon: GzIcons.checklist, title: l.hotelSettingsMoreRules, count: null, onPress: () => push('HL-VENU-06')),
        ]);
      }
      if (access.availability) tiles.add((id: 'availability', icon: GzIcons.calendarCheck, title: l.hotelSettingsMoreAvailability, count: null, onPress: () => nav.switchTab('calendar')));
      if (access.visits) {
        rowsVisits.add(moreRow('visit-requests', GzIcons.door, l.hotelSettingsMoreVisitRequests, trailing: waiting(counts.visitRequests), onPress: () => push('HL-VIST-01')));
        if (access.venue) rowsVisits.add(moreRow('visit-availability', GzIcons.calendarDots, l.hotelSettingsMoreVisitAvailability, onPress: () => push('HL-VIST-05')));
      }
      if (access.voucherPrices) rowsGrow.add(moreRow('voucher-prices', GzIcons.ticket, l.hotelSettingsMoreVoucherPrices, onPress: () => push('HL-GROW-01')));
      if (access.analytics) rowsGrow.add(moreRow('analytics', GzIcons.chartLine, l.hotelSettingsMoreAnalytics, onPress: () => push('HL-GROW-04')));
      if (access.reviews) rowsGrow.add(moreRow('reviews', GzIcons.star, l.hotelSettingsMoreReviews, trailing: waiting(counts.reviewsWaiting), onPress: () => push('HL-GROW-06')));
    } else if (access.listings) {
      rowsListings.addAll([
        moreRow('listings', GzIcons.megaphone, l.hotelSettingsMoreListings, trailing: count(counts.listingsAll), onPress: () => push('HL-PROV-02', {'account': 'provider'})),
        moreRow('performance', GzIcons.chartLine, l.hotelSettingsMorePerformance, onPress: () => push('HL-PROV-07', {'account': 'provider'})),
      ]);
    }

    final language = moreRow(
      'language',
      GzIcons.translate,
      l.hotelSettingsMoreLanguage,
      trailing: Directionality(textDirection: lang == 'ar' ? TextDirection.rtl : TextDirection.ltr, child: GzText(lang == 'ar' ? 'العربية' : 'English', color: c.textSecondary)),
      onPress: openLanguage,
    );
    final rowsBusiness = <MoreRow>[];
    if (!isProvider && access.staff) rowsBusiness.add(moreRow('staff', GzIcons.team, l.hotelSettingsMoreStaff, trailing: count(data.staffCount), onPress: () => push('HL-SETT-03')));
    if (!isProvider && access.hours != Level.none) rowsBusiness.add(moreRow('hours', GzIcons.clock, l.hotelSettingsMoreHours, onPress: () => push('HL-SETT-05')));
    final hasBusiness = rowsBusiness.isNotEmpty;
    if (hasBusiness) rowsBusiness.add(language);

    final rowsAccount = <MoreRow>[
      if (!hasBusiness) language,
      if (access.accountType)
        moreRow(
          'account-type',
          GzIcons.user,
          l.hotelSettingsMoreAccountType,
          trailing: GzFactChip(
            icon: isProvider ? GzIcons.megaphone : GzIcons.hotel,
            label: isProvider ? l.hotelSettingsAcctProvider : l.hotelSettingsAcctVenue,
          ),
          onPress: () => nav.openSheetBuilder((_) => const AccountTypeContent(), options: GzSheetOptions(title: l.hotelSettingsAcctTitle)),
        ),
      moreRow(
        'biometric',
        GzIcons.fingerprint,
        l.hotelSettingsMoreBiometric,
        chevron: false,
        trailing: GzSwitch(label: l.hotelSettingsMoreBiometric, checked: biometric, onChanged: toggleBiometric),
      ),
      moreRow(
        'support',
        GzIcons.chatText,
        l.hotelSettingsMoreSupport,
        onPress: isProvider ? () => nav.toast(GzToastSpec(message: l.hotelSettingsMoreSupportToast, icon: GzIcons.chatText)) : () => push('HL-TODY-05', {'conversationId': kSupportConversationId}),
      ),
      if (!isProvider) moreRow('switch', GzIcons.swap, l.hotelSettingsMoreSwitch, onPress: () => nav.openSheetBuilder((_) => const VenueSwitcherContent(), options: GzSheetOptions(title: l.hotelSettingsSwitchTitle))),
      moreRow('logout', GzIcons.signOut, l.hotelSettingsMoreLogout, danger: true, chevron: false, onPress: logout),
    ];

    // ---- the card
    final live = data.counts.listingsLive;
    final cardState = isProvider
        ? (live > 0 ? CardState.live : (counts.listingsReview > 0 ? CardState.review : CardState.draft))
        : (venue?.status == VenueStatus.inReview ? CardState.review : CardState.live);
    final cardName = isProvider ? (ctx?.accountName?.of(lang) ?? '') : (venue?.name.of(lang) ?? ctx?.accountName?.of(lang) ?? '');
    final showBilling = access.billing != Level.none;
    final attention = data.billing.status == BillingStatus.expiring || data.billing.status == BillingStatus.expired;
    final completeness = data.venue?.listingCompleteness;

    void legal() => nav.toast(GzToastSpec(message: l.hotelSettingsMoreLegalToast, icon: GzIcons.externalLink));

    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: ListingCard(
              name: cardName,
              state: cardState,
              completeness: isProvider || completeness == null ? null : (ar: completeness.ar, en: completeness.en),
              listings: isProvider ? (live: counts.listingsLive, review: counts.listingsReview) : null,
              billing: showBilling ? data.billing : null,
              attention: attention,
              onBilling: showBilling ? () => push('HL-SETT-04') : null,
              onPreview: () => nav.openSheetBuilder((_) => const PreviewContent(), options: GzSheetOptions(title: l.hotelSettingsPreviewTitle)),
            ),
          ),
          const _Gap(),
          if (tiles.isNotEmpty) ...[VenueTiles(title: l.hotelSettingsMoreGroupVenue, tiles: tiles), const _Gap()],
          if (rowsVisits.isNotEmpty) ...[MoreGroup(title: l.hotelSettingsMoreGroupVisits, rows: rowsVisits), const _Gap()],
          if (rowsListings.isNotEmpty) ...[MoreGroup(rows: rowsListings), const _Gap()],
          if (rowsGrow.isNotEmpty) ...[MoreGroup(title: l.hotelSettingsMoreGroupGrow, rows: rowsGrow), const _Gap()],
          MoreGroup(rows: [moreRow('notifications', GzIcons.bell, l.hotelSettingsMoreNotifications, onPress: () => push('HL-SETT-02'))]),
          const _Gap(),
          if (hasBusiness) ...[MoreGroup(title: l.hotelSettingsMoreGroupBusiness, rows: rowsBusiness), const _Gap()],
          MoreGroup(title: l.hotelSettingsMoreGroupAccount, rows: rowsAccount),
          const _Gap(),
          Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzText(l.hotelSettingsMoreVersion(_kAppVersion), role: GzTextRole.caption, figures: true),
                const SizedBox(height: GzSpace.s1),
                Wrap(
                  spacing: GzSpace.s5,
                  children: [
                    _Link(label: l.hotelSettingsMoreTerms, onPressed: legal),
                    _Link(label: l.hotelSettingsMorePrivacy, onPressed: legal),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Gap extends StatelessWidget {
  const _Gap();

  @override
  Widget build(BuildContext context) => const SizedBox(height: GzSpace.section);
}

class _Link extends StatelessWidget {
  const _Link({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      minHeight: GzSize.touchMin,
      scale: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        child: Align(
          widthFactor: 1,
          alignment: AlignmentDirectional.centerStart,
          child: ExcludeSemantics(
            child: Text(label, style: context.gz.text(GzTextRole.caption).copyWith(color: context.gz.colors.textGoldInk, decoration: TextDecoration.underline, decorationColor: context.gz.colors.textGoldInk)),
          ),
        ),
      ),
    );
  }
}
