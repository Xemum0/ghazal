import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The 12-month picker of the "Flexible" alternative (web `PickerSheet`): chips in six rows of two, Done pins at the foot. Resolves with
/// the chosen month, or null when dismissed.
Future<GzYm?> showObdMonthSheet(BuildContext context, {required List<GzYm> months, required GzYm initial, required String Function(GzYm) monthText}) {
  final l10n = context.l10n;
  return showGzSheet<GzYm>(
    context,
    title: l10n.clientOnboardingDateFlexibleTitle,
    label: l10n.clientOnboardingDateMonthsLabel,
    builder: (context) => _Months(months: months, initial: initial, monthText: monthText),
  );
}

class _Months extends StatefulWidget {
  const _Months({required this.months, required this.initial, required this.monthText});

  final List<GzYm> months;
  final GzYm initial;
  final String Function(GzYm) monthText;

  @override
  State<_Months> createState() => _MonthsState();
}

class _MonthsState extends State<_Months> {
  late GzYm _picked = widget.initial;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget chip(GzYm m) => Expanded(
      child: GzChip(label: widget.monthText(m), expand: true, figures: true, selected: _picked == m, onPressed: () => setState(() => _picked = m)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: l10n.clientOnboardingDateMonthsLabel,
          child: Column(
            children: [
              for (var i = 0; i < widget.months.length; i += 2) ...[
                if (i > 0) const SizedBox(height: GzSpace.s2),
                Row(
                  children: [
                    for (var j = i; j < i + 2 && j < widget.months.length; j++) ...[
                      if (j > i) const SizedBox(width: GzSpace.s2),
                      chip(widget.months[j]),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
        GzSheetFooter(
          child: GzButton(label: l10n.commonActionDone, fullWidth: true, onPressed: () => Navigator.of(context).pop(_picked)),
        ),
      ],
    );
  }
}
