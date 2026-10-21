import 'package:flutter/services.dart' show SystemUiOverlayStyle, TextInputAction;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import 'gz_bar_button.dart';
import 'gz_nav_scope.dart';
import 'gz_navigator.dart';

/// standard: back, centred title, up to two actions; hairline once content scrolls under it.
/// largeTitle: the row, then the screen title (client serif d3, partner ui-xl) that collapses into the row on scroll.
/// transparent: over a photograph: canvas disks on a scrim-top gradient; turns solid after the hero.
/// search: back + a 48 high search field in the row, actions at the end.
enum GzTopBarVariant { standard, largeTitle, transparent, search }

/// `auto` shows back when the navigator can go back, `show` always, `hide` never, `close` shows the close glyph.
enum GzTopBarBack { auto, show, hide, close }

/// A bar action (at most two: 88 wide; a third would not fit beside a title).
@immutable
class GzTopBarAction {
  const GzTopBarAction({required this.icon, required this.label, this.onPressed, this.count, this.pressed, this.iconActive});

  final IconData icon;

  /// The filled glyph of a toggle (`GzIcons.heartFill`).
  final IconData? iconActive;

  /// The accessible name.
  final String label;
  final VoidCallback? onPressed;
  final int? count;
  final bool? pressed;
}

/// The search field of the `search` variant. With [onChanged] it is a real input; without it a button that opens search ([onPressed]).
@immutable
class GzTopBarSearch {
  const GzTopBarSearch({required this.placeholder, this.value, this.onChanged, this.onPressed});

  final String placeholder;
  final String? value;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onPressed;
}

/// TopBar (direction sections 3 and 5): the 56 high bar row under the status bar (the bar includes the safe-top inset). The 20
/// gutter is carried by the bar padding (the glyph edge sits on the gutter: 20 - (44 - 24) / 2 = 10), so every screen below
/// aligns with it. The back chevron is the registry's `back` glyph, mirrored in Arabic.
///
/// The bar reads the scroll offset of its [GzScreen] ([GzScreenScroll]) for the hairline, the large-title collapse and the
/// transparent-to-solid change. [GzTopBarVariant.transparent] does not position itself: [GzScreen] (`topOverlay: true`) or a
/// `Stack` overlays it on the hero.
class GzTopBar extends StatelessWidget {
  const GzTopBar({
    this.variant = GzTopBarVariant.standard,
    this.title,
    this.subtitle,
    this.back = GzTopBarBack.auto,
    this.onBack,
    this.backLabel,
    this.actions = const [],
    this.search,
    this.leading,
    this.solidAfter,
    this.solid = false,
    this.rule,
    this.previewScrolled,
    super.key,
  });

  final GzTopBarVariant variant;
  final String? title;

  /// One caption line under a standard title (a venue's area, a booking reference).
  final String? subtitle;
  final GzTopBarBack back;

  /// Overrides the navigator's pop.
  final VoidCallback? onBack;
  final String? backLabel;
  final List<GzTopBarAction> actions;
  final GzTopBarSearch? search;

  /// Custom start content instead of the back button (a wordmark, a venue switcher).
  final Widget? leading;

  /// transparent: scroll offset after which the bar turns solid. Default = hero height under the bar.
  final double? solidAfter;

  /// transparent: draw it as already solid.
  final bool solid;

  /// Hairline under the bar: null = once content scrolls under it.
  final bool? rule;

  /// Gallery only: force the scrolled state.
  final bool? previewScrolled;

  static const double _slotUnit = GzSize.touchMin;

  /// Glyph edge on the 20 gutter: bar padding = gutter - (target - glyph) / 2.
  static const double barPad = GzSpace.gutter - (GzSize.touchMin - GzSize.iconMd) / 2;

  /// Collapse threshold of the large title (space 4).
  static const double collapseAt = GzSpace.s4;

