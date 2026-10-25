// What a representative can do to a visit (HA-VIS-02 to HA-VIS-06), the twin of the web `useVisitActions`: confirm, propose another time,
// decline, mark arrived, open the visit and the chat, the representative and member sheets. Decisions are never queued offline.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage, partnerVisitsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show DeclineVisitInput, ProposeVisitSlotInput, StaffMember, ThreadMember, VisitAppointment;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart';
import '../../../../l10n/l10n.dart';
import '../../application/visits_data.dart';
import 'visit_sheets.dart';

class VisitUi {
  VisitUi(this.context, this.ref);

  final BuildContext context;
  final WidgetRef ref;

  GzNavigator get _nav => GzNavigatorScope.of(context);

  void open(VisitAppointment v) => _nav.push('HL-VIST-02', params: <String, Object?>{'visitId': v.id});

  void chat(VisitAppointment v) => _nav.push('HL-VIST-03', params: <String, Object?>{'visitId': v.id});

  void arrival(VisitAppointment v) => _nav.openSheet('HL-VIST-04', options: GzSheetOptions(params: <String, Object?>{'visitId': v.id}));

  void _bump() => ref.read(partnerDataRevisionProvider.notifier).bump();

  void _problem(ApiProblem p) => _nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger));

  Future<void> confirm(VisitAppointment v) async {
    final l = context.l10n;
    final nav = _nav;
    final p = await visitWrite(() => ref.read(partnerVisitsRepositoryProvider).confirmVisit(visitId: v.id));
    _bump();
    if (p != null) return _problem(p);
    nav.toast(GzToastSpec(message: l.hotelVisitsToastConfirmed, tone: GzToastTone.success));
  }

  void propose(VisitAppointment v) {
    final l = context.l10n;
    final nav = _nav;
    nav.openSheetBuilder(
      (_) => ProposeSheet(
        visit: v,
        onSend: (slot) async {
          final p = await visitWrite(
            () => ref
                .read(partnerVisitsRepositoryProvider)
                .proposeVisitSlot(
                  visitId: v.id,
                  body: ProposeVisitSlotInput(slotStart: slot),
                ),
          );
          _bump();
          if (p != null) return _problem(p);
          nav.closeSheet();
          nav.toast(GzToastSpec(message: l.hotelVisitsToastProposed, tone: GzToastTone.success, icon: GzIcons.checkCircle));
        },
      ),
    );
  }

  void decline(VisitAppointment v, {VoidCallback? after}) {
    final l = context.l10n;
    final nav = _nav;
    nav.openSheetBuilder(
      (_) => DeclineSheet(
        onCancel: nav.closeSheet,
        onConfirm: (reason, note) async {
          final p = await visitWrite(
            () => ref
                .read(partnerVisitsRepositoryProvider)
                .declineVisit(
                  visitId: v.id,
                  body: DeclineVisitInput(reason: note.isEmpty ? reason.name : '${reason.name}: $note'),
                ),
          );
          _bump();
          if (p != null) return _problem(p);
          ref.read(declineReasonProvider.notifier).set(v.id, reason.name);
          nav.closeSheet();
          nav.toast(GzToastSpec(message: l.hotelVisitsToastDeclined, icon: GzIcons.checkCircle));
          after?.call();
        },
      ),
    );
  }

  void assign(VisitAppointment v, String currentId) {
    final l = context.l10n;
    final nav = _nav;
    nav.openSheetBuilder(
      (_) => RepSheet(
        currentId: currentId,
        onPick: (StaffMember s) {
          ref.read(representativeOverrideProvider.notifier).set(v.id, s.userId);
          nav.closeSheet();
          nav.toast(GzToastSpec(message: l.hotelVisitsToastAssigned, tone: GzToastTone.success, icon: GzIcons.checkCircle));
        },
      ),
    );
  }

  void members(List<ThreadMember> list, {String? meId}) => _nav.openSheetBuilder((_) => MembersSheet(members: list, meId: meId));

  void attach() {
    final nav = _nav;
    final notice = context.gzL10n.commonStateTitleNetwork;
    nav.openSheetBuilder(
      (_) => AttachSheet(
        onPick: () {
          nav.closeSheet();
          // The device picker is a platform plugin the app does not carry yet (requests.md): say so instead of failing silently.
          nav.toast(GzToastSpec(message: notice));
        },
      ),
    );
  }
}
