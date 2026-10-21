import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

/// What the partner may do with a request (web `BookingAction`).
enum GzBookingAction { reschedule, revoke, cancel }

/// BookingActionList: what the partner may do with a request (ADR 0033 D3, ADR 0008 D12): Propose another date, Revoke approval and
/// Cancel booking, each a 64 row with the consequence in a caption, so nobody taps into a surprise. Revoke and Cancel are the danger
/// tone. Only the roles that may see Revoke and Cancel get them (the screen passes [actions] for the role); an action the role cannot
/// use is not drawn, never locked.
class GzBookingActionList extends StatelessWidget {
  const GzBookingActionList({required this.actions, this.onAction, super.key});

  /// The actions this role may take, in order.
  final List<GzBookingAction> actions;
  final ValueChanged<GzBookingAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    String title(GzBookingAction a) => switch (a) {
      GzBookingAction.reschedule => l.uiHotelActionsReschedule,
      GzBookingAction.revoke => l.uiHotelActionsRevoke,
      GzBookingAction.cancel => l.uiHotelActionsCancel,
    };
    String why(GzBookingAction a) => switch (a) {
      GzBookingAction.reschedule => l.uiHotelActionsRescheduleWhy,
      GzBookingAction.revoke => l.uiHotelActionsRevokeWhy,
      GzBookingAction.cancel => l.uiHotelActionsCancelWhy,
    };
    IconData icon(GzBookingAction a) => switch (a) {
      GzBookingAction.reschedule => GzIcons.calendarDots,
      GzBookingAction.revoke => GzIcons.undo,
      GzBookingAction.cancel => GzIcons.close,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < actions.length; i++)
            GzListRow(
              flush: true,
              chevron: true,
              last: i == actions.length - 1,
              tone: actions[i] == GzBookingAction.reschedule ? GzListRowTone.normal : GzListRowTone.danger,
              onPressed: () => onAction?.call(actions[i]),
              leading: _Disk(icon: icon(actions[i]), danger: actions[i] != GzBookingAction.reschedule),
              title: title(actions[i]),
              subtitle: why(actions[i]),
              subtitleWidget: GzText(why(actions[i]), role: GzTextRole.caption, color: c.textSecondary, figures: true),
            ),
        ],
      ),
    );
  }
}

/// `.gz-inv__disk`: a 40 disk, quiet (or danger tinted) with a 20 glyph.
class _Disk extends StatelessWidget {
  const _Disk({required this.icon, required this.danger});

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: Container(
        width: GzSize.avatarSm,
        height: GzSize.avatarSm,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: danger ? c.statusDangerBg : c.surfaceQuiet),
        child: GzIcon(icon, size: GzIconSize.sm, color: danger ? c.iconDanger : c.iconPrimary),
      ),
    );
  }
}
