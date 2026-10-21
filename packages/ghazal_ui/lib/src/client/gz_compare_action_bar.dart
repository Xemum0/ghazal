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
                      GzCompareButton(
                        label: columns[i].label,
                        primary: pickedId == columns[i].id,
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

/// The compare button: the web `Button` (secondary, or the one gold primary) with its inline padding trimmed to 8, which is what the
/// compare surfaces ask of it (a third of a row, or the tray's free width). [height] is 48 (md) in the action bar and 44 (sm) in the tray.
/// It fills the width it is given and keeps its label to one ellipsised line.
class GzCompareButton extends StatelessWidget {
  const GzCompareButton({required this.label, required this.onPressed, this.primary = false, this.height = GzSize.controlMd, super.key});

  final String label;
  final bool primary;
  final double height;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    return GzPressable(
      semanticLabel: label,
      onPressed: onPressed,
      borderRadius: GzRadius.smAll,
      builder: (context, st) {
        final bg = primary ? (st.pressed ? c.actionPrimaryBgPressed : c.actionPrimaryBg) : (st.pressed ? c.actionSecondaryBgPressed : null);
        final fg = primary ? c.actionPrimaryLabel : c.actionSecondaryLabel;
        return ClipRRect(
          borderRadius: GzRadius.smAll,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: GzRadius.smAll,
              border: primary ? null : Border.all(color: c.actionSecondaryBorder, width: GzStroke.hair),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height),
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2 + GzStroke.hair),
                child: Center(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: gzResetLabelStyle(gz).copyWith(color: fg, decoration: TextDecoration.none),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
