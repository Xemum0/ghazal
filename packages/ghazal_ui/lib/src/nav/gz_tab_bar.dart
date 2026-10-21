import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_nav_scope.dart';

/// A tab-bar badge (ADR 0007 D4, ADR 0008 D2): a gold count (9+ above the cap), a danger count only for the SLA danger state, or a
/// dot without a number (My Wedding when an action is due).
@immutable
class GzTabBadge {
  const GzTabBadge.count(this.count, {this.max = 9, this.tone = GzCountTone.gold, this.label}) : dot = false;

  /// A dot without a number.
  const GzTabBadge.dot({this.label})
      : count = 0,
        max = 9,
        tone = GzCountTone.gold,
        dot = true;

  final int count;
  final int max;
  final GzCountTone tone;
  final bool dot;

  /// Spoken with the tab name ("3 unread").
  final String? label;
}

/// One tab: a stable id, the registry glyph, the catalogue label and an optional badge.
@immutable
class GzTabItem {
  const GzTabItem({required this.id, required this.icon, required this.label, this.badge});

  final String id;
  final IconData icon;
  final String label;
  final GzTabBadge? badge;
}

/// The id and glyph of a tab of the two apps. Labels come from the apps' catalogues (`client-shell`, `hotel-shell`), root screens
/// from the inventory: only the id and the icon are shared here.
@immutable
class GzTabDef {
  const GzTabDef(this.id, this.icon);

  final String id;
  final IconData icon;
}

/// The client tabs (ADR 0007 D1): Discover, Saved, My Wedding, Messages, Profile.
const List<GzTabDef> gzClientTabs = [
  GzTabDef('discover', GzIcons.search),
  GzTabDef('saved', GzIcons.heart),
  GzTabDef('my-wedding', GzIcons.calendarCheck),
  GzTabDef('messages', GzIcons.chat),
  GzTabDef('profile', GzIcons.user),
];

/// The partner tabs (ADR 0008 D1): Today, Bookings, Calendar, Messages, More.
const List<GzTabDef> gzPartnerTabs = [
  GzTabDef('today', GzIcons.home),
  GzTabDef('bookings', GzIcons.clipboard),
  GzTabDef('calendar', GzIcons.calendar),
  GzTabDef('messages', GzIcons.chat),
  GzTabDef('more', GzIcons.more),
];

List<GzTabDef> gzTabsOf(GzAppKind app) => app == GzAppKind.client ? gzClientTabs : gzPartnerTabs;

/// TabBar (direction section 3): canvas with a 1 dp ink-200 top rule, never ink. Five items, icon + label always visible; active =
/// ink label step-up and a 24 x 2 gold khayt on the top edge that slides between items (320 ms, follows the reading direction);
/// inactive = secondary. Count badge 20 gold with a 2 dp canvas ring. Height 60 (the prototype measures it: the 56 token is the minimum and the label's line box is 20) + the home-indicator inset. The first tab is always
/// at inline-start. The bar is a pure view: the app's `StatefulShellRoute` drives [activeId] and [onSelect].
class GzTabBar extends StatelessWidget {
  const GzTabBar({
    required this.items,
    required this.activeId,
    required this.ariaLabel,
    this.onSelect,
    this.previewPressed,
    this.safeBottom,
    super.key,
  });

  final List<GzTabItem> items;
  final String activeId;
  final ValueChanged<String>? onSelect;

  /// The tab bar's accessible name.
  final String ariaLabel;

  /// Gallery only: draw the pressed state on one item.
  final String? previewPressed;

  /// Override the bottom inset (default: the home-indicator padding of the media query).
  final double? safeBottom;

