// CL-PROF-04 Notification preferences. Port of CL-PROF-04.tsx. Requirements: CA-PROF-06, CA-NOTI-02 .. 05, 07, 08.
// What reaches the person, in three groups: glyph rows with a one-word name and a switch. Always on: requests, vouchers, visits (no
// switch, a check). Reminders (on by default): the confirm window (the hours as a timer fact), voucher expiry, visit, countdown; there is no
// "balance due" because the app takes no balance (ADR 0033). Offers and news: one master switch, opt-in and off until turned on; the
// frequency is behind the info glyph. Channels are chosen per group as glyph chips. The quiet hours open a sheet; the phone's own
// permission is shown. Every change saves at once with a quiet toast.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/profile_identity.dart';
import '../application/profile_state.dart';
import 'widgets/profile_parts.dart';
import 'widgets/quiet_sheet.dart';

class ClProf04Screen extends ConsumerStatefulWidget {
  const ClProf04Screen({super.key});

  @override
  ConsumerState<ClProf04Screen> createState() => _ClProf04State();
}

class _ClProf04State extends ConsumerState<ClProf04Screen> {
  bool _failed = false;

  Future<void> _set(NotifPrefs next) async {
    final nav = context.gzNav;
    final saved = context.gzL10n.commonStateSaved;
    final ok = await ref.read(notifPrefsProvider.notifier).apply(next);
    if (!mounted) return;
    setState(() => _failed = !ok);
    if (ok) nav.toast(GzToastSpec(message: saved, icon: GzIcons.check));
  }

