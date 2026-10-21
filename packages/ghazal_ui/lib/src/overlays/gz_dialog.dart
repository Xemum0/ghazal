import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'dart:ui' show SemanticsRole;

import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../nav/gz_nav_scope.dart';
import '../nav/gz_navigator.dart';

/// Dialog (direction section 3, panel anatomy): a centred paper card, radius 12, hairline ring plus the floating shadow. Title
/// (client serif d1, partner ui-title), body-s, then stacked actions: the confirm (gold primary, or the destructive tint) above a
/// secondary cancel. Stacked, not a row, so the labels never compete for 150 dp in Arabic. A dialog states its consequence in the
/// body; it never carries marketing and never stacks on another dialog.
///
/// This is the card. The scrim, the centring, the 200 ms fade and the route are [showGzDialog]; in a gallery or a static frame the
/// card is placed directly.
class GzDialog extends StatelessWidget {
  const GzDialog({
    required this.title,
    this.body,
    this.icon,
    this.confirmLabel,
    this.cancelLabel,
    this.showCancel = true,
    this.tone = GzDialogTone.standard,
    this.onConfirm,
    this.onCancel,
    super.key,
  });

  GzDialog.fromSpec(GzDialogSpec spec, {this.onConfirm, this.onCancel, super.key})
      : title = spec.title,
        body = spec.body,
        icon = spec.icon,
        confirmLabel = spec.confirmLabel,
        cancelLabel = spec.cancelLabel,
        showCancel = spec.showCancel,
        tone = spec.tone;

  final String title;
  final String? body;
  final IconData? icon;

  /// Default: the shared "Confirm".
  final String? confirmLabel;

  /// Default: the shared "Cancel".
  final String? cancelLabel;

  /// false: an acknowledgement, one button.
  final bool showCancel;
  final GzDialogTone tone;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.gzL10n;
    final destructive = tone == GzDialogTone.destructive;
    final role = GzAppScope.of(context) == GzAppKind.client ? GzTextRole.d1 : GzTextRole.uiTitle;
    final children = <Widget>[
      if (icon != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: DecoratedBox(
            key: const ValueKey('gz:dialog.icon'),
            decoration: BoxDecoration(shape: BoxShape.circle, color: destructive ? c.statusDangerBg : c.surfaceTint),
            child: SizedBox.square(
              dimension: GzSize.controlMd,
              child: Center(child: GzIcon(icon!, color: destructive ? c.iconDanger : c.iconPrimary)),
            ),
          ),
        ),
      GzText(title, role: role, color: c.textStrong, header: true),
      if (body != null) GzText(body!, role: GzTextRole.bodyS, color: c.textPrimary),
      Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzButton(
              label: confirmLabel ?? l10n.commonActionConfirm,
              onPressed: onConfirm ?? () {},
              variant: destructive ? GzButtonVariant.destructive : GzButtonVariant.primary,
              fullWidth: true,
            ),
            if (showCancel) ...[
              const SizedBox(height: GzSpace.s3),
              GzButton(label: cancelLabel ?? l10n.commonActionCancel, onPressed: onCancel ?? () {}, variant: GzButtonVariant.secondary, fullWidth: true),
            ],
          ],
        ),
      ),
    ];
    // gap 12 between the blocks
    final spaced = <Widget>[for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s3), children[i]]];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      label: title,
      role: SemanticsRole.alertDialog,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.mdAll,
          border: Border.all(color: c.borderStrong, width: GzStroke.hair),
          boxShadow: GzElevation.e2,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.all(GzSpace.s5),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: spaced),
        ),
      ),
    );
  }
}

/// The route of a dialog: scrim-modal barrier, the card centred inside the gutters, a 200 ms fade in and a 120 ms fade out. A
/// scrim tap does not dismiss; the system back and Escape cancel when the dialog has a cancel button.
class GzDialogRoute extends PopupRoute<GzDialogResult> {
  GzDialogRoute({required this.spec, required this.scrimColor, super.settings});

  final GzDialogSpec spec;
  final Color scrimColor;

  @override
  Duration get transitionDuration => GzMotion.durationBase;

  @override
  Duration get reverseTransitionDuration => GzMotion.durationFast;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => scrimColor;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final cancellable = spec.showCancel;
    void answer(GzDialogResult r) => Navigator.of(context).pop(r);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && cancellable) answer(GzDialogResult.cancel);
      },
      child: CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          if (cancellable) const SingleActivator(LogicalKeyboardKey.escape): () => answer(GzDialogResult.cancel),
        },
        child: FocusScope(
          autofocus: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            child: Center(
              child: GzDialog.fromSpec(spec, onConfirm: () => answer(GzDialogResult.confirm), onCancel: () => answer(GzDialogResult.cancel)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
    final reduced = GzReducedMotion.of(context);
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: reduced ? GzMotion.easeLinear : GzMotion.easeStandard, reverseCurve: GzMotion.easeExit.flipped),
      child: child,
    );
  }
}

/// Opens a dialog and resolves with the choice. A system back (or Escape) answers [GzDialogResult.cancel] when there is a cancel
/// button; an acknowledgement has none and can only be confirmed.
Future<GzDialogResult> showGzDialog(BuildContext context, GzDialogSpec spec, {bool useRootNavigator = true}) async {
  final route = GzDialogRoute(spec: spec, scrimColor: context.gz.colors.scrimModal);
  final result = await Navigator.of(context, rootNavigator: useRootNavigator).push<GzDialogResult>(route);
  return result ?? GzDialogResult.cancel;
}
