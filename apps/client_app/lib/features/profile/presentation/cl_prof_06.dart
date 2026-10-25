// CL-PROF-06 Delete account. Port of CL-PROF-06.tsx. Requirements: CA-PROF-09 (ADR 0007 D12, ADR 0028 item 7).
// In-app deletion in four moves, text-diet edition (ADR 0034): (1) the consequences as glyph rows with a one-word outcome, the full
// sentences behind the info glyph; (2) a fresh WhatsApp code; (3) the last confirmation (who, "Can't be undone", a destructive button
// with icon and text, never colour alone); (4) a plain "deleted" and the language screen again. Deletion is PAUSED, never a dead end,
// while a request is approved (confirm or cancel it first) or a confirmed booking is still ahead: the hourglass, the request named as a
// fact row, and the ways forward. A ready voucher is shown as lost (no money refund; ask support first). No gold on the destructive path.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, profileRepositoryProvider, sessionProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode, DateStyle, gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show BookingStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/profile_activity.dart';
import '../application/profile_code.dart';
import '../application/profile_identity.dart';
import '../application/profile_state.dart';
import 'widgets/code_body.dart';
import 'widgets/profile_parts.dart';

enum _Step { consequences, blocked, scheduled, otp, confirm, deleting, success }

class ClProf06Screen extends ConsumerWidget {
  const ClProf06Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    return GzAsyncView<ProfileActivity>(
      value: ref.watch(profileActivityProvider),
      loading: GzScreen(top: GzTopBar(title: l.clientProfileDelTitle), child: const _Skeleton()),
      onRetry: () => ref.invalidate(profileActivityProvider),
      data: (a) => _Body(activity: a),
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.gzL10n.commonStateLoading,
    container: true,
    child: const Padding(
      padding: EdgeInsetsDirectional.only(top: GzSpace.s2, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 96), SizedBox(height: GzSpace.s3), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64)],
      ),
    ),
  );
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.activity});

  final ProfileActivity activity;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late _Step _step = _seed(ref.read(profileDeletionAfterProvider) != null, widget.activity.blocksDeletion);
  bool _failed = false;
  ProfileCodeController? _code;

  static _Step _seed(bool scheduled, bool blocked) => scheduled ? _Step.scheduled : (blocked ? _Step.blocked : _Step.consequences);

  @override
  void dispose() {
    _code?.dispose();
    super.dispose();
  }

  void _keep() => context.gzNav.pop();

  void _back() {
    if (_step == _Step.deleting || _step == _Step.success) return;
    if (_step == _Step.otp || _step == _Step.confirm) {
      _code?.dispose();
      _code = null;
      setState(() {
        _step = _Step.consequences;
        _failed = false;
      });
    } else {
      _keep();
    }
  }

  Future<void> _enterOtp() async {
    final who = ref.read(profileIdentityProvider);
    if (who == null) return;
    final code = ProfileCodeController(ref, purpose: CodePurpose.stepUp, phone: who.phone);
    _code?.dispose();
    _code = code;
    setState(() => _step = _Step.otp);
    await code.send();
  }

  Future<void> _confirmDelete() async {
    setState(() {
      _step = _Step.deleting;
      _failed = false;
    });
    try {
      await ref.read(profileRepositoryProvider).deleteAccount();
    } on ApiProblem catch (e) {
      if (!mounted) return;
      if (e.code == ApiProblemCode.accountDeletionBlocked) {
        ref.invalidate(profileActivityProvider);
        setState(() => _step = _Step.blocked);
      } else {
        setState(() {
          _step = _Step.confirm;
          _failed = true;
        });
      }
      return;
    }
    if (!mounted) return;
    await ref.read(sessionProvider.notifier).signOut();
    if (!mounted) return;
    setState(() => _step = _Step.success);
  }

  void _scheduleAfter(String isoDay) {
    ref.read(profileDeletionAfterProvider.notifier).schedule(isoDay);
    setState(() => _step = _Step.scheduled);
  }

  void _unschedule() {
    ref.read(profileDeletionAfterProvider.notifier).schedule(null);
    context.gzNav.toast(GzToastSpec(message: context.l10n.clientProfileDelScheduledCancelled, icon: GzIcons.check));
    context.gzNav.pop();
  }

  void _openBooking({bool cancel = false}) {
    final id = widget.activity.request?.booking.id;
    if (id == null) return;
    context.gzNav.push('CL-BKNG-02', params: cancel ? <String, Object?>{'bookingId': id, 'intent': 'cancel'} : <String, Object?>{'bookingId': id});
  }

  void _toSupport() => context.gzNav.push('CL-MSGS-02', params: const <String, Object?>{'support': true});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = _step == _Step.success;
    final locked = done || _step == _Step.deleting;
    final Widget child = switch (_step) {
      _Step.consequences => _consequences(),
      _Step.blocked => _blocked(),
      _Step.scheduled => _scheduled(),
      _Step.otp => _otp(),
      _Step.confirm => _failed ? _error() : _confirm(),
      _Step.deleting => _deleting(),
      _Step.success => _success(),
    };
    final body = _step == _Step.otp && _code != null
        ? ListenableBuilder(
            listenable: _code!,
            builder: (context, _) => GzScreen(
              top: GzTopBar(title: l.clientProfileDelTitle, back: GzTopBarBack.auto, onBack: _back),
              bottom: GzActionBar(action: codeAction(context, _code!, () => setState(() => _step = _Step.confirm))),
              child: child,
            ),
          )
        : GzScreen(
            top: GzTopBar(title: done ? null : l.clientProfileDelTitle, back: locked ? GzTopBarBack.hide : GzTopBarBack.auto, onBack: locked ? null : _back),
            child: child,
          );
    return body;
  }

  /// One consequence: a glyph, a noun, the outcome in one word.
  Widget _outcome(IconData icon, String title, String word, {bool last = false, Widget? trailing, VoidCallback? onPressed}) => GzIconListRow(
    icon: icon,
    title: title,
    trailing: trailing ?? Text(word),
    chevron: onPressed != null,
    last: last,
    onPressed: onPressed,
  );

  Widget _warn() => Row(
    children: [
      GzIcon(GzIcons.warningCircle, size: GzIconSize.sm, color: context.gz.colors.iconDanger),
      const SizedBox(width: GzSpace.s2),
      Expanded(child: GzText(context.l10n.clientProfileDelUndone, role: GzTextRole.bodyS, color: context.gz.colors.textSecondary)),
    ],
  );

  Widget _consequences() {
    final l = context.l10n;
    final c = context.gz.colors;
    final a = widget.activity;
    final request = a.request;
    final venueName = request?.target.name.of(context.gz.locale.languageCode) ?? '';
    final ready = a.ready.length;
    final refundable = a.creditEligible.length;
    final paragraphs = <String>[l.clientProfileDelSheetData, l.clientProfileDelSheetReceipts, l.clientProfileDelSheetSaved, l.clientProfileDelSheetApple];
    if (request?.booking.status == BookingStatus.pending) paragraphs.add(l.clientProfileDelSheetRequest(venueName));
    if (refundable > 0) {
      paragraphs.add(l.clientProfileDelVoucherDetailRefund(refundable));
    } else if (ready > 0) {
      paragraphs.add(l.clientProfileDelVoucherDetailEnds(ready));
    }
    final lastPlain = request?.booking.status != BookingStatus.pending && ready == 0;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: kProfPad,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const GzIllustration(GzIllustrationName.shield, size: GzIllustrationSize.md),
                const SizedBox(width: GzSpace.s4),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GzIcon(GzIcons.warningCircle, size: GzIconSize.sm, color: context.gz.colors.iconDanger),
                      const SizedBox(width: GzSpace.s2),
                      Flexible(child: GzText(l.clientProfileDelUndone, role: GzTextRole.bodyS, color: c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s4),
                GzInfoButton(title: l.clientProfileDelDetailTitle, paragraphs: paragraphs),
              ],
            ),
          ),
          const SizedBox(height: GzSpace.s6),
          Column(
            children: [
              _outcome(GzIcons.user, l.clientProfileDelItemData, l.clientProfileDelOutAnonymised),
              _outcome(GzIcons.receipt, l.clientProfileHubRowReceipts, l.clientProfileDelOutKept),
              _outcome(GzIcons.heart, l.clientProfileDelItemPlans, l.clientProfileDelOutRemoved, last: lastPlain),
              if (request?.booking.status == BookingStatus.pending)
                GzIconListRow(
                  icon: GzIcons.calendarCheck,
                  title: venueName,
                  trailing: Text(l.clientProfileDelOutWithdrawn),
                  last: ready == 0,
                ),
              if (ready > 0)
                _outcome(
                  GzIcons.ticket,
                  l.clientProfileDelVoucher(ready),
                  '',
                  last: true,
                  trailing: refundable > 0
                      ? GzButton(
                          label: l.clientProfileDelVoucherRefund,
                          variant: GzButtonVariant.tertiary,
                          onPressed: () => context.gzNav.push('CL-VCHR-03', params: <String, Object?>{'voucherId': a.ready.first.voucher.id}),
                        )
                      : Text(l.clientProfileDelOutRemoved, style: TextStyle(color: c.textSecondary)),
                ),
            ],
          ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: kProfPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzButton(label: l.clientProfileDelTitle, variant: GzButtonVariant.destructive, iconStart: GzIcons.trash, fullWidth: true, onPressed: _enterOtp),
                const SizedBox(height: GzSpace.s3),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzButton(label: l.clientProfileSharedKeep, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: _keep),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blocked() {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final lang = context.gz.locale.languageCode;
    final request = widget.activity.request;
    final approved = request?.booking.status == BookingStatus.approved;
    final venueName = request?.target.name.of(lang) ?? '';
    final eventIso = request?.booking.eventDate.toString() ?? '';
    final detail = approved ? l.clientProfileDelBlockedApprovedDetail(venueName) : l.clientProfileDelBlockedDetail(venueName, eventIso.isEmpty ? '' : f.date(eventIso, DateStyle.full));
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzEmptyState(
            illustration: GzIllustrationName.hourglass,
            title: l.clientProfileDelBlockedTitle,
            detail: detail,
            detailTitle: l.clientProfileDelBlockedTitle,
            fill: false,
            size: GzIllustrationSize.lg,
          ),
          if (request != null)
            GzIconListRow(
              icon: GzIcons.calendarCheck,
              title: venueName,
              facts: GzFactRow(
                children: [
                  if (eventIso.isNotEmpty) GzFactChip(icon: GzIcons.calendar, value: f.date(eventIso, DateStyle.full), label: l.clientProfileWedDate),
                  GzStatusPill(status: approved ? GzStatus.approved : GzStatus.confirmed),
                ],
              ),
              chevron: true,
              onPressed: _openBooking,
              last: true,
            ),
          const SizedBox(height: GzSpace.s6),
          Padding(
            padding: kProfPad,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (approved)
                  GzButton(label: l.clientProfileDelBlockedOpen, fullWidth: true, onPressed: _openBooking)
                else
                  GzButton(
                    label: l.clientProfileDelBlockedSchedule,
                    fullWidth: true,
                    onPressed: eventIso.isEmpty ? null : () => _scheduleAfter(eventIso),
                  ),
                const SizedBox(height: GzSpace.s3),
                GzButton(
                  label: approved ? l.clientProfileDelBlockedCancelRequest : l.clientProfileDelBlockedCancel,
                  variant: GzButtonVariant.secondary,
                  fullWidth: true,
                  onPressed: () => _openBooking(cancel: true),
                ),
                const SizedBox(height: GzSpace.s3),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: GzButton(label: l.clientProfileSharedSupport, variant: GzButtonVariant.tertiary, flushInline: true, iconStart: GzIcons.chat, onPressed: _toSupport),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduled() {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final day = ref.watch(profileDeletionAfterProvider) ?? widget.activity.request?.booking.eventDate.toString() ?? '';
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: GzSuccessState(
        illustration: GzIllustrationName.calendar,
        title: l.clientProfileDelScheduledTitle,
        body: day.isEmpty ? null : f.date(day, DateStyle.full),
        action: GzStateAction(label: context.gzL10n.commonActionDone, onPressed: _keep),
        secondary: GzStateAction(label: l.clientProfileDelScheduledCancel, onPressed: _unschedule),
      ),
    );
  }

  Widget _otp() {
    final f = ref.watch(gzFormatProvider);
    final who = ref.watch(profileIdentityProvider);
    final code = _code;
    if (code == null || who == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: GzIllustration(GzIllustrationName.chat, size: GzIllustrationSize.md)),
          const SizedBox(height: GzSpace.s5),
          ProfileCodeBody(code: code, phoneText: f.phone(who.phone), onVerified: () => setState(() => _step = _Step.confirm)),
        ],
      ),
    );
  }

  Widget _confirm() {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    final who = ref.watch(profileIdentityProvider);
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: GzIllustration(GzIllustrationName.warning, size: GzIllustrationSize.lg)),
          const SizedBox(height: GzSpace.s5),
          if (who != null)
            Column(
              children: [
                GzAvatar(name: who.name, initial: who.monogram, size: GzAvatarSize.md),
                const SizedBox(height: GzSpace.s3),
                GzText(who.name, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true, textAlign: TextAlign.center),
                const SizedBox(height: GzSpace.s1),
                GzNum(f.phone(who.phone), role: GzTextRole.figCaption, color: context.gz.colors.textSecondary),
              ],
            ),
          const SizedBox(height: GzSpace.s5),
          _warn(),
          const SizedBox(height: GzSpace.s5),
          GzButton(label: l.clientProfileDelTitle, variant: GzButtonVariant.destructive, iconStart: GzIcons.trash, fullWidth: true, onPressed: _confirmDelete),
          const SizedBox(height: GzSpace.s3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(label: l.clientProfileSharedKeep, variant: GzButtonVariant.tertiary, flushInline: true, onPressed: _keep),
          ),
        ],
      ),
    );
  }

  Widget _error() {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: GzErrorState(
        title: l.clientProfileDelErrorTitle,
        body: l.clientProfileDelErrorDetail,
        onRetry: _confirmDelete,
        secondary: GzStateAction(label: l.clientProfileSharedKeep, onPressed: _keep),
      ),
    );
  }

  Widget _deleting() => Padding(
    padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
    child: GzEmptyState(illustration: GzIllustrationName.hourglass, title: context.l10n.clientProfileDelDeleting, fill: false, size: GzIllustrationSize.lg),
  );

  Widget _success() {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
      child: GzSuccessState(
        illustration: GzIllustrationName.seal,
        title: l.clientProfileDelSuccessTitle,
        detail: l.clientProfileDelSuccessDetail,
        detailTitle: l.clientProfileDelSuccessTitle,
        action: GzStateAction(label: context.gzL10n.commonActionDone, onPressed: () => context.gzNav.reset('CL-ONBD-01')),
      ),
    );
  }
}
