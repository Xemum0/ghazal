// HL-SETT-03 Staff and roles (web `HL-SETT-03.tsx`): the team of the venue (Admin only): monogram, name in its own script, and per person the role and
// the state as facts (Active = when last seen, Pending = a pill and its expiry, Deactivated). Invite staff and the edit sheet are real sheets;
// inviting, removing and changing a role need a fresh email code first (the code screen in step-up mode, ADR 0028 D6). The owner and your own
// row cannot be changed here. Roles are glyph strips; the plain-words line of each role is read in the sheet of the top bar's (i). Staff are
// invited by email (Resend, ADR 0035); the row shows Pending until the invitee sets a password. A service provider has no staff list.
// Requirements: HA-SET-01, HA-SET-02, HA-AUTH-04, HA-AUTH-02.
import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerAccountRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show ChangeStaffRoleInput, InviteStaffInput, StaffInvitation, StaffList, StaffMember, StaffRole, StaffStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/settings_data.dart';
import '../application/settings_model.dart';
import 'widgets/staff_parts.dart';
import 'widgets/staff_sheets.dart';

class HlSett03Screen extends ConsumerStatefulWidget {
  const HlSett03Screen({super.key});

  @override
  ConsumerState<HlSett03Screen> createState() => _HlSett03ScreenState();
}

class _HlSett03ScreenState extends ConsumerState<HlSett03Screen> {
  Timer? _watch;

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  void _bump() => ref.read(partnerDataRevisionProvider.notifier).bump();

