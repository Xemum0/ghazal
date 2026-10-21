import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_roving.dart';

/// One tab of [GzTabs].
class GzTabsItem<V> {
  const GzTabsItem({required this.value, required this.label, this.count, this.disabled = false, this.panel});

  final V value;
  final String label;

  /// A count in the figures voice after the label (pending requests); already formatted by the caller.
  final String? count;
  final bool disabled;

  /// Optional panel, rendered below the tab list for the selected tab.
  final Widget? panel;
}

/// One tab of [GzIconTabs]: a glyph over a one-word label.
class GzIconTabItem<V> {
  const GzIconTabItem({required this.value, required this.icon, required this.label, this.count, this.disabled = false, this.panel});

  final V value;
  final IconData icon;

  /// One word. Shown under the selected tab (or under all with `labels: all`); always the accessible name.
  final String label;

  /// A gold count badge on the glyph (pending requests, unread).
  final int? count;
  final bool disabled;
  final Widget? panel;
}

/// `fill`: equal-width tabs across the row. `hug`: tabs size to their label and the row scrolls (many tabs). Default `fill`.
enum GzTabsLayout { fill, hug }

/// Tabs (web `Tabs`): 48 high, label body-s muted, the selected tab ink-900 at 500 with a 2 dp gold thread sliding under it over
/// 320 ms on a 1 dp ink-300 baseline. The thread is positioned from the start edge (a directional offset), so Arabic mirrors with no
/// second code path. Arrow keys activate and follow what you see; Home / End jump. The label reserves its selected (500) width
/// ([GzSteadyLabel], measured, not a hidden copy) so selecting a tab never nudges its neighbours.
class GzTabs<V> extends StatefulWidget {
  const GzTabs({
    required this.items,
    required this.label,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.layout = GzTabsLayout.fill,
    super.key,
  });

  final List<GzTabsItem<V>> items;

  /// Accessible name of the tab list.
  final String label;
  final V? value;
  final V? defaultValue;
  final ValueChanged<V>? onChanged;
  final GzTabsLayout layout;

  @override
  State<GzTabs<V>> createState() => _GzTabsState<V>();
}

class _GzTabsState<V> extends State<GzTabs<V>> {
  final GzFocusNodes _focus = GzFocusNodes();
  final GlobalKey _content = GlobalKey();
  final Map<int, GlobalKey> _tabKeys = {};
  V? _inner;
  ({double x, double w})? _box;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultValue ?? widget.items.where((i) => !i.disabled).map((i) => i.value).firstOrNull;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  V? get _value => widget.value ?? _inner;

  int get _active {
    final i = widget.items.indexWhere((e) => e.value == _value);
    return i < 0 ? 0 : i;
  }

  void _set(V v) {
    if (widget.value == null) setState(() => _inner = v);
    widget.onChanged?.call(v);
  }

  // The thread's x is measured from the START edge of the list content, in layout dp, and the width of the active tab.
  void _measure() {
    final content = _content.currentContext?.findRenderObject();
    final tab = _tabKeys[_active]?.currentContext?.findRenderObject();
    if (content is! RenderBox || tab is! RenderBox || !content.hasSize || !tab.hasSize || !mounted) return;
    final left = tab.localToGlobal(Offset.zero, ancestor: content).dx;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final x = rtl ? content.size.width - (left + tab.size.width) : left;
    final next = (x: (x * 100).roundToDouble() / 100, w: (tab.size.width * 100).roundToDouble() / 100);
    if (_box == null || _box!.x != next.x || _box!.w != next.w) setState(() => _box = next);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final hug = w.layout == GzTabsLayout.hug;
    final active = _active;
    SchedulerBinding.instance.addPostFrameCallback((_) => _measure());
    final flags = [for (final i in w.items) i.disabled];

    Widget tab(int i) {
      final it = w.items[i];
      final selected = i == active;
      final color = it.disabled ? c.textDisabled : (selected ? c.textStrong : c.textSecondary);
      final base = gz.text(GzTextRole.bodyS);
      final label = GzSteadyLabel(span: TextSpan(text: it.label), style: base.copyWith(color: color), selected: selected);
      final body = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          label,
          if (it.count case final count?) ...[
            const SizedBox(width: GzSpace.s2),
            GzText(count, role: GzTextRole.figCaption, color: c.textSecondary, figures: true),
          ],
        ],
      );
      final pressable = Focus(
        canRequestFocus: false,
        onKeyEvent: (_, e) {
          final next = gzRovingIndex(e, i, flags, rtl: gz.isRtl, vertical: false);
          if (next == null) return KeyEventResult.ignored;
          _set(w.items[next].value);
          _focus[next].requestFocus();
          return KeyEventResult.handled;
        },
        child: GzPressable(
          focusNode: _focus[i],
          onPressed: it.disabled ? null : () => _set(it.value),
          semanticLabel: it.count == null ? it.label : '${it.label} ${it.count}',
          selected: selected,
          builder: (context, st) => SizedBox(
            height: GzSize.controlMd,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hug ? 0 : GzSpace.s2),
              child: Center(widthFactor: hug ? 1 : null, child: body),
            ),
          ),
        ),
      );
      final keyed = KeyedSubtree(key: _tabKeys.putIfAbsent(i, GlobalKey.new), child: pressable);
      return hug ? keyed : Expanded(child: keyed);
    }

    final row = hug
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < w.items.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s6), tab(i)],
            ],
          )
        : Row(children: [for (var i = 0; i < w.items.length; i++) tab(i)]);

    final thread = _box == null || _box!.w <= 0
        ? null
        : AnimatedPositionedDirectional(
            duration: GzReducedMotion.movement(context, GzMotion.durationSlow),
            curve: GzMotion.easeStandard,
            start: _box!.x,
            width: _box!.w,
            bottom: 0,
            height: GzStroke.thread,
            child: ColoredBox(color: c.markKhayt),
          );

    final content = Stack(key: _content, children: [row, ?thread]);
    // A Container (not a DecoratedBox): the 1 dp baseline is a border of the list that ADDS its width to the box (web: 56 + 1, 48 + 1),
    // and the thread sits above it.
    final list = Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderStrong, width: GzStroke.hair),
        ),
      ),
      child: hug ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: content) : content,
    );
    final selectedPanel = w.items.isEmpty ? null : w.items[active].panel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(container: true, label: w.label, child: list),
        if (selectedPanel != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
            child: selectedPanel,
          ),
      ],
    );
  }
}

