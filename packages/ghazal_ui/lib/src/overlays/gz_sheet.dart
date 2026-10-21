import 'dart:math' as math;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/physics.dart' show SpringSimulation;
import 'package:flutter/widgets.dart';

import '../foundation.dart';
import '../nav/gz_bar_button.dart';
import '../nav/gz_nav_scope.dart';
import 'gz_sheet_slots.dart';

export 'gz_sheet_route.dart';
export 'gz_sheet_slots.dart';

/// Share of the frame a sheet may take (direction section 3: at most 90% height), snapped to the 4-pt grid.
const double gzSheetMaxShare = 0.9;

/// A drag past this share of the sheet's height dismisses it.
const double gzSheetDismissShare = 0.3;

/// A release faster than this (dp/s) dismisses regardless of distance.
const double gzSheetFlick = 700;

/// Upward drags are rubber-banded by this factor.
const double gzSheetRubber = 0.15;

/// Title at inline-start, close at inline-end (ADR 0014 D3). Min 48 high; the close target is 44.
class GzSheetHeader extends StatelessWidget {
  const GzSheetHeader({required this.title, this.onClose, this.closeLabel, super.key});

  final String title;
  final VoidCallback? onClose;
  final String? closeLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final role = GzAppScope.of(context) == GzAppKind.client ? GzTextRole.d1 : GzTextRole.uiTitle;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          children: [
            Expanded(child: GzText(title, role: role, color: c.textStrong, header: true)),
            if (onClose != null) ...[
              const SizedBox(width: GzSpace.s3),
              GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: closeLabel ?? context.gzL10n.commonActionClose, onPressed: onClose),
            ],
          ],
        ),
      ),
    );
  }
}

/// The modal dimmer behind a sheet or dialog (scrim-modal). [opacity] (0..1) scales the token colour's alpha, and so does `1 - dim`
/// (the share of the sheet that has been dragged away). Painted as one colour, no `Opacity` layer.
class GzScrim extends StatelessWidget {
  const GzScrim({this.opacity = const AlwaysStoppedAnimation<double>(1), this.dim, super.key});

  final Animation<double> opacity;
  final ValueListenable<double>? dim;

  @override
  Widget build(BuildContext context) {
    final base = context.gz.colors.scrimModal;
    return AnimatedBuilder(
      animation: Listenable.merge([opacity, ?dim]),
      builder: (context, _) {
        final f = (opacity.value * (1 - (dim?.value ?? 0))).clamp(0.0, 1.0);
        return ColoredBox(color: base.withValues(alpha: base.a * f));
      },
    );
  }
}

/// Sheet (direction section 3): raised paper, top radius 20, handle 36 x 4 ink-300, padding 12 / 20 / 24 + the home-indicator inset,
/// elevation 3, at most 90% of the available height. Drag down on the handle or the title row to dismiss: past 30% of its height or
/// a flick over 700 dp/s it leaves, otherwise the critically damped settle spring (ADR 0017) brings it back, continuing the
/// finger's velocity. [dragProgress] (0..1) tells the scrim to dim with the drag.
///
/// This widget is the container; the rise, the scrim and the route are [showGzSheet] / [GzSheetPage]. Without [onRequestClose] (a
/// static frame, a gallery) it does not drag and has no close button.
///
/// Spacing the sheet supplies: the 20 gutter at both sides and the bottom padding (24 + the home-indicator inset) of the body and of
/// the footer; the content passes bare widgets and adds neither. A pinned [header] is self-drawn and gets NO gutter (it draws its own,
/// like [GzSheetHeader]). [fill] makes the sheet take its full height (90 % of the frame, snapped to 4) with the body scrolling
/// between the pinned header and the pinned footer, instead of sizing to its content.
class GzSheet extends StatefulWidget {
  const GzSheet({
    required this.child,
    this.title,
    this.header,
    this.footer,
    this.fill = false,
    this.onRequestClose,
    this.dismissible = true,
    this.label,
    this.dragProgress,
    super.key,
  });

  final Widget child;

  /// Title row (a screen opened as a sheet draws its own header and passes none).
  final String? title;

  /// A self-drawn header pinned between the handle and the body (a screen opened as a sheet draws its own): no gutter is added to
  /// it. A [GzSheetPinnedHeader] inside the content publishes here too. Replaces the [title] row when both are given.
  final Widget? header;

  /// Pinned under the body (primary action row); gets the gutter, the bottom spacing and the safe-bottom inset.
  final Widget? footer;

  /// Take the full 90 % height (the body scrolls between header and footer). A [GzSheetFill] inside the content asks for it too.
  final bool fill;

  /// Close button, drag-dismiss and the Escape key ask to close; called after a drag has left the screen.
  final VoidCallback? onRequestClose;

  /// false: the sheet must be answered (unsaved guard): no drag, no close button.
  final bool dismissible;

  /// Accessible name when there is no [title].
  final String? label;
  final ValueNotifier<double>? dragProgress;

  @override
  State<GzSheet> createState() => _GzSheetState();
}

class _GzSheetState extends State<GzSheet> with SingleTickerProviderStateMixin {
  late final AnimationController _spring = AnimationController.unbounded(vsync: this)..addListener(_onSpring);
  final GlobalKey _sheetKey = GlobalKey();
  final GzSheetSlots _slots = GzSheetSlots();
  double _offset = 0;
  bool _gone = false;