  void _problemToast(ApiProblem p) => GzNavigatorScope.of(context).toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));

  /// The step-up: a dialog says why, the code screen confirms, and when the code screen is left again the action runs. The contract has no
  /// partner step-up result yet (requests.md): leaving the code screen counts as the confirmation.
  Future<void> _stepUp(StaffAction action) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final answer = await nav.openDialog(
      GzDialogSpec(title: l.hotelSettingsStepUpTitle, body: l.hotelSettingsStepUpBodyStaff, icon: GzIcons.lock, confirmLabel: l.hotelSettingsStepUpSend, cancelLabel: context.gzL10n.commonActionCancel),
    );
    if (answer != GzDialogResult.confirm || !mounted) return;
    nav.push('HL-ACCS-02', params: const {'mode': 'step-up'});
    var left = false;
    _watch?.cancel();
    _watch = Timer.periodic(const Duration(milliseconds: 150), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      final here = nav.currentId == 'HL-SETT-03';
      if (!here) {
        left = true;
      } else if (left) {
        t.cancel();
        _run(action);
      }
    });
  }

  Future<void> _run(StaffAction action) async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final repo = ref.read(partnerAccountRepositoryProvider);
    switch (action) {
      case InviteAction(:final email, :final role):
        final p = await attempt(() => repo.inviteStaff(body: InviteStaffInput(email: email, role: role)));
        if (!mounted) return;
        if (p != null) return _problemToast(p);
        _bump();
        nav.toast(GzToastSpec(message: l.hotelSettingsStaffSent, tone: GzToastTone.success, icon: GzIcons.mail));
      case RoleAction(:final staffId, :final role):
        final p = await attempt(() => repo.changeStaffRole(staffId: staffId, body: ChangeStaffRoleInput(role: role)));
        if (!mounted) return;
        if (p != null) return _problemToast(p);
        _bump();
        nav.toast(GzToastSpec(message: roleName(l, role), tone: GzToastTone.success, icon: GzIcons.checkCircle));
      case RemoveAction(:final staff):
        final list = ref.read(staffListProvider).value;
        final inv = list?.invitations.where((i) => i.staffId == staff.id).firstOrNull;
        final name = staffName(context, staff);
        final p = await attempt(() => staff.status == StaffStatus.invited && inv != null ? repo.revokeStaffInvitation(invitationId: inv.id) : repo.deactivateStaff(staffId: staff.id));
        if (!mounted) return;
        if (p != null) return _problemToast(p);
        _bump();
        nav.toast(
          GzToastSpec(
            message: l.hotelSettingsStaffRemoved(name),
            icon: GzIcons.userMinus,
            undo: true,
            action: GzToastAction(label: context.gzL10n.commonActionUndo, onPressed: () => unawaited(repo.reactivateStaff(staffId: staff.id).then((_) => _bump()))),
          ),
        );
    }
  }

  void _openInvite() {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (_) => InviteContent(
        onSubmit: (email, role) {
          nav.closeSheet();
          unawaited(_stepUp(InviteAction(email, role)));
        },
      ),
      options: GzSheetOptions(title: context.l10n.hotelSettingsStaffInvite),
    );
  }

  void _openEdit(StaffMember s, StaffList all) {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final name = staffName(context, s);
    final repo = ref.read(partnerAccountRepositoryProvider);
    final inv = all.invitations.where((StaffInvitation i) => i.staffId == s.id).firstOrNull;
    nav.openSheetBuilder(
      (_) => EditContent(
        staff: s,
        actions: (
          onSaveRole: (r) {
            nav.closeSheet();
            unawaited(_stepUp(RoleAction(s.id, r)));
          },
          onSessions: () {
            nav.closeSheet();
            nav.toast(GzToastSpec(message: l.hotelSettingsStaffSessionsDone, tone: GzToastTone.success, icon: GzIcons.signOut));
          },
          onToggleActive: () async {
            nav.closeSheet();
            final was = s.status == StaffStatus.deactivated;
            final p = await attempt(() => was ? repo.reactivateStaff(staffId: s.id) : repo.deactivateStaff(staffId: s.id));
            if (!mounted) return;
            if (p != null) return _problemToast(p);
            _bump();
            nav.toast(
              GzToastSpec(
                message: was ? l.hotelSettingsStaffReactivated(name) : l.hotelSettingsStaffDeactivated(name),
                icon: was ? GzIcons.userPlus : GzIcons.userMinus,
                undo: true,
                action: GzToastAction(
                  label: context.gzL10n.commonActionUndo,
                  onPressed: () => unawaited((was ? repo.deactivateStaff(staffId: s.id) : repo.reactivateStaff(staffId: s.id)).then((_) => _bump())),
                ),
              ),
            );
          },
          onRemove: () async {
            nav.closeSheet();
            final answer = await nav.openDialog(
              GzDialogSpec(title: l.hotelSettingsStaffRemoveTitle(name), icon: GzIcons.userMinus, confirmLabel: l.hotelSettingsStaffRemoveConfirm, cancelLabel: context.gzL10n.commonActionCancel, tone: GzDialogTone.destructive),
            );
            if (answer == GzDialogResult.confirm && mounted) unawaited(_stepUp(RemoveAction(s)));
          },
          onResend: () async {
            nav.closeSheet();
            if (inv == null) return;
            final p = await attempt(() => repo.resendStaffInvitation(invitationId: inv.id));
            if (!mounted) return;
            if (p != null) return _problemToast(p);
            _bump();
            nav.toast(GzToastSpec(message: l.hotelSettingsStaffResent, tone: GzToastTone.success, icon: GzIcons.mail));
          },
        ),
      ),
      options: GzSheetOptions(title: name),
    );
  }

  void _about() {
    final l = context.l10n;
    final c = context.gz.colors;
    GzNavigatorScope.of(context).openSheetBuilder(
      (_) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in kAssignable) ...[
            GzText(roleName(l, r), role: GzTextRole.title, color: c.textStrong),
            const SizedBox(height: GzSpace.s2),
            RoleStrip(role: r),
            const SizedBox(height: GzSpace.s2),
            GzText(roleLine(l, r), role: GzTextRole.bodyS),
            Container(height: GzStroke.hair, margin: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s4), color: c.borderHairline),
          ],
          GzText(l.hotelSettingsStaffVisitNote, role: GzTextRole.bodyS),
          const SizedBox(height: GzSpace.s4),
          GzText(l.hotelSettingsStaffFoot, role: GzTextRole.bodyS),
        ],
      ),
      options: GzSheetOptions(title: l.hotelSettingsStaffAboutTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final ctx = ref.watch(partnerContextProvider);
    final allowed = ctx != null && accessOf(ctx.role).staff && !ctx.isProvider;
    final value = allowed ? ref.watch(staffListProvider) : const AsyncData<StaffList>(StaffList(staff: [], invitations: []));

    Widget body(StaffList all) {
      final alone = all.staff.every((s) => s.isYou) && all.invitations.isEmpty;
      final rows = [
        for (var i = 0; i < all.staff.length; i++)
          StaffPerson(
            key: ValueKey<String>('staff.${all.staff[i].id}'),
            staff: all.staff[i],
            last: i == all.staff.length - 1,
            onOpen: all.staff[i].isYou || all.staff[i].role == StaffRole.admin ? null : () => _openEdit(all.staff[i], all),
          ),
      ];
      return Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ...rows,
            if (alone)
              GzEmptyState(
                illustration: GzIllustrationName.invitation,
                size: GzIllustrationSize.lg,
                title: l.hotelSettingsStaffEmptyTitle,
                action: GzStateAction(label: l.hotelSettingsStaffInvite, iconStart: GzIcons.userPlus, onPressed: _openInvite),
                fill: false,
              )
            else ...[
              const SizedBox(height: GzSpace.s5),
              GzIconListRow(icon: GzIcons.chatText, title: l.hotelSettingsStaffSupport, chevron: true, flush: true, last: true, onPressed: () => nav.push('HL-TODY-05', params: {'conversationId': kSupportConversationId})),
            ],
          ],
        ),
      );
    }

    final loaded = allowed && value.hasValue && !(value.value!.staff.every((s) => s.isYou) && value.value!.invitations.isEmpty);
    return GzScreen(
      top: GzTopBar(title: l.hotelSettingsMoreStaff, actions: allowed ? [GzTopBarAction(icon: GzIcons.info, label: l.commonA11yInfo, onPressed: _about)] : const []),
      bottom: loaded ? GzActionBar(action: GzActionBarAction(label: l.hotelSettingsStaffInvite, onPressed: _openInvite)) : null,
      child: allowed
          ? GzAsyncView<StaffList>(value: value, loading: const _Skeleton(), onRetry: () => ref.invalidate(staffListProvider), data: body)
          : const GzErrorState(kind: GzErrorKind.noAccess),
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
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
              SizedBox(height: GzSpace.s4),
              GzSkeleton(variant: GzSkeletonVariant.line, blockSize: 64),
            ],
          ),
        ),
      ),
    );
  }
}
