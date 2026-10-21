import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';

enum GzCompareActionKind { voucher, dates, official, notify }

/// One column of the [GzCompareActionBar].
@immutable
class GzCompareActionColumn {
  const GzCompareActionColumn({required this.id, required this.name, required this.kind, required this.label});

  final String id;

  /// Hall name, one ellipsised line above the button.
  final String name;
  final GzCompareActionKind kind;
  final String label;
}

/// CompareActionBar (web `CompareActionBar`): the hall name over a 48 button aligned to each column; a hall turns gold (the one
/// primary) only once it is picked, never by default (ADR 0009 D8). [pinned] is the screen's job (a pinned bottom bar).
///
/// The buttons are [GzCompareButton]s, not `GzButton`: a third of the row is about 114 dp and the web trims the button's inline padding
/// to 8 so "Get voucher" keeps to its button (`GzButton` has a fixed 24).
class GzCompareActionBar extends StatelessWidget {
  const GzCompareActionBar({required this.columns, this.pickedId, this.onAction, this.pinned = false, super.key});

  final List<GzCompareActionColumn> columns;
  final String? pickedId;
  final void Function(String id, GzCompareActionKind kind)? onAction;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceCanvas,
          border: Border(
            top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
          ),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(GzSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < columns.length; i++) ...[
                if (i > 0) const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      GzText(columns[i].name, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1),
                      const SizedBox(height: GzSpace.s1),
                      GzButton(
                        label: columns[i].label,
                        variant: pickedId == columns[i].id ? GzButtonVariant.primary : GzButtonVariant.secondary,
                        size: GzButtonSize.md,
                        compact: true,
                        ellipsize: true,
                        fullWidth: true,
                        onPressed: () => onAction?.call(columns[i].id, columns[i].kind),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