  /// Total height of the bar for [safeTop]: safe inset + 56 (+ the large title block when expanded).
  static double heightOf(double safeTop) => safeTop + GzSize.controlLg;

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 2, 'A bar carries at most two actions');
    final gz = context.gz;
    final c = gz.colors;
    final nav = GzNavigatorScope.maybeOf(context);
    final app = GzAppScope.of(context);
    final safeTop = MediaQuery.paddingOf(context).top;
    final scrollTop = GzScreenScroll.of(context);
    final scrolled = previewScrolled ?? scrollTop > 0;

    final transparent = variant == GzTopBarVariant.transparent;
    final heroEnd = solidAfter ?? GzLayout.heroVenue - safeTop - GzSize.controlLg;
    final isSolid = transparent ? (solid || scrollTop >= heroEnd || previewScrolled == true) : true;
    final disk = transparent && !isSolid;
    final large = variant == GzTopBarVariant.largeTitle;
    final compact = large && scrollTop > collapseAt;
    final showRule = rule ?? (scrolled && (!transparent || isSolid));

    final canGoBack = nav?.canGoBack ?? Navigator.canPop(context);
    final showBack = switch (back) {
      GzTopBarBack.auto => canGoBack,
      GzTopBarBack.show || GzTopBarBack.close => true,
      GzTopBarBack.hide => false,
    };
    final closeGlyph = back == GzTopBarBack.close;
    final handleBack = onBack ?? (nav != null ? () => nav.pop() : () => Navigator.maybePop(context));
    final l10n = context.gzL10n;
    final tone = disk ? GzBarButtonTone.disk : GzBarButtonTone.plain;

    final start = leading ??
        (showBack
            ? GzBarButton(
                key: const ValueKey('gz:bar.back'),
                icon: closeGlyph ? GzIcons.close : GzIcons.back,
                label: closeGlyph ? l10n.commonActionClose : (backLabel ?? l10n.commonActionBack),
                onPressed: handleBack,
                tone: tone,
              )
            : null);
    final actionButtons = [
      for (final a in actions)
        GzBarButton(icon: a.icon, iconActive: a.iconActive, label: a.label, onPressed: a.onPressed, count: a.count, pressed: a.pressed, tone: tone),
    ];

    final slots = [if (start != null) 1, actions.length, 1].reduce((a, b) => a > b ? a : b);
    final slotWidth = slots * _slotUnit;

    final Widget row;
    if (variant == GzTopBarVariant.search && search != null) {
      row = Row(
        children: [
          ?start,
          if (start != null) const SizedBox(width: GzSpace.s1),
          Expanded(child: _SearchField(search: search!)),
          if (actionButtons.isNotEmpty) const SizedBox(width: GzSpace.s1),
          ...actionButtons,
        ],
      );
    } else {
      final fadedTitle = (large && !compact) || (transparent && !isSolid);
      row = Row(
        children: [
          SizedBox(width: slotWidth, child: Align(alignment: AlignmentDirectional.centerStart, child: start)),
          const SizedBox(width: GzSpace.s1),
          Expanded(
            child: AnimatedOpacity(
              opacity: fadedTitle ? 0 : 1,
              duration: GzReducedMotion.fade(context, GzMotion.durationBase),
              curve: GzMotion.easeStandard,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (title != null) GzText(title!, role: GzTextRole.title, color: c.textStrong, maxLines: 1, textAlign: TextAlign.center, header: true),
                  if (subtitle != null) GzText(subtitle!, role: GzTextRole.caption, color: c.textSecondary, maxLines: 1, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          const SizedBox(width: GzSpace.s1),
          SizedBox(width: slotWidth, child: Align(alignment: AlignmentDirectional.centerEnd, child: Row(mainAxisSize: MainAxisSize.min, children: actionButtons))),
        ],
      );
    }

    Widget largeBlock = const SizedBox.shrink();
    if (large && title != null) {
      final role = app == GzAppKind.client ? GzTextRole.d3 : GzTextRole.uiXl;
      final st = gz.text(role);
      final lineHeight = (st.fontSize ?? 0) * (st.height ?? 1);
      final blockHeight = lineHeight + GzSpace.s3;
      largeBlock = TweenAnimationBuilder<double>(
        tween: Tween<double>(end: compact ? 0 : 1),
        duration: GzReducedMotion.fade(context, GzMotion.durationBase),
        curve: GzMotion.easeStandard,
        builder: (context, t, child) => ClipRect(
          child: Align(alignment: AlignmentDirectional.topStart, heightFactor: t, child: SizedBox(height: blockHeight, child: child)),
        ),
        child: ExcludeSemantics(
          excluding: compact,
          child: AnimatedOpacity(
            opacity: compact ? 0 : 1,
            duration: GzReducedMotion.fade(context, GzMotion.durationBase),
            curve: GzMotion.easeStandard,
            child: Padding(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2),
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: GzText(title!, role: role, color: c.textStrong, header: true),
              ),
            ),
          ),
        ),
      );
    }

    Widget bar = AnimatedContainer(
      duration: GzReducedMotion.fade(context, GzMotion.durationBase),
      curve: GzMotion.easeStandard,
      color: disk ? c.surfaceCanvas.withAlpha(0) : c.surfaceCanvas,
      child: Stack(
        children: [
          if (transparent)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: disk ? 1 : 0,
                  duration: GzReducedMotion.fade(context, GzMotion.durationBase),
                  curve: GzMotion.easeStandard,
                  child: const DecoratedBox(decoration: BoxDecoration(gradient: GzGradient.scrimTopBar)),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsetsDirectional.only(start: barPad, end: barPad, top: safeTop),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [SizedBox(height: GzSize.controlLg, child: row), largeBlock],
            ),
          ),
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            height: GzStroke.hair,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: showRule ? 1 : 0,
                duration: GzReducedMotion.fade(context, GzMotion.durationBase),
                curve: GzMotion.easeStandard,
                child: ColoredBox(color: c.borderHairline),
              ),
            ),
          ),
        ],
      ),
    );
    if (disk) {
      // Imagery under the status bar wants light chrome until the bar turns solid.
      bar = AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light, child: bar);
    }
    return Semantics(container: true, explicitChildNodes: true, child: bar);
  }
}

