// The small overlays of Today (web `Overlays.tsx`): the two first-run sheets (notifications, then the biometric lock) and the venue switcher sheet.
// Text diet: a first-run sheet is a drawing, two glyph points and one action; the paragraph that explains the permission sits behind an info glyph.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';

enum FirstRunStep { notifications, biometric }

String firstRunTitle(AppL10n l, FirstRunStep s) => s == FirstRunStep.notifications ? l.hotelTodayFirstRunNotifTitle : l.hotelTodayFirstRunLockTitle;

/// The body and the two actions of a first-run sheet.
class FirstRunContent extends StatelessWidget {
  const FirstRunContent({required this.step, this.onPrimary, this.onSkip, super.key});

  final FirstRunStep step;
  final VoidCallback? onPrimary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final notifications = step == FirstRunStep.notifications;
    final points = notifications
        ? <(IconData, String, String?)>[
            (GzIcons.bolt, l.hotelTodayFirstRunNotifPointTime, l.hotelTodayFirstRunNotifPointTime),
            (GzIcons.sound, l.hotelTodayFirstRunNotifPointSound, l.hotelTodayFirstRunNotifPointSound),
          ]
        : <(IconData, String, String?)>[(GzIcons.faceId, l.hotelTodayFirstRunFaceId, null), (GzIcons.fingerprint, l.hotelTodayFirstRunFingerprint, null)];
    Widget dot(bool on) => Container(
          width: on ? GzSize.dotOn : GzSize.dotOff,
          height: on ? GzSize.dotOn : GzSize.dotOff,
          decoration: BoxDecoration(shape: BoxShape.circle, color: on ? c.markKhayt : c.borderStrong),
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: GzIllustration(notifications ? GzIllustrationName.bell : GzIllustrationName.shield, size: GzIllustrationSize.lg)),
        const SizedBox(height: GzSpace.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < points.length; i++) ...[
              if (i > 0) const SizedBox(width: GzSpace.s5),
              Semantics(
                container: true,
                label: points[i].$2,
                child: ExcludeSemantics(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: GzSize.avatarSm,
                        height: GzSize.avatarSm,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceQuiet),
                        child: GzIcon(points[i].$1, size: GzIconSize.sm, color: c.iconPrimary),
                      ),
                      if (points[i].$3 != null) ...[const SizedBox(width: GzSpace.s2), GzText(points[i].$3!, role: GzTextRole.bodyS)],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Semantics(
              label: l.commonCounter(notifications ? 1 : 2, 2),
              child: ExcludeSemantics(child: Row(mainAxisSize: MainAxisSize.min, children: [dot(notifications), const SizedBox(width: GzSpace.s2), dot(!notifications)])),
            ),
            const SizedBox(width: GzSpace.s3),
            GzIconButton(
              icon: GzIcons.info,
              iconSize: GzIconSize.sm,
              label: context.gzL10n.commonA11yInfo,
              onPressed: () => showGzSheet<void>(
                context,
                title: firstRunTitle(l, step),
                builder: (_) => GzText(notifications ? l.hotelTodayFirstRunNotifBody : l.hotelTodayFirstRunLockBody, role: GzTextRole.body),
              ),
            ),
          ],
        ),
        GzSheetFooter(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzButton(label: notifications ? l.hotelTodayFirstRunNotifAllow : l.hotelTodayFirstRunLockOn, fullWidth: true, onPressed: onPrimary),
              const SizedBox(height: GzSpace.s1),
              Center(child: GzButton(label: notifications ? l.hotelTodayFirstRunNotNow : l.commonActionSkip, variant: GzButtonVariant.tertiary, onPressed: onSkip)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Opens the two first-run sheets one after the other when Today is entered with `firstRun` (the first sign-in of this run of the app).
class FirstRunTrigger extends StatefulWidget {
  const FirstRunTrigger({super.key});

  @override
  State<FirstRunTrigger> createState() => _FirstRunTriggerState();
}

class _FirstRunTriggerState extends State<FirstRunTrigger> {
  bool _asked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_asked) return;
    final nav = GzNavigatorScope.of(context);
    if (nav.params['firstRun'] != true) return;
    _asked = true;
    final l = context.l10n;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void second() {
        nav.openSheetBuilder(
          (_) => FirstRunContent(step: FirstRunStep.biometric, onPrimary: nav.closeSheet, onSkip: nav.closeSheet),
          options: GzSheetOptions(title: l.hotelTodayFirstRunLockTitle),
        );
      }

      void next() {
        nav.closeSheet();
        Future<void>.delayed(const Duration(milliseconds: 360), second);
      }

      nav.openSheetBuilder(
        (_) => FirstRunContent(step: FirstRunStep.notifications, onPrimary: next, onSkip: next),
        options: GzSheetOptions(title: l.hotelTodayFirstRunNotifTitle),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The venue switcher: the accounts of this staff member with their role and waiting requests; one tap works in that account.
class VenueSwitcherContent extends ConsumerWidget {
  const VenueSwitcherContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final nav = GzNavigatorScope.of(context);
    final ctx = ref.watch(partnerContextProvider);
    final rows = ref.watch(partnerMembershipsProvider).value ?? const [];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final m in rows)
          GzPressable(
            onPressed: () async {
              nav.closeSheet();
              if (m.accountId != ctx?.accountId) await ref.read(partnerContextProvider.notifier).switchTo(m.accountId, venueId: m.venueId, providerId: m.providerId);
            },
            semanticLabel: m.accountName.of(lang),
            borderRadius: GzRadius.smAll,
            minHeight: GzSize.rowQueue,
            scale: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
              padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GzUserText(m.accountName.of(lang), role: GzTextRole.d1, color: c.textStrong),
                        const SizedBox(height: GzSpace.s1),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GzText(_roleWord(l, m.role.value), role: GzTextRole.caption, color: c.textSecondary),
                            if (m.pendingRequests > 0) ...[
                              const SizedBox(width: GzSpace.s3),
                              GzFactChip(icon: GzIcons.calendarDots, label: l.hotelTodaySwitchPending(m.pendingRequests), value: f.integer(m.pendingRequests), tone: GzFactTone.accent, small: true),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (m.accountId == ctx?.accountId) Semantics(label: l.hotelTodaySwitchCurrent, child: GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

String _roleWord(AppL10n l, String role) => switch (role) {
      'reception' => l.hotelTodayRoleReception,
      'accountant' => l.hotelTodayRoleAccountant,
      'marketing' => l.hotelTodayRoleMarketing,
      _ => l.hotelTodayRoleManager,
    };