/// `selected`: the chosen tab shows its word. `all`: every tab does.
enum GzIconTabsLabels { selected, all }

/// Icon tabs (web `IconTabs`, ADR 0034): tabs as glyphs. Each tab is a fixed 56 high column: the glyph, then a one-word label that
/// appears under the SELECTED tab only. The label row is always reserved, so choosing a tab never moves or resizes anything: only the
/// 2 dp gold thread slides (320 ms) and the glyph tone changes.
class GzIconTabs<V> extends StatefulWidget {
  const GzIconTabs({
    required this.items,
    required this.label,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.labels = GzIconTabsLabels.selected,
    super.key,
  });

  final List<GzIconTabItem<V>> items;
  final String label;
  final V? value;
  final V? defaultValue;
  final ValueChanged<V>? onChanged;
  final GzIconTabsLabels labels;

  @override
  State<GzIconTabs<V>> createState() => _GzIconTabsState<V>();
}

class _GzIconTabsState<V> extends State<GzIconTabs<V>> {
  final GzFocusNodes _focus = GzFocusNodes();
  V? _inner;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultValue ?? widget.items.where((i) => !i.disabled).map((i) => i.value).firstOrNull;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  V? get _value => widget.value ?? _inner;

  void _set(V v) {
    if (widget.value == null) setState(() => _inner = v);
    widget.onChanged?.call(v);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final idx = w.items.indexWhere((e) => e.value == _value);
    final active = idx < 0 ? 0 : idx;
    final flags = [for (final i in w.items) i.disabled];
    final n = w.items.length;

    Widget tab(int i) {
      final it = w.items[i];
      final selected = i == active;
      final color = it.disabled ? c.textDisabled : (selected ? c.textStrong : c.textSecondary);
      final iconColor = selected ? c.iconPrimary : (it.disabled ? c.iconDisabled : c.iconSecondary);
      final showLabel = w.labels == GzIconTabsLabels.all || selected;
      // The count badge sits at the PHYSICAL right corner of the glyph in both languages: the web badge is a number island
      // (`direction: ltr`), and an absolutely positioned box resolves `inset-inline-end` against its own direction (measured:
      // HL-TODY-02 in Arabic, badge right edge = glyph right edge). An LTR scope makes `end` the right edge here.
      final glyph = SizedBox(
        height: GzSize.iconMd,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: GzSpace.s2),
                child: GzIcon(it.icon, size: GzIconSize.md, color: iconColor),
              ),
              if (it.count != null && it.count! > 0) PositionedDirectional(top: 0, end: 0, child: GzCountBadge(count: it.count!)),
            ],
          ),
        ),
      );
      return Expanded(
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, e) {
            final next = gzRovingIndex(e, i, flags, rtl: gz.isRtl, vertical: false);
            if (next == null) return KeyEventResult.ignored;
            _set(w.items[next].value);
            _focus[next].requestFocus();
            return KeyEventResult.handled;
          },
          child: GzPressable(
            focusNode: _focus[i],
            onPressed: it.disabled ? null : () => _set(it.value),
            semanticLabel: it.label,
            selected: selected,
            builder: (context, st) => SizedBox(
              height: GzSize.controlLg,
              width: double.infinity,
              child: Padding(
                // The web item is 56 high with 8 above and 4 below: glyph 24 + 4 + label 16 = 44 (the block-size cuts the bottom padding to
                // 4, so the content overflows the padding, not the box).
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s1, start: GzSpace.s1, end: GzSpace.s1),
                child: Column(
                  children: [
                    glyph,
                    const SizedBox(height: GzSpace.s1),
                    SizedBox(
                      height: GzSpace.s4,
                      child: showLabel
                          ? Text(
                              it.label,
                              maxLines: 1,
                              softWrap: false,
                              // The web label block is 16 high and its taller line box overflows it unclipped (Arabic tails).
                              overflow: TextOverflow.visible,
                              style: gz
                                  .text(GzTextRole.tab)
                                  .copyWith(
                                    color: color,
                                    fontWeight: gz.text(GzTextRole.title).fontWeight,
                                    decoration: TextDecoration.none,
                                  ),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // A Container (not a DecoratedBox): the 1 dp baseline is a border of the list that ADDS its width to the box (web: 56 + 1, 48 + 1),
    // and the thread sits above it.
    final list = Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.borderStrong, width: GzStroke.hair),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final each = n == 0 ? 0.0 : box.maxWidth / n;
          return Stack(
            children: [
              Row(children: [for (var i = 0; i < n; i++) tab(i)]),
              AnimatedPositionedDirectional(
                duration: GzReducedMotion.movement(context, GzMotion.durationSlow),
                curve: GzMotion.easeStandard,
                start: active * each,
                width: each,
                bottom: 0,
                height: GzStroke.thread,
                child: ColoredBox(color: c.markKhayt),
              ),
            ],
          );
        },
      ),
    );
    final panel = n == 0 ? null : w.items[active].panel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(container: true, label: w.label, child: list),
        if (panel != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
            child: panel,
          ),
      ],
    );
  }
}