/// Search field in the row: 48 high, paper, 1 dp control border, radius 8; the text is body, muted until typed.
class _SearchField extends StatefulWidget {
  const _SearchField({required this.search});

  final GzTopBarSearch search;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _controller = TextEditingController(text: widget.search.value ?? '');
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(_SearchField old) {
    super.didUpdateWidget(old);
    final v = widget.search.value ?? '';
    if (widget.search.onChanged != null && v != _controller.text) _controller.text = v;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final s = widget.search;
    final focused = _focus.hasFocus;
    final input = s.onChanged != null;
    final body = Row(
      children: [
        const GzIcon(GzIcons.search, size: GzIconSize.sm, tone: GzIconTone.secondary),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: input
              ? Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [
                    if (_controller.text.isEmpty) IgnorePointer(child: GzText(s.placeholder, role: GzTextRole.body, color: c.textSecondary, maxLines: 1)),
                    EditableText(
                      controller: _controller,
                      focusNode: _focus,
                      style: gz.text(GzTextRole.body).copyWith(color: c.textStrong, decoration: TextDecoration.none),
                      cursorColor: c.textStrong,
                      backgroundCursorColor: c.surfaceQuiet,
                      textInputAction: TextInputAction.search,
                      onChanged: (v) {
                        setState(() {});
                        s.onChanged!(v);
                      },
                    ),
                  ],
                )
              : GzText(
                  (s.value?.isNotEmpty ?? false) ? s.value! : s.placeholder,
                  role: GzTextRole.body,
                  color: (s.value?.isNotEmpty ?? false) ? c.textStrong : c.textSecondary,
                  maxLines: 1,
                ),
        ),
      ],
    );
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: c.controlBg,
        borderRadius: GzRadius.smAll,
        border: Border.all(color: focused ? c.borderFocus : c.borderControl, width: focused ? GzStroke.focus : GzStroke.hair),
      ),
      child: SizedBox(
        height: GzSize.controlMd,
        child: Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3), child: body),
      ),
    );
    if (input) return Semantics(textField: true, label: s.placeholder, child: box);
    return GzPressable(onPressed: s.onPressed ?? () {}, semanticLabel: s.placeholder, borderRadius: GzRadius.smAll, minHeight: GzSize.controlMd, child: box);
  }
}