  bool get _draggable => widget.dismissible && widget.onRequestClose != null;

  void _onSpring() => _setOffset(_spring.value);

  void _setOffset(double dy) {
    if (dy == _offset) return;
    setState(() => _offset = dy);
    final h = _sheetKey.currentContext?.size?.height ?? 1;
    widget.dragProgress?.value = dy <= 0 ? 0 : (dy / h).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _spring.dispose();
    _slots.dispose();
    super.dispose();
  }

  double _raw = 0;

  void _onStart(DragStartDetails d) {
    _spring.stop();
    _raw = _offset;
  }

  void _onUpdate(DragUpdateDetails d) {
    _raw += d.delta.dy;
    _setOffset(_raw < 0 ? _raw * gzSheetRubber : _raw);
  }

  void _onEnd(DragEndDetails d) {
    final h = _sheetKey.currentContext?.size?.height ?? 1;
    final dy = math.max(0.0, _offset);
    final v = d.velocity.pixelsPerSecond.dy;
    final leave = dy > h * gzSheetDismissShare || v > gzSheetFlick;
    final target = leave ? h : 0.0;
    if (GzReducedMotion.of(context)) {
      _setOffset(target);
      if (leave) _finish();
      return;
    }
    // Leaves from where the finger let go: the settle spring carries it the rest of the way out.
    _spring.value = _offset;
    _spring.animateWith(SpringSimulation(GzMotion.springSettle, _offset, target, leave ? math.max(v, 0) : v)).whenComplete(() {
      if (!mounted) return;
      _setOffset(target);
      if (leave) _finish();
    });
  }

  void _finish() {
    _gone = true;
    widget.onRequestClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final mq = MediaQuery.of(context);
    final safeBottom = mq.padding.bottom;
    final title = widget.title;
    final closeHandler = widget.dismissible ? widget.onRequestClose : null;

    final grab = SizedBox(
      key: const ValueKey('gz:sheet.grab'),
      height: GzSpace.s5,
      width: double.infinity,
      child: Align(
        alignment: AlignmentDirectional.topCenter,
        child: DecoratedBox(
          decoration: BoxDecoration(color: c.borderStrong, borderRadius: GzRadius.pillAll),
          child: const SizedBox(width: GzSize.handleWidth, height: GzSize.handleHeight),
        ),
      ),
    );

    Widget dragZoneOf(Widget? slotted) {
      final header = widget.header ?? slotted;
      Widget zone = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [grab, if (header != null) header else if (title != null) GzSheetHeader(title: title, onClose: closeHandler)],
      );
      if (_draggable) {
        zone = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: _onStart,
          onVerticalDragUpdate: _onUpdate,
          onVerticalDragEnd: _onEnd,
          child: zone,
        );
      }
      return zone;
    }

    final dragZone = ValueListenableBuilder<Widget?>(valueListenable: _slots.header, builder: (context, slotted, _) => dragZoneOf(slotted));

    // The body takes the rest in fill mode (a tight height, set below), else only what its content needs.
    Widget bodyOf(bool fill) {
      final scroll = GzSheetSlotScope(
        slots: _slots,
        child: SingleChildScrollView(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.sheetPadBottom),
          child: widget.child,
        ),
      );
      // One widget type for both modes: switching must not rebuild (and re-publish) the content below.
      return Flexible(fit: fill ? FlexFit.tight : FlexFit.loose, child: scroll);
    }

    final footer = ValueListenableBuilder<Widget?>(
      valueListenable: _slots.footer,
      builder: (context, slotted, _) {
        final f = widget.footer ?? slotted;
        if (f == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.sheetPadBottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [f]),
        );
      },
    );

    Widget panelOf(bool fill) => DecoratedBox(
          decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.sheetTop, boxShadow: GzElevation.e3),
          child: Padding(
            padding: EdgeInsetsDirectional.only(top: GzSpace.sheetPadTop, bottom: safeBottom),
            child: Column(
              mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [dragZone, bodyOf(fill), footer],
            ),
          ),
        );

    return LayoutBuilder(
      builder: (context, box) {
        final cap = box.hasBoundedHeight ? (box.maxHeight * gzSheetMaxShare / 4).floor() * 4.0 : double.infinity;
        return ValueListenableBuilder<bool?>(
          valueListenable: _slots.fill,
          builder: (context, asked, _) {
            final fill = (widget.fill || asked == true) && cap.isFinite;
            return _semantics(title, fill ? BoxConstraints.tightFor(height: cap) : BoxConstraints(maxHeight: cap), panelOf(fill));
          },
        );
      },
    );
  }

  Widget _semantics(String? title, BoxConstraints constraints, Widget panel) {
    return Builder(
      builder: (context) {
        return Semantics(
          container: true,
          explicitChildNodes: true,
          scopesRoute: true,
          namesRoute: true,
          label: title ?? widget.label,
          role: SemanticsRole.dialog,
          child: Transform.translate(
            offset: Offset(0, _gone ? math.max(_offset, 0) : _offset),
            child: ConstrainedBox(
              key: _sheetKey,
              constraints: constraints,
              child: panel,
            ),
          ),
        );
      },
    );
  }
}

