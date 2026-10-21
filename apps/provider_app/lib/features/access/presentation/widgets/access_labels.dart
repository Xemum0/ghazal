// The words of a staff role (shared by the invitation card and the invitation sheet).
import 'package:ghazal_domain/ghazal_domain.dart' show StaffRole;

import '../../../../l10n/l10n.dart';

String staffRoleLabel(AppL10n l, StaffRole role) => switch (role) {
  StaffRole.admin => l.hotelSettingsRoleOwner,
  StaffRole.manager => l.hotelSettingsRoleManager,
  StaffRole.reception => l.hotelSettingsRoleReception,
  StaffRole.accountant => l.hotelTodayRoleAccountant,
  StaffRole.marketing => l.hotelTodayRoleMarketing,
  StaffRole.unknown => '',
};

/// What the role can do, in one plain line (the sentence behind the info glyph of the invitation card).
String staffRoleSummary(AppL10n l, StaffRole role) => switch (role) {
  StaffRole.manager => l.hotelSettingsRoleLineManager,
  StaffRole.reception => l.hotelSettingsRoleLineReception,
  StaffRole.accountant => l.hotelSettingsRoleLineAccountant,
  StaffRole.marketing => l.hotelSettingsRoleLineMarketing,
  _ => '',
};
