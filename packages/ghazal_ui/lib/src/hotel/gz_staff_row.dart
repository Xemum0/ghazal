import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffMember, StaffRole, StaffStatus;

import '../core/core.dart';
import '../foundation.dart';
import 'hotel_bits.dart';
import 'hotel_c_kit.dart';

enum _Permission { accept, block, cancel, cash, revenue, offers, manage }

/// The role matrix of ADR 0008 D12.
const Map<StaffRole, Set<_Permission>> _matrix = {
  StaffRole.admin: {
    _Permission.accept,
    _Permission.block,
    _Permission.cancel,
    _Permission.cash,
    _Permission.revenue,
    _Permission.offers,
    _Permission.manage,
  },
  StaffRole.manager: {_Permission.accept, _Permission.block, _Permission.cancel, _Permission.cash, _Permission.revenue, _Permission.offers},
  StaffRole.reception: {_Permission.accept, _Permission.block, _Permission.cash},
  StaffRole.accountant: {_Permission.cash, _Permission.revenue},
  StaffRole.marketing: {_Permission.offers},
};

/// StaffRow: one person on the hotel's team (HL-SETT-03, HA-SET-01, HA-SET-02, ADR 0008 D12). Monogram, the name in its own script,
/// the role as a quiet badge (and "You" as a marker), and the state line: Active with when they were last seen, Invite pending with
/// its expiry, or Deactivated. Opened, it explains the role in one plain line and lists what that role may do: a check for what the
/// role has, a minus for what it does not; the one permission an Admin can switch is Reception's "accept and decline", a real
/// switch. Roles are fixed by the role, so a locked permission says so rather than showing a dead switch.
class GzStaffRow extends StatefulWidget {
  const GzStaffRow({
    required this.staff,
    this.defaultExpanded = false,
    this.canAccept = true,
    this.onCanAcceptChange,
    this.last = false,
    super.key,
  });

  final StaffMember staff;
  final bool defaultExpanded;

  /// Reception only: "Can accept and decline requests" (the owner may switch it off).
  final bool canAccept;
  final ValueChanged<bool>? onCanAcceptChange;
  final bool last;

  @override
  State<GzStaffRow> createState() => _GzStaffRowState();
}

class _GzStaffRowState extends State<GzStaffRow> {
  late bool _open = widget.defaultExpanded;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final staff = widget.staff;
    final name = lang == 'ar' ? staff.name : staff.nameLatin;
    final state = switch (staff.status) {
      StaffStatus.active => [
        l.uiHotelStaffActive,
        if (staff.lastSeenAt != null) l.uiHotelStaffLastSeen(f.dateTime(staff.lastSeenAt!)),
      ].join(' · '),
      StaffStatus.invited => [
        l.uiHotelStaffPending,
        if (staff.inviteExpiresAt != null) l.uiHotelStaffExpires(f.date(staff.inviteExpiresAt!, DateStyle.short)),
      ].join(' · '),
      _ => l.uiHotelStaffDeactivated,
    };
    final allowed = _matrix[staff.role] ?? const <_Permission>{};
    String word(_Permission p) => switch (p) {
      _Permission.accept => l.uiHotelStaffAccept,
      _Permission.block => l.uiHotelStaffBlock,
      _Permission.cancel => l.uiHotelStaffCancel,
      _Permission.cash => l.uiHotelStaffCash,
      _Permission.revenue => l.uiHotelStaffRevenue,
      _Permission.offers => l.uiHotelStaffOffers,
      _Permission.manage => l.uiHotelStaffManage,
    };
    return Container(
      decoration: gzRuleBelow(c, last: widget.last),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            expanded: _open,
            child: GzPressable(
              onPressed: () => setState(() => _open = !_open),
              semanticLabel: l.uiHotelStaffOpen(name),
              borderRadius: GzRadius.smAll,
              scale: 1,
              minHeight: GzSize.rowQueue,
              builder: (context, st) => Container(
                constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
                padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                decoration: BoxDecoration(color: st.pressed ? c.surfaceQuiet : null, borderRadius: GzRadius.smAll),
                child: Row(
                  children: [
                    GzAvatar(name: name, initial: staff.monogram, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: GzSpace.s2,
                            runSpacing: GzSpace.s1,
                            children: [
                              Text(
                                name,
                                style: gzUserStyle(name, GzTextRole.title, c.textStrong),
                                textDirection: gzFirstStrongOr(name, Directionality.of(context)),
                              ),
                              GzBadge(label: staff.roleLabel.of(lang), variant: GzBadgeVariant.quiet, bead: false),
                              if (staff.isYou) GzText(l.uiHotelStaffYou, role: GzTextRole.caption, color: c.textSecondary),
                            ],
                          ),
                          const SizedBox(height: GzSpace.s1),
                          GzFigText(
                            state,
                            role: GzTextRole.caption,
                            color: staff.status == StaffStatus.deactivated ? c.textDisabled : c.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    GzIcon(_open ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(bottom: GzSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzText(staff.roleSummary.of(lang), role: GzTextRole.bodyS, color: c.textPrimary),
                  const SizedBox(height: GzSpace.s3),
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final p in _Permission.values)
                          _PermissionRow(
                            label: word(p),
                            allowed: allowed.contains(p),
                            switchable: staff.role == StaffRole.reception && p == _Permission.accept,
                            checked: widget.canAccept,
                            onChanged: widget.onCanAcceptChange,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.label,
    required this.allowed,
    required this.switchable,
    required this.checked,
    required this.onChanged,
  });

  final String label;
  final bool allowed;
  final bool switchable;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
      decoration: gzRuleBelow(c),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(label, role: GzTextRole.bodyS),
                if (switchable) GzText(l.uiHotelStaffSwitchable, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          if (switchable)
            GzSwitch(checked: checked, onChanged: onChanged, label: l.uiHotelStaffAccept)
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GzIcon(allowed ? GzIcons.check : GzIcons.minus, size: GzIconSize.xs, color: allowed ? c.iconSuccess : c.iconSecondary),
                const SizedBox(width: GzSpace.s1),
                GzText(
                  allowed ? l.uiHotelStaffAllowed : l.uiHotelStaffNotAllowed,
                  role: GzTextRole.caption,
                  color: allowed ? c.textSuccess : c.textSecondary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