  /// The bar without the inset: 60 (`GzSize.tabBar` 56 is the minimum; glyph box 32 + 4 + label line 20 + 4).
  static double heightOf(double safeBottom) => 60 + safeBottom;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final bottom = safeBottom ?? MediaQuery.paddingOf(context).bottom;
    final index = items.indexWhere((i) => i.id == activeId).clamp(0, items.length - 1);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: ariaLabel,
      child: ColoredBox(
        color: c.surfaceCanvas,
        child: Padding(
          padding: EdgeInsetsDirectional.only(bottom: bottom),
          child: LayoutBuilder(
            builder: (context, box) {
              // Formula, not a measurement: item width = bar width / item count; the khayt travels index x item width.
              final itemWidth = box.maxWidth / items.length;
              // min 56, growing with the label's line (14/20 Arabic: 60), like the web `min-block-size`.
              return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Row(
                      children: [
                        for (final item in items)
                          Expanded(
                            child: _TabCell(
                              key: ValueKey('gz:tab.${item.id}'),
                              item: item,
                              active: item.id == activeId,
                              pressedPreview: previewPressed == item.id,
                              onSelect: onSelect,
                            ),
                          ),
                      ],
                    ),
                    // The hairline is an overlay (no extra height); the khayt sits over it: the line is the place, the rule is the edge.
                    PositionedDirectional(start: 0, end: 0, top: 0, height: GzStroke.hair, child: ColoredBox(color: c.borderHairline)),
                    AnimatedPositionedDirectional(
                      key: const ValueKey('gz:tab.khayt'),
                      duration: GzReducedMotion.movement(context, GzMotion.durationSlow),
                      curve: GzMotion.easeStandard,
                      top: 0,
                      start: (index * itemWidth + (itemWidth - GzSize.khaytWidth) / 2).roundToDouble(),
                      width: GzSize.khaytWidth,
                      height: GzStroke.thread,
                      child: ColoredBox(color: c.markKhayt),
                    ),
                  ],
              );
            },
          ),
        ),
      ),
    );
  }
}

const double _labelLine = 20;

class _TabCell extends StatelessWidget {
  const _TabCell({required this.item, required this.active, required this.pressedPreview, required this.onSelect, super.key});

  final GzTabItem item;
  final bool active;
  final bool pressedPreview;
  final ValueChanged<String>? onSelect;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final badge = item.badge;
    final name = badge?.label != null ? '${item.label}, ${badge!.label}' : item.label;
    final labelStyle = gz.text(GzTextRole.tab);
    final inactiveWeight = gz.text(GzTextRole.caption).fontWeight;
    return GzPressable(
      onPressed: () => onSelect?.call(item.id),
      semanticLabel: name,
      selected: active,
      minHeight: GzSize.tabBar,
      builder: (context, st) {
        final strong = active || st.pressed || pressedPreview;
        final color = strong ? c.textStrong : c.textSecondary;
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.tabBar),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s1, end: GzSpace.s1, bottom: GzSpace.s1),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 48 x 32: the 24 glyph sits at the bottom with 8 spare above it, so the badge anchors to the top inline-end corner.
                SizedBox(
                  width: GzSpace.s12,
                  height: GzSpace.s8,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Align(alignment: Alignment.bottomCenter, child: GzIcon(item.icon, color: color)),
                      if (badge != null && badge.dot)
                        PositionedDirectional(
                          key: const ValueKey('gz:tab.badge'),
                          top: GzSpace.s1,
                          end: GzSpace.s2,
                          child: ExcludeSemantics(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: c.markKhayt,
                                borderRadius: GzRadius.pillAll,
                                boxShadow: [BoxShadow(color: c.surfaceCanvas, spreadRadius: GzStroke.thread)],
                              ),
                              child: const SizedBox.square(dimension: GzSpace.s3),
                            ),
                          ),
                        )
                      else if (badge != null)
                        PositionedDirectional(
                          key: const ValueKey('gz:tab.badge'),
                          top: 0,
                          end: GzSpace.s1,
                          child: ExcludeSemantics(child: GzCountBadge(count: badge.count, max: badge.max, tone: badge.tone, ring: true)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: GzSpace.s1),
                // The label's line box is 20 (the prototype measures 60 for the item in both languages): the text centres in it.
                SizedBox(
                  height: _labelLine,
                  child: Center(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: labelStyle.copyWith(
                        color: color,
                        fontWeight: active ? labelStyle.fontWeight : inactiveWeight,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
