// "Invitation" (the sheet of HL-ACCS-01): there is no self sign-up; the invitation arrives as an email link from the account admin and opens
// Set password. Three knots on the thread show the way (link, password, code) and a picture of the message follows.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/access_flow.dart';
import '../../application/invitation_providers.dart';
import 'invite_card.dart';

class InviteSheetContent extends ConsumerWidget {
  const InviteSheetContent({this.onClose, this.onOpenInvitation, super.key});

  final VoidCallback? onClose;
  final VoidCallback? onOpenInvitation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final preview = ref.watch(invitationPreviewProvider(kHeroInvitationToken));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: GzSpace.s2),
        GzIconProgress(
          label: l.hotelAccessInviteSteps,
          labels: GzProgressLabels.all,
          draw: GzDraw.mount,
          steps: [
            GzIconProgressStep(id: 'link', icon: GzIcons.mail, label: l.hotelAccessInviteStepLink, state: GzKnotState.now),
            GzIconProgressStep(id: 'password', icon: GzIcons.lock, label: l.hotelAccessSigninPasswordLabel, state: GzKnotState.open),
            GzIconProgressStep(id: 'code', icon: GzIcons.shieldCheck, label: l.hotelAccessInviteStepCode, state: GzKnotState.open),
          ],
        ),
        const SizedBox(height: GzSpace.s6),
        if (preview.hasValue) InviteMessage(preview: preview.requireValue, onOpen: onOpenInvitation),
        GzSheetFooter(
          child: GzButton(label: context.gzL10n.commonActionDone, fullWidth: true, onPressed: onClose),
        ),
      ],
    );
  }
}
