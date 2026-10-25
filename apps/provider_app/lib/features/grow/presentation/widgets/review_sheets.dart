// The two sheets of Reviews (web `ReviewSheets.tsx`): reply once in the venue's voice, and report abuse with a reason. The venue never approves, edits
// or hides a review (CF-24): the report only asks Ghazal to look, and the review stays visible meanwhile; that sentence is behind the (i) of the report
// sheet. A reply is public and sent once.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/grow_data.dart';

class ReplySheet extends ConsumerStatefulWidget {
  const ReplySheet({required this.review, required this.initial, super.key});

  final Review review;

  /// The text to start from: the staged draft, in the language the reviewer wrote in.
  final String initial;

  @override
  ConsumerState<ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends ConsumerState<ReplySheet> {
  late String _text = widget.initial;

  Future<void> _send() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final g = context.gzL10n;
    final res = await ref.read(growActionsProvider.notifier).reply(widget.review.id, _text.trim(), widget.review.origin);
    res.when(
      success: (_) {
        nav.closeSheet();
        nav.toast(GzToastSpec(message: l.hotelGrowRwReplySent, tone: GzToastTone.success));
      },
      failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(g, p), tone: GzToastTone.danger)),
      gated: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = ref.watch(growActionsProvider).busy.contains('reply:${widget.review.id}');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: GzSpace.s2),
        GzTextArea(
          label: l.hotelGrowRwReply,
          helper: l.hotelGrowRwReplyHelp,
          rows: 5,
          maxLength: 600,
          defaultValue: widget.initial,
          onValueChange: (v) => setState(() => _text = v),
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(
          label: l.hotelGrowRwReplySend,
          iconEnd: GzIcons.send,
          fullWidth: true,
          loading: busy,
          onPressed: _text.trim().isEmpty ? null : _send,
        ),
      ],
    );
  }
}

class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({required this.review, super.key});

  final Review review;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  ReportReviewInputReason? _reason;

  Future<void> _send() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final g = context.gzL10n;
    final res = await ref.read(growActionsProvider.notifier).report(widget.review.id, _reason!);
    res.when(
      success: (_) {
        nav.closeSheet();
        nav.toast(GzToastSpec(message: l.hotelGrowRwReported, tone: GzToastTone.success));
      },
      failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(g, p), tone: GzToastTone.danger)),
      gated: () {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final busy = ref.watch(growActionsProvider).busy.contains('report:${widget.review.id}');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GzInfoButton(title: l.hotelGrowRwReportTitle, paragraphs: [l.hotelGrowRwReportBody]),
        ),
        GzRadioGroup<ReportReviewInputReason>(
          label: l.hotelGrowRwReportTitle,
          value: _reason,
          onChanged: (v) => setState(() => _reason = v),
          children: [
            GzRadio(value: ReportReviewInputReason.offensive, label: l.hotelGrowRwReasonAbuse),
            GzRadio(value: ReportReviewInputReason.wrongVenue, label: l.hotelGrowRwReasonOff),
            GzRadio(value: ReportReviewInputReason.notAGuest, label: l.hotelGrowRwReasonPersonal),
            GzRadio(value: ReportReviewInputReason.other, label: l.hotelGrowRwReasonOther),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l.hotelGrowRwReportSend, fullWidth: true, loading: busy, onPressed: _reason == null ? null : _send),
      ],
    );
  }
}
