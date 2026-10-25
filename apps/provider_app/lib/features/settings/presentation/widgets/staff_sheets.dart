// The invite and edit sheets of Staff and roles (web `InviteContent`, `EditContent`). Actions that need a step-up are handed back to the screen,
// which closes the sheet first.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show StaffMember, StaffRole, StaffStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'staff_parts.dart';

class InviteContent extends StatefulWidget {
  const InviteContent({required this.onSubmit, super.key});

  final void Function(String email, StaffRole role) onSubmit;

  @override
  State<InviteContent> createState() => _InviteContentState();
}

class _InviteContentState extends State<InviteContent> {
  String _email = '';
  StaffRole _role = StaffRole.reception;
  bool _canAccept = true;
  bool _tried = false;

  bool get _emailBad => !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$').hasMatch(_email.trim());

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzTextField(
          label: l.hotelSettingsStaffEmail,
          dir: GzFieldDir.ltr,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          enableSuggestions: false,
          onValueChange: (v) => setState(() => _email = v),
          error: _tried && _emailBad ? l.hotelSettingsStaffEmailError : null,
        ),
        const SizedBox(height: GzSpace.s4),
        GzText(l.hotelSettingsStaffRole, role: GzTextRole.label),
        const SizedBox(height: GzSpace.s2),
        RolePicker(value: _role, onChanged: (r) => setState(() => _role = r)),
        if (_role == StaffRole.reception) ...[const SizedBox(height: GzSpace.s4), AcceptRow(checked: _canAccept, onChanged: (v) => setState(() => _canAccept = v))],
        GzSheetFooter(
          child: GzButton(
            label: l.hotelSettingsStaffSend,
            iconStart: GzIcons.mail,
            fullWidth: true,
            onPressed: () {
              setState(() => _tried = true);
              if (_emailBad) return;
              widget.onSubmit(_email.trim(), _role);
            },
          ),
        ),
      ],
    );
  }
}

typedef EditActions = ({
  void Function(StaffRole) onSaveRole,
  VoidCallback onSessions,
  VoidCallback onToggleActive,
  VoidCallback onRemove,
  VoidCallback onResend,
});

class EditContent extends StatefulWidget {
  const EditContent({required this.staff, required this.actions, super.key});

  final StaffMember staff;
  final EditActions actions;

  @override
  State<EditContent> createState() => _EditContentState();
}

class _EditContentState extends State<EditContent> {
  late StaffRole _role = widget.staff.role == StaffRole.admin ? StaffRole.manager : widget.staff.role;
  bool _canAccept = true;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final s = widget.staff;
    final pending = s.status == StaffStatus.invited;
    final off = s.status == StaffStatus.deactivated;
    final changed = _role != (s.role == StaffRole.admin ? StaffRole.manager : s.role);
    Widget action(IconData icon, String label, VoidCallback onTap) => GzPressable(
      onPressed: onTap,
      semanticLabel: label,
      minHeight: GzSize.rowMin,
      scale: 1,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: ExcludeSemantics(
          child: Row(children: [GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary), const SizedBox(width: GzSpace.s3), Expanded(child: GzText(label))]),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StaffFacts(staff: s),
        const SizedBox(height: GzSpace.s4),
        GzText(l.hotelSettingsStaffRole, role: GzTextRole.label),
        const SizedBox(height: GzSpace.s2),
        RolePicker(value: _role, onChanged: (r) => setState(() => _role = r)),
        if (_role == StaffRole.reception) ...[const SizedBox(height: GzSpace.s4), AcceptRow(checked: _canAccept, onChanged: (v) => setState(() => _canAccept = v))],
        const SizedBox(height: GzSpace.s4),
        if (pending) Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelSettingsStaffResend, variant: GzButtonVariant.secondary, iconStart: GzIcons.refresh, onPressed: widget.actions.onResend)),
        if (!pending) action(GzIcons.signOut, l.hotelSettingsStaffSessions, widget.actions.onSessions),
        if (!pending) action(off ? GzIcons.userPlus : GzIcons.userMinus, off ? l.hotelSettingsStaffReactivate : l.hotelSettingsStaffDeactivate, widget.actions.onToggleActive),
        const SizedBox(height: GzSpace.s2),
        Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: l.hotelSettingsStaffRemove, variant: GzButtonVariant.destructive, iconStart: GzIcons.trash, onPressed: widget.actions.onRemove)),
        if (changed) GzSheetFooter(child: GzButton(label: l.hotelSettingsStaffSaveRole, fullWidth: true, onPressed: () => widget.actions.onSaveRole(_role))),
      ],
    );
  }
}
