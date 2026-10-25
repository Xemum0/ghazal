import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/notification_view.dart';
import '../../application/ntf_data.dart';
import 'msg_sheet_head.dart';

/// The notification pre-prompt (CA-NOTI-07): a bell drawn once, the title, two actions. `Turn on` asks the system (a dialog here).
class NtfPromptSheet extends ConsumerWidget {
  const NtfPromptSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = context.gzNav;
    Future<void> turnOn() async {
      final answer = await nav.openDialog(
        GzDialogSpec(
          title: l.clientMessagesOsTitle,
          body: l.clientMessagesOsBody,
          icon: GzIcons.bell,
          confirmLabel: l.clientMessagesOsAllow,
          cancelLabel: l.clientMessagesOsDeny,
        ),
      );
      ref.read(ntfPermissionProvider.notifier).set(answer == GzDialogResult.confirm ? NtfPermission.granted : NtfPermission.denied);
      nav.closeSheet();
      if (answer == GzDialogResult.confirm) nav.toast(GzToastSpec(message: l.clientMessagesPromptOnToast, tone: GzToastTone.success));
    }

    return Column(
      key: const ValueKey<String>('messages.prompt'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(
          title: l.clientMessagesPromptTitle,
          info: GzInfoButton(title: l.clientMessagesPromptTitle, paragraphs: [l.clientMessagesPromptBody, l.clientMessagesPromptNote]),
        ),
        const SizedBox(height: GzSpace.s3),
        const Center(child: GzIllustration(GzIllustrationName.bell, size: GzIllustrationSize.lg)),
        const SizedBox(height: GzSpace.s4),
        GzButton(key: const ValueKey<String>('messages.prompt.on'), label: l.clientMessagesPromptOn, fullWidth: true, onPressed: turnOn),
        const SizedBox(height: GzSpace.s2),
        Center(
          child: GzButton(label: l.clientMessagesPromptLater, variant: GzButtonVariant.tertiary, onPressed: () => nav.closeSheet()),
        ),
      ],
    );
  }
}

/// A notification whose venue is no longer listed (CA-NOTI-08): one drawing, then the nearest halls as rows.
class NtfMissingSheet extends ConsumerWidget {
  const NtfMissingSheet({required this.venueId, super.key});

  final String venueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final nearby = ref.watch(nearbyVenuesProvider(venueId)).value ?? const [];
    final areas = ref.watch(areaByIdProvider).value ?? const {};
    final shown = nearby.where((n) => n.venue.cover != null).take(3).toList();
    return Column(
      key: const ValueKey<String>('messages.missing'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MsgSheetHead(title: l.clientMessagesMissingTitle),
        const SizedBox(height: GzSpace.s3),
        const Center(child: GzIllustration(GzIllustrationName.noResult, size: GzIllustrationSize.lg)),
        const SizedBox(height: GzSpace.s3),
        for (var i = 0; i < shown.length; i++)
          GzListRow(
            flush: true,
            last: i == shown.length - 1,
            chevron: true,
            autoDir: true,
            title: shown[i].venue.name.of(lang),
            subtitleWidget: GzFactChip(
              icon: GzIcons.pin,
              label: l.clientMessagesMissingArea,
              value: areas[shown[i].venue.areaId]?.name.of(lang),
              small: true,
              tone: GzFactTone.muted,
            ),
            leading: SizedBox(
              width: GzSize.thumbMd,
              height: GzSize.thumbMd,
              child: ClipRRect(
                borderRadius: GzRadius.smAll,
                child: GzPhoto(src: shown[i].venue.cover!.file, alt: shown[i].venue.cover!.alt.of(lang)),
              ),
            ),
            onPressed: () {
              context.gzNav.closeSheet();
              context.gzNav.push('CL-VENU-01', params: <String, Object?>{'venueId': shown[i].venue.id});
            },
          ),
      ],
    );
  }
}
