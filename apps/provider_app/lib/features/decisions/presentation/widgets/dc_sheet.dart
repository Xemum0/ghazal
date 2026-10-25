// DcSheet (web `SheetShell.tsx`): the one anatomy of the four decision sheets: a pinned title row (ui-title, the info glyph and close at
// inline-end), the pinned who-and-what strip under it, the scrolling body and the pinned footer under a hairline. The footer is the ONE pinned
// bar of the sheet: the one gold primary, then equal-weight secondaries. Also the small string helpers of the flow.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

/// The name as an isolate (first strong direction), so an Arabic name does not reorder an English sentence.
String dcIsolate(String s) => String.fromCharCodes([0x2068, ...s.codeUnits, 0x2069]);

/// A message with the web's `<f>` (figure) and `<n>` (name) tags: the figures stay as given, the name becomes an isolate.
String dcPlain(String message) =>
    message.replaceAllMapped(RegExp('<n>(.*?)</n>'), (m) => dcIsolate(m.group(1)!)).replaceAllMapped(RegExp('<f>(.*?)</f>'), (m) => m.group(1)!);

/// First name of a person as typed (`ريم الدوسري` becomes `ريم`): the sheets speak about the couple by first name.
String dcFirstName(String full) {
  final parts = full.trim().split(RegExp(r'\s+'));
  return parts.isEmpty ? full : parts.first;
}

class DcSheet extends StatelessWidget {
  const DcSheet({required this.title, required this.children, this.context, this.footer, this.info, this.onClose, this.gap = GzSpace.s4, super.key});

  final String title;
  final List<Widget> children;

  /// The who-and-what strip (a `RequestContext`).
  final Widget? context;
  final Widget? footer;

  /// An info glyph before the close: the paragraphs that survived the diet live behind it.
  final Widget? info;
  final VoidCallback? onClose;
  final double gap;

  @override
  Widget build(BuildContext buildContext) {
    final c = buildContext.gz.colors;
    final close = onClose ?? () => buildContext.gzNav.closeSheet();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzSheetPinnedHeader(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: GzSize.controlMd),
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
                  child: Row(
                    children: [
                      Expanded(
                        child: GzText(title, role: GzTextRole.uiTitle, color: c.textStrong, header: true),
                      ),
                      ?info,
                      GzBarButton(
                        key: const ValueKey('gz:sheet.close'),
                        icon: GzIcons.close,
                        label: buildContext.gzL10n.commonActionClose,
                        onPressed: close,
                      ),
                    ],
                  ),
                ),
              ),
              if (context != null)
                Padding(
                  padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
                  child: context,
                ),
            ],
          ),
        ),
        DcTrim(
          trim: footer == null ? 0 : GzSpace.s3,
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [footer!]),
            ),
          ),
      ],
    );
  }
}

/// Reports its child's height minus [trim] (the kit's sheet body pads 24 under the content where the web frame pads 12 before its footer rule).
class DcTrim extends SingleChildRenderObjectWidget {
  const DcTrim({required this.trim, required super.child, super.key});

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
