// Contact Support and Contact the account admin (web `support.tsx`): with a valid session the Support thread opens (HL-TODY-05); without
// one a dialog shows the contact itself, display only, never a tel: link (ADR 0012 D11).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

/// Ghazal Support's number as the sign-in screens show it: a display value until the app config carries a support contact (requests.md).
const String kSupportPhone = '+96550000001';

Future<void> _showContact(BuildContext context, {required String title, required IconData icon}) {
  final nav = GzNavigatorScope.of(context);
  return nav.openDialog(
    GzDialogSpec(
      title: title,
      icon: icon,
      body: context.gzFormat.phone(kSupportPhone),
      confirmLabel: context.l10n.commonActionDone,
      showCancel: false,
    ),
  );
}

/// "Contact support": the Support thread when signed in, the contact dialog otherwise.
VoidCallback accessSupportAction(BuildContext context, WidgetRef ref) => () {
  final nav = GzNavigatorScope.of(context);
  if (ref.read(sessionProvider).isSignedIn) {
    nav.push('HL-TODY-05', params: const {'support': true});
    return;
  }
  _showContact(context, title: context.l10n.hotelAccessSupportTitle, icon: GzIcons.headset);
};

/// "Contact admin": the same dialog from the deactivated status and from an expired invitation.
VoidCallback accessContactAdminAction(BuildContext context) => () {
  _showContact(context, title: context.l10n.hotelAccessAdminTitle, icon: GzIcons.phone);
};
