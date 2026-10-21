import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/auth_flow.dart';

/// Contact Support: a dialog with the number as its only content (display only, never a tel: or wa.me link, ADR 0012 D11). The number is a
/// value in an LTR island; there is no sentence around it.
void openAuthSupport(BuildContext context, WidgetRef ref) {
  final l10n = context.l10n;
  final GzFormat f = ref.read(gzFormatProvider);
  context.gzNav.openDialog(
    GzDialogSpec(
      title: l10n.clientAuthSharedSupport,
      icon: GzIcons.whatsapp,
      body: GzBidi.isolateLtr(f.phone(AuthConfig.supportPhone)),
      confirmLabel: l10n.commonActionOpenWhatsapp,
      cancelLabel: l10n.commonActionClose,
    ),
  );
}
