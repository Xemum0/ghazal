import 'package:flutter/widgets.dart';

import '../core/gz_format_scope.dart';
import '../foundation.dart';

/// A day separator: a centred caption between two runs of messages ("Today", "Thu 12 Nov"). [date] is a civil date (`2026-11-12`) or an
/// instant ISO string; the words come from the shared formatter.
class GzChatDateDivider extends StatelessWidget {
  const GzChatDateDivider({required this.date, super.key});

  final String date;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s3),
          child: GzText(context.gzFormat.relativeDay(date), role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.center, figures: true),
        ),
      ),
    );
  }
}
