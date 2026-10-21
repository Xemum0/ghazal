// The invitation behind HL-ACCS-03 and the sheet of HL-ACCS-01: who invited whom, to which account and role, valid until when.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show sessionProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show InvitationPreview;

/// The preview of an invitation token (`INVITATION_EXPIRED` surfaces as an `ApiProblem` error of the future).
final invitationPreviewProvider = FutureProvider.autoDispose.family<InvitationPreview, String>(
  (ref, token) => ref.read(sessionProvider.notifier).invitationPreview(token),
);
