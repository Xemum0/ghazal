import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The title row of a sheet screen: the title at inline-start (with an optional info glyph), close at inline-end (ADR 0014 D3). The sheet
/// body already carries the gutter, so the row adds none.
class MsgSheetHead extends StatelessWidget {
  const MsgSheetHead({this.title, this.info, this.plain = false, this.onClose, super.key});

  final String? title;
  final Widget? info;
  final bool plain;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (title != null)
                  Flexible(
                    child: GzText(title!, role: plain ? GzTextRole.title : GzTextRole.d1, color: c.textStrong, header: true),
                  ),
                if (info != null) ...[const SizedBox(width: GzSpace.s1), info!],
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzBarButton(
            key: const ValueKey<String>('gz:sheet.close'),
            icon: GzIcons.close,
            label: context.gzL10n.commonActionClose,
            onPressed: onClose ?? () => context.gzNav.closeSheet(),
          ),
        ],
      ),
    );
  }
}
