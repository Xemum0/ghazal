import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage, requestsRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show ReportIssueInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'bk_common.dart';

/// ChoiceRow: one option of a short single choice as a ruled radio row: a glyph, at most three words, the gold bead when chosen.
class BkChoiceRow extends StatelessWidget {
  const BkChoiceRow({required this.icon, required this.label, required this.selected, required this.onSelect, super.key});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      child: GzPressable(
        onPressed: onSelect,
        semanticLabel: label,
        builder: (context, st) => Container(
          constraints: const BoxConstraints(minHeight: GzSize.controlLg),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          child: Row(
            children: [
              GzIcon(icon, size: GzIconSize.md, color: selected ? c.iconPrimary : c.iconSecondary),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: GzText(label, role: GzTextRole.title, color: selected ? c.textStrong : c.textPrimary),
              ),
              GzThreadBead(tone: selected ? GzBeadTone.gold : GzBeadTone.hollow),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Reason { price, notRedeemed, other }

/// "Report an issue" for 72 hours after the event (voucher model section 8.5): the venue would not honour the voucher price, or the voucher
/// was never redeemed. Ghazal support reads it and follows up in the client's messages.
class ReportIssueSheet extends ConsumerStatefulWidget {
  const ReportIssueSheet({required this.bookingId, required this.venue, required this.until, super.key});

  final String bookingId;
  final String venue;
  final String until;

  @override
  ConsumerState<ReportIssueSheet> createState() => _ReportIssueState();
}

class _ReportIssueState extends ConsumerState<ReportIssueSheet> {
  _Reason? _reason;
  String _note = '';
  bool _busy = false;

  Future<void> _send(String reasonText) async {
    final nav = context.gzNav;
    final l = context.l10n;
    final common = context.gzL10n;
    setState(() => _busy = true);
    try {
      final text = _note.trim().isEmpty ? reasonText : '$reasonText. ${_note.trim()}';
      await ref
          .read(requestsRepositoryProvider)
          .reportIssue(
            requestId: widget.bookingId,
            body: ReportIssueInput(text: text),
          );
      ref.read(clientDataRevisionProvider.notifier).bump();
      nav.closeSheet();
      nav.toast(GzToastSpec(message: l.clientBookingsIssueSent, tone: GzToastTone.success));
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() => _busy = false);
      nav.toast(GzToastSpec(message: gzProblemMessage(common, p), tone: GzToastTone.danger));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final options = <(_Reason, IconData, String)>[
      (_Reason.price, GzIcons.coins, l.clientBookingsIssueReasonPrice),
      (_Reason.notRedeemed, GzIcons.ticket, l.clientBookingsIssueReasonNotRedeemed),
      (_Reason.other, GzIcons.help, l.clientBookingsIssueReasonOther),
    ];
    final chosen = options.where((o) => o.$1 == _reason).firstOrNull;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BkSheetTop(title: l.clientBookingsIssueTitle),
        const SizedBox(height: GzSpace.s4),
        GzFactRow(
          label: l.clientBookingsIssueFacts,
          children: [
            GzFactChip(icon: GzIcons.hall, label: l.clientBookingsFactHall, value: widget.venue),
            GzFactChip(icon: GzIcons.timer, tone: GzFactTone.accent, label: l.clientBookingsIssueUntil, value: widget.until),
          ],
        ),
        const SizedBox(height: GzSpace.s4),
        Semantics(
          container: true,
          label: l.clientBookingsIssueTitle,
          child: Column(
            children: [
              for (final o in options)
                BkChoiceRow(icon: o.$2, label: o.$3, selected: _reason == o.$1, onSelect: () => setState(() => _reason = o.$1)),
            ],
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        GzTextArea(label: l.clientBookingsIssueNote, optional: true, rows: 3, maxLength: 300, onValueChange: (v) => _note = v),
        const SizedBox(height: GzSpace.s4),
        GzButton(label: l.clientBookingsIssueSend, fullWidth: true, loading: _busy, onPressed: chosen == null ? null : () => _send(chosen.$3)),
      ],
    );
  }
}
