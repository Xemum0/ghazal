// The pieces of Staff and roles (web `StaffParts.tsx`; text diet, ADR 0034): one person row (monogram, name, role, state as facts), a role as a
// strip of glyphs (its plain-words line is the accessible name) and the role picker.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show StaffMember, StaffRole, StaffStatus;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/settings_model.dart';

String roleName(AppL10n l, StaffRole r) => switch (r) {
  StaffRole.admin => l.hotelSettingsRoleOwner,
  StaffRole.manager => l.hotelSettingsRoleManager,
  StaffRole.reception => l.hotelSettingsRoleReception,
  StaffRole.accountant => l.hotelTodayRoleAccountant,
  _ => l.hotelTodayRoleMarketing,
};

String roleLine(AppL10n l, StaffRole r) => switch (r) {
  StaffRole.manager => l.hotelSettingsRoleLineManager,
  StaffRole.reception => l.hotelSettingsRoleLineReception,
  StaffRole.accountant => l.hotelSettingsRoleLineAccountant,
  _ => l.hotelSettingsRoleLineMarketing,
};

String staffName(BuildContext context, StaffMember s) => context.gz.locale.languageCode == 'ar' ? s.name : s.nameLatin;

/// The state of a person as facts: Active = when last seen, Pending = a pill and when it expires, Deactivated.
class StaffFacts extends StatelessWidget {
  const StaffFacts({required this.staff, super.key});

  final StaffMember staff;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = context.gzFormat;
    final pill = staff.status == StaffStatus.invited;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: GzSpace.s3,
      runSpacing: GzSpace.s1,
      children: [
        GzBadge(label: roleName(l, staff.role), variant: GzBadgeVariant.quiet, bead: false),
        if (staff.status == StaffStatus.active && staff.lastSeenAt != null)
          GzFactChip(icon: GzIcons.clock, small: true, tone: GzFactTone.muted, label: l.hotelSettingsStaffLastSeen, value: f.date(staff.lastSeenAt!, DateStyle.dayMonth)),
        if (pill) ...[
          const GzStatusPill(status: GzStatus.pending, audience: GzStatusAudience.hotel),
          if (staff.inviteExpiresAt != null)
            GzFactChip(icon: GzIcons.timer, small: true, tone: GzFactTone.muted, label: l.hotelSettingsStaffExpires, value: f.date(staff.inviteExpiresAt!, DateStyle.dayMonth)),
        ],
        if (staff.status == StaffStatus.deactivated) GzBadge(label: l.hotelSettingsStaffStateDeactivated, variant: GzBadgeVariant.quiet, bead: false, icon: GzIcons.userMinus),
      ],
    );
  }
}

class StaffPerson extends StatelessWidget {
  const StaffPerson({required this.staff, required this.last, this.onOpen, super.key});

  final StaffMember staff;
  final bool last;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final name = staffName(context, staff);
    final off = staff.status == StaffStatus.deactivated;
    final body = Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowQueue),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline.withAlpha(last ? 0 : 255), width: GzStroke.hair))),
      child: Row(
        children: [
          ExcludeSemantics(child: GzAvatar(name: name, initial: staff.monogram, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans)),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: GzUserText(name, role: GzTextRole.title, color: off ? c.textDisabled : c.textStrong)),
                    if (staff.isYou) ...[const SizedBox(width: GzSpace.s2), GzText(l.hotelSettingsStaffYou, role: GzTextRole.caption, color: c.textSecondary)],
                  ],
                ),
                const SizedBox(height: GzSpace.s2),
                StaffFacts(staff: staff),
              ],
            ),
          ),
          if (onOpen != null) GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary, mirror: true),
        ],
      ),
    );
    if (onOpen == null) return body;
    return GzPressable(onPressed: onOpen, semanticLabel: l.hotelSettingsStaffOpen(name), minHeight: GzSize.rowQueue, scale: 1, child: body);
  }
}

/// What a role may open, drawn as glyphs (muted = read only). The plain-words line is the accessible name of the strip.
class RoleStrip extends StatelessWidget {
  const RoleStrip({required this.role, super.key});

  final StaffRole role;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      label: roleLine(context.l10n, role),
      child: ExcludeSemantics(
        child: Wrap(
          spacing: GzSpace.s3,
          runSpacing: GzSpace.s1,
          children: [for (final g in kRoleGlyphs[role] ?? const <RoleGlyph>[]) GzIcon(g.icon, size: GzIconSize.sm, color: g.muted ? c.iconDisabled : c.iconSecondary)],
        ),
      ),
    );
  }
}

class RolePicker extends StatelessWidget {
  const RolePicker({required this.value, required this.onChanged, super.key});

  final StaffRole value;
  final ValueChanged<StaffRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final role in kAssignable) ...[
          GzPressable(
            onPressed: () => onChanged(role),
            semanticLabel: roleName(l, role),
            selected: value == role,
            minHeight: GzSize.controlLg,
            borderRadius: GzRadius.smAll,
            scale: 1,
            child: Container(
              constraints: const BoxConstraints(minHeight: GzSize.controlLg),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
              decoration: BoxDecoration(
                color: value == role ? c.surfaceQuiet : c.surfaceRaised,
                borderRadius: GzRadius.smAll,
                border: Border.all(color: value == role ? c.textStrong : c.borderStrong, width: GzStroke.hair),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [GzText(roleName(l, role), role: GzTextRole.title, color: c.textStrong), const SizedBox(height: GzSpace.s2), RoleStrip(role: role)],
                    ),
                  ),
                  SizedBox(width: GzSize.iconMd, child: value == role ? GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconPrimary) : null),
                ],
              ),
            ),
          ),
          if (role != kAssignable.last) const SizedBox(height: GzSpace.s2),
        ],
      ],
    );
  }
}

/// Reception only: may this person accept and decline requests (a switch kept on this device until the contract has it).
class AcceptRow extends StatelessWidget {
  const AcceptRow({required this.checked, required this.onChanged, super.key});

  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      child: Row(
        children: [
          ExcludeSemantics(
            child: Container(
              width: GzSize.avatarSm,
              height: GzSize.avatarSm,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
              child: GzIcon(GzIcons.checkDouble, size: GzIconSize.md, color: c.iconPrimary),
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(child: GzText(l.hotelSettingsStaffAccept, role: GzTextRole.title, color: c.textStrong)),
          GzSwitch(label: l.hotelSettingsStaffAccept, checked: checked, onChanged: onChanged),
        ],
      ),
    );
  }
}
