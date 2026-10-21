import 'package:flutter/widgets.dart';

import '../foundation.dart';

/// One row of a [GzAccordion].
@immutable
class GzAccordionItem {
  const GzAccordionItem({required this.id, required this.title, required this.content, this.summary});

  final String id;
  final String title;

  /// One caption line under the title while closed (a summary of what is inside).
  final String? summary;
  final Widget content;
}

/// Accordion (direction section 9: a custom button + region): each row is a 64 min button (title body 500, chevron at inline-end) over
/// a hairline; the region opens by a 200 ms height tween measured from its content, the chevron turns 180 degrees. Single-open by
/// default ([multiple] for FAQ-style lists). Controlled ([openIds] + [onChanged]) or uncontrolled ([initialOpenIds]).
class GzAccordion extends StatefulWidget {
  const GzAccordion({required this.items, this.multiple = false, this.openIds, this.initialOpenIds = const [], this.onChanged, super.key});

  final List<GzAccordionItem> items;
  final bool multiple;
  final List<String>? openIds;
  final List<String> initialOpenIds;
  final ValueChanged<List<String>>? onChanged;

  @override
  State<GzAccordion> createState() => _GzAccordionState();
}

class _GzAccordionState extends State<GzAccordion> {
  late List<String> _inner = [...widget.initialOpenIds];

  List<String> get _open => widget.openIds ?? _inner;

  void _toggle(String id) {
    final open = _open;
    final next = open.contains(id) ? open.where((x) => x != id).toList() : (widget.multiple ? [...open, id] : [id]);
    if (widget.openIds == null) setState(() => _inner = next);
    widget.onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in widget.items)
          _AccordionRow(key: ValueKey('gz:accordion.${item.id}'), item: item, open: _open.contains(item.id), onToggle: () => _toggle(item.id)),
      ],
    );
  }
}

class _AccordionRow extends StatelessWidget {
  const _AccordionRow({required this.item, required this.open, required this.onToggle, super.key});

  final GzAccordionItem item;
  final bool open;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final dur = GzReducedMotion.movement(context, GzMotion.durationBase);
    final titleStyle = gz.text(GzTextRole.body).copyWith(fontWeight: gz.text(GzTextRole.title).fontWeight, color: c.textStrong, decoration: TextDecoration.none);
    final head = GzPressable(
      onPressed: onToggle,
      minHeight: GzSize.rowMin,
      builder: (context, st) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(item.title, style: titleStyle),
                      if (item.summary != null && !open) GzText(item.summary!, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1),
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s4),
                AnimatedRotation(
                  turns: open ? 0.5 : 0,
                  duration: dur,
                  curve: GzMotion.easeStandard,
                  child: const GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, tone: GzIconTone.secondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // A Container, not a DecoratedBox: the border insets the child, so the row is its content plus the 1 dp hairline, like the web row.
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(expanded: open, container: true, child: head),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: open ? 1 : 0),
            duration: dur,
            curve: GzMotion.easeStandard,
            builder: (context, t, child) => ClipRect(child: Align(alignment: AlignmentDirectional.topStart, heightFactor: t, child: child)),
            child: ExcludeFocus(
              excluding: !open,
              child: ExcludeSemantics(
                excluding: !open,
                child: IgnorePointer(
                  ignoring: !open,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
                    child: DefaultTextStyle.merge(style: gz.text(GzTextRole.bodyS).copyWith(color: c.textPrimary, decoration: TextDecoration.none), child: item.content),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
