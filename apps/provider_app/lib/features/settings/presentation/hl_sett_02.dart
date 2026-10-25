// HL-SETT-02 Notification preferences (web `HL-SETT-02.tsx`): which alerts reach this phone, limited by role: a type a role cannot receive is
// hidden, never locked. New booking requests lead the screen with their own drawing (a bell), a lock glyph (always on for the roles that act on
// them) and a play control for the alert sound; business hours are one row below it. Every other alert is a glyph, one word and a switch. Changes
// save at once with "Saved". Text diet (ADR 0034): no sentence is on the screen; what each alert covers sits behind the (i) of the top bar.
// Voucher model (ADR 0033): requests, confirmations, vouchers redeemed, visits and chat, listing decisions and plan expiry; no balances or refunds.
// Requirements: HA-NOTI-08, HA-NOTI-01..05, HA-AUTH-02.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart' show PartnerNotificationPreferences, StaffRole;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_data.dart';
import '../application/settings_model.dart';
import 'widgets/pref_parts.dart';

const Duration _kSoundLength = Duration(milliseconds: 1800);

class HlSett02Screen extends ConsumerStatefulWidget {
  const HlSett02Screen({super.key});

  @override
  ConsumerState<HlSett02Screen> createState() => _HlSett02ScreenState();
}

class _HlSett02ScreenState extends ConsumerState<HlSett02Screen> {
  bool _playing = false;
  Timer? _timer;
  String? _saved;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    setState(() => _playing = true);
    _timer?.cancel();
    _timer = Timer(_kSoundLength, () {
      if (mounted) setState(() => _playing = false);
    });
  }

  /// The title word of an alert type.
  String _title(AppL10n l, NotifType t) => switch (t) {
    NotifType.newRequest => l.hotelSettingsNotifNewRequest,
    NotifType.confirmations => l.hotelSettingsNotifConfirmations,
    NotifType.cancelled => l.hotelSettingsNotifCancelled,
    NotifType.redemptions => l.hotelSettingsNotifRedemptions,
    NotifType.visits => l.hotelSettingsNotifVisits,
    NotifType.messages => l.hotelSettingsNotifMessages,
    NotifType.reviews => l.hotelSettingsNotifReviews,
    NotifType.listing => l.hotelSettingsNotifListing,
    NotifType.plan => l.hotelSettingsNotifPlan,
  };

  bool _value(NotifType t, PartnerNotificationPreferences p, Map<String, bool> local) => switch (t) {
    NotifType.redemptions => p.vouchers,
    NotifType.visits => p.visits,
    NotifType.messages => p.messages,
    NotifType.reviews => p.reviews,
    _ => local[t.name] ?? true,
  };

  Future<void> _change(NotifType t, bool on, PartnerNotificationPreferences p) async {
    final nav = GzNavigatorScope.of(context);
    final gzl = context.gzL10n;
    final local = <NotifType>{NotifType.confirmations, NotifType.cancelled, NotifType.listing, NotifType.plan};
    if (local.contains(t)) {
      ref.read(localAlertsProvider.notifier).set(t.name, on);
    } else {
      final next = PartnerNotificationPreferences(
        newRequestAlwaysOn: true,
        messages: t == NotifType.messages ? on : p.messages,
        reviews: t == NotifType.reviews ? on : p.reviews,
        vouchers: t == NotifType.redemptions ? on : p.vouchers,
        visits: t == NotifType.visits ? on : p.visits,
      );
      final problem = await ref.read(notifPrefsProvider.notifier).save(next);
      if (!mounted) return;
      if (problem != null) {
        nav.toast(GzToastSpec(message: problem.code == ApiProblemCode.offline ? gzl.commonStateOffline : gzProblemMessage(gzl, problem), tone: GzToastTone.danger, icon: GzIcons.offline));
        return;
      }
    }
    if (_saved != null) nav.dismissToast(_saved);
    _saved = nav.toast(GzToastSpec(message: gzl.commonStateSaved, icon: GzIcons.checkCircle));
  }

  void _about(bool request) {
    final l = context.l10n;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => AboutLines(
        lines: [
          if (request) ...[(GzIcons.bell, l.hotelSettingsNotifAboutLock), (GzIcons.moon, l.hotelSettingsNotifAboutQuiet)],
          (GzIcons.mail, l.hotelSettingsNotifAboutChannel),
        ],
      ),
      options: GzSheetOptions(title: l.hotelSettingsNotifAboutTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final ctx = ref.watch(partnerContextProvider);
    final role = ctx?.role ?? StaffRole.manager;
    final isProvider = ctx?.isProvider == true;
    final canHours = accessOf(role).hours != Level.none && !isProvider;
    final local = ref.watch(localAlertsProvider);
    bool visible(NotifType t) => (kNotifRoles[t] ?? const []).contains(role) && !(isProvider && kProviderHidden.contains(t)) && !(t == NotifType.plan && (ctx?.feeExempt ?? false));
    final requestVisible = visible(NotifType.newRequest);

    Widget body(PartnerNotificationPreferences prefs) {
      final groups = <Widget>[];
      for (final g in kNotifGroups) {
        final types = g.where(visible).toList();
        if (types.isEmpty) continue;
        groups.add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < types.length; i++)
                if (types[i] == NotifType.newRequest)
                  _RequestLead(playing: _playing, onPlay: _play, canHours: canHours, onHours: () => nav.push('HL-SETT-05'))
                else
                  PrefRow(
                    key: ValueKey<String>('pref.${types[i].name}'),
                    icon: kNotifGlyph[types[i]]!,
                    title: _title(l, types[i]),
                    checked: _value(types[i], prefs, local),
                    onChanged: (on) => _change(types[i], on, prefs),
                    last: i == types.length - 1,
                  ),
            ],
          ),
        );
      }
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [for (var i = 0; i < groups.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), groups[i]]],
        ),
      );
    }

    final value = ref.watch(notifPrefsProvider);
    return GzScreen(
      top: GzTopBar(
        title: l.hotelSettingsMoreNotifications,
        actions: [GzTopBarAction(icon: GzIcons.info, label: l.commonA11yInfo, onPressed: () => _about(requestVisible))],
      ),
      child: GzAsyncView<PartnerNotificationPreferences>(
        value: value,
        loading: const _Skeleton(),
        onRetry: () => ref.invalidate(notifPrefsProvider),
        data: body,
      ),
    );
  }
}

/// New requests: its drawing, a lock (always on) and the play control; business hours one row below.
class _RequestLead extends StatelessWidget {
  const _RequestLead({required this.playing, required this.onPlay, required this.canHours, required this.onHours});

  final bool playing;
  final VoidCallback onPlay;
  final bool canHours;
  final VoidCallback onHours;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzIconListRow(
          illustration: GzIllustrationName.bell,
          title: l.hotelSettingsNotifNewRequest,
          flush: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzFactChip(icon: GzIcons.lock, label: l.hotelSettingsNotifAlwaysOn),
              const SizedBox(width: GzSpace.s2),
              GzIconButton(
                icon: playing ? GzIcons.sound : GzIcons.play,
                iconSize: GzIconSize.sm,
                variant: GzIconButtonVariant.outline,
                disk: GzIconButtonDisk.sm,
                label: playing ? l.hotelSettingsNotifPlaying : l.hotelSettingsNotifPlaySound,
                onPressed: onPlay,
              ),
            ],
          ),
          chevron: false,
          last: !canHours,
        ),
        if (canHours) GzIconListRow(icon: GzIcons.clock, title: l.hotelSettingsMoreHours, chevron: true, onPressed: onHours, flush: true, last: true),
      ],
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
              GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 128),
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
