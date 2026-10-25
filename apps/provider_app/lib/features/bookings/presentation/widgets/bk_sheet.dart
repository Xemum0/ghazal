// BkSheet (web `SheetFrame.tsx`): the one anatomy of the sheets of this flow: a self-drawn pinned title row (ui-title, the info glyph when a
// paragraph sits behind it, close at inline-end), the body, and a pinned footer under a hairline. The sheet supplies the gutter of the body
// and of the footer; the header draws its own.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

class BkSheet extends StatelessWidget {
  const BkSheet({
    required this.title,
    this.titleWidget,
    required this.children,
    this.footer,
    this.info,
    this.infoTitle,
    this.onClose,
    this.gap = GzSpace.s4,
    super.key,
  });

  final String title;

  /// Replaces the title text (a client's name as typed takes its own script).
  final Widget? titleWidget;
  final List<Widget> children;
  final Widget? footer;

  /// The paragraphs that survived the diet, behind an info glyph beside the close.
  final List<String>? info;
  final String? infoTitle;
  final VoidCallback? onClose;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final close = onClose ?? () => context.gzNav.closeSheet();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.controlMd),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: GzSpace.s2),
                      child: titleWidget ?? GzText(title, role: GzTextRole.uiTitle, color: c.textStrong, header: true),
                    ),
                  ),
                  if (info != null) GzInfoButton(title: infoTitle ?? title, paragraphs: info!),
                  GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: close),
                ],
              ),
            ),
          ),
        ),
        BkTrim(
          trim: footer == null ? 0 : GzSpace.s2,
          child: Padding(
            padding: EdgeInsets.only(top: GzSpace.s3, bottom: footer == null ? GzSpace.s3 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
              ],
            ),
          ),
        ),
        if (footer != null)
          GzSheetFooter(
            child: Container(
              padding: const EdgeInsets.only(top: GzSpace.s3),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: footer!,
            ),
          ),
      ],
    );
  }
}

/// Reports its child's height minus [trim] (the child keeps its size and overflows at the bottom, nothing is clipped): the kit's sheet body
/// pads 24 under the content where the web sheet frame pads 12 before its footer rule.
class BkTrim extends SingleChildRenderObjectWidget {
  const BkTrim({required this.trim, required super.child, super.key});

  final double trim;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTrim(trim);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) => (renderObject as _RenderTrim).trim = trim;
}

class _RenderTrim extends RenderShiftedBox {
  _RenderTrim(this._trim) : super(null);

  double _trim;
  set trim(double v) {
    if (v == _trim) return;
    _trim = v;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final c = child!;
    c.layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(Size(c.size.width, (c.size.height - _trim).clamp(0.0, double.infinity)));
  }
}