  void _openSettings() => context.gzNav.toast(GzToastSpec(message: context.l10n.clientProfileSharedOpeningSettings, icon: GzIcons.externalLink));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return GzScreen(
      top: GzTopBar(title: l.clientProfileNotifTitle),
      child: GzAsyncView<NotifPrefs>(
        value: ref.watch(notifPrefsProvider),
        loading: Semantics(
          label: context.gzL10n.commonStateLoading,
          container: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, start: GzSpace.gutter, end: GzSpace.gutter),
            child: Column(children: [for (var i = 0; i < 6; i++) const Padding(padding: EdgeInsetsDirectional.only(bottom: GzSpace.s3), child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64))]),
          ),
        ),
        onRetry: () => ref.invalidate(notifPrefsProvider),
        data: _body,
      ),
    );
  }

  Widget _channels(NotifPrefs n, Set<NotifChannel> value, NotifPrefs Function(Set<NotifChannel>) apply, {bool emailHint = false}) {
    final l = context.l10n;
    final hasEmail = (ref.watch(profileIdentityProvider)?.email ?? '').trim().isNotEmpty;
    final c = context.gz.colors;
    GzChipOption<NotifChannel> opt(NotifChannel v, IconData icon, String name, {bool disabled = false}) => GzChipOption<NotifChannel>(
      value: v,
      label: name,
      labelWidget: GzIcon(icon, size: GzIconSize.sm, color: disabled ? c.iconDisabled : c.iconPrimary),
      semanticLabel: name,
      disabled: disabled,
    );
    return Padding(
      padding: kProfPad,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: GzSpace.s3,
        runSpacing: GzSpace.s3,
        children: [
          ExcludeSemantics(child: GzIcon(GzIcons.send, size: GzIconSize.md, color: c.iconSecondary)),
          GzChipGroup<NotifChannel>.multiple(
            label: l.clientProfileNotifChannels,
            values: value.toList(),
            onChanged: (v) => _set(apply(v.toSet())),
            options: [
              opt(NotifChannel.push, GzIcons.bell, l.clientProfileNotifChannelPush),
              opt(NotifChannel.whatsapp, GzIcons.whatsapp, l.clientProfileNotifChannelWhatsapp),
              opt(NotifChannel.email, GzIcons.mail, l.clientProfileNotifChannelEmail, disabled: !hasEmail),
            ],
          ),
          if (!hasEmail && emailHint) GzButton(label: l.clientProfileNotifChannelEmailAdd, variant: GzButtonVariant.tertiary, onPressed: () => context.gzNav.push('CL-PROF-03')),
        ],
      ),
    );
  }

  Widget _section(String title, Widget list, [Widget? after]) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title.isNotEmpty) ...[Padding(padding: kProfPad, child: GzSectionHeader(title: title)), const SizedBox(height: GzSpace.s3)],
        list,
        if (after != null) ...[const SizedBox(height: GzSpace.s3), after],
      ],
    ),
  );

  Widget _body(NotifPrefs n) {
    final l = context.l10n;
    final c = context.gz.colors;
    final denied = ref.watch(deviceSettingsProvider).osNotificationsDenied;
    final hours = kConfirmWindowHours;
    final always = <(IconData, String)>[(GzIcons.calendarCheck, l.clientProfileNotifRequests), (GzIcons.ticket, l.clientProfileNotifVouchers), (GzIcons.calendarDots, l.clientProfileNotifVisits)];
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (denied || _failed)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s6),
              child: Column(
                children: [
                  if (denied) GzBanner(message: l.clientProfileNotifDenied, icon: GzIcons.bell, actionLabel: l.commonLabelSettings, onAction: _openSettings),
                  if (_failed) GzBanner(message: l.clientProfileSharedSaveFailed, tone: GzBannerTone.danger, actionLabel: context.gzL10n.commonActionRetry, onAction: () => setState(() => _failed = false)),
                ],
              ),
            ),
          _section(
            l.clientProfileNotifGroupAlways,
            Column(
              children: [
                for (var i = 0; i < always.length; i++)
                  GzIconListRow(
                    icon: always[i].$1,
                    title: always[i].$2,
                    trailing: Semantics(label: l.clientProfileSharedOn, image: true, excludeSemantics: true, child: GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSecondary)),
                    last: i == always.length - 1,
                  ),
              ],
            ),
          ),
          _section(
            l.clientProfileNotifGroupReminders,
            Column(
              children: [
                ProfSwitchRow(
                  icon: GzIcons.timer,
                  title: l.clientProfileNotifConfirm,
                  fact: GzFactChip(icon: GzIcons.timer, value: context.gzFormat.digits(context.gzL10n.commonCountHours(hours)), label: l.clientProfileNotifConfirmFact, tone: GzFactTone.muted, small: true),
                  checked: n.confirmWindow,
                  onChanged: (v) => _set(n.copyWith(confirmWindow: v)),
                ),
                ProfSwitchRow(icon: GzIcons.hourglass, title: l.clientProfileNotifVoucherExpiry, checked: n.voucherExpiry, onChanged: (v) => _set(n.copyWith(voucherExpiry: v))),
                ProfSwitchRow(icon: GzIcons.calendarDots, title: l.clientProfileNotifVisitReminders, checked: n.visitReminders, onChanged: (v) => _set(n.copyWith(visitReminders: v))),
                ProfSwitchRow(icon: GzIcons.countdown, title: l.clientProfileNotifMilestones, checked: n.milestones, onChanged: (v) => _set(n.copyWith(milestones: v)), last: true),
              ],
            ),
            _channels(n, n.reminderChannels, (s) => n.copyWith(reminderChannels: s), emailHint: true),
          ),
          _section(
            '',
            Column(
              children: [
                ProfSwitchRow(
                  icon: GzIcons.megaphone,
                  title: l.clientProfileNotifGroupMarketing,
                  checked: n.marketing,
                  onChanged: (v) => _set(n.copyWith(marketing: v)),
                  last: !n.marketing,
                  info: GzInfoButton(title: l.clientProfileNotifFrequencyTitle, paragraphs: [l.clientProfileNotifFrequency(kMaxMarketingPerWeek, kMarketingBlackoutDays)]),
                ),
                if (n.marketing) ...[
                  ProfSwitchRow(nested: true, icon: GzIcons.offer, title: l.clientProfileNotifOffers, checked: n.offers, onChanged: (v) => _set(n.copyWith(offers: v))),
                  ProfSwitchRow(nested: true, icon: GzIcons.trendDown, title: l.clientProfileNotifPriceDrops, checked: n.priceDrops, onChanged: (v) => _set(n.copyWith(priceDrops: v))),
                  ProfSwitchRow(nested: true, icon: GzIcons.venue, title: l.clientProfileNotifNewVenues, checked: n.newVenues, onChanged: (v) => _set(n.copyWith(newVenues: v)), last: true),
                ],
              ],
            ),
            n.marketing ? _channels(n, n.marketingChannels, (s) => n.copyWith(marketingChannels: s)) : null,
          ),
          Column(
            children: [
              GzIconListRow(
                icon: GzIcons.moon,
                title: l.clientProfileNotifQuiet,
                facts: GzFactChip(icon: GzIcons.clock, value: quietRange(ref, kQuietMarketing), label: l.clientProfileNotifQuiet, tone: GzFactTone.muted, small: true),
                chevron: true,
                last: denied,
                onPressed: () => context.gzNav.openSheetBuilder((_) => const QuietSheet(), options: GzSheetOptions(title: l.clientProfileNotifQuiet)),
              ),
              if (!denied) GzIconListRow(icon: GzIcons.phone, title: l.clientProfileNotifPhone, trailing: Text(l.clientProfileSharedOn), chevron: true, last: true, onPressed: _openSettings),
            ],
          ),
        ],
      ),
    );
  }
}
