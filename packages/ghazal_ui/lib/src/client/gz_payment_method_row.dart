import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show GatewayMethod;

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';

/// The ways to pay in the picker (ADR 0027). The only payments in the product are the KD 2 voucher and a partner's listing plan,
/// so there is no cash row, no deposit and no balance.
enum GzPaymentMethodKey { knet, visa, mastercard, applePay, googlePay }

/// `GatewayMethod` of the contracts has one `card`; the picker tells Visa and Mastercard apart.
GatewayMethod gzToGatewayMethod(GzPaymentMethodKey k) => switch (k) {
  GzPaymentMethodKey.visa || GzPaymentMethodKey.mastercard => GatewayMethod.card,
  GzPaymentMethodKey.knet => GatewayMethod.knet,
  GzPaymentMethodKey.applePay => GatewayMethod.applePay,
  GzPaymentMethodKey.googlePay => GatewayMethod.googlePay,
};

String _label(GzL10n l, GzPaymentMethodKey m) => switch (m) {
  GzPaymentMethodKey.knet => l.uiClientPaymentKnet,
  GzPaymentMethodKey.visa => l.uiClientPaymentVisa,
  GzPaymentMethodKey.mastercard => l.uiClientPaymentMastercard,
  GzPaymentMethodKey.applePay => l.uiClientPaymentApplePay,
  GzPaymentMethodKey.googlePay => l.uiClientPaymentGooglePay,
};

String _note(GzL10n l, GzPaymentMethodKey m) => switch (m) {
  GzPaymentMethodKey.knet => l.uiClientPaymentKnetNote,
  GzPaymentMethodKey.visa || GzPaymentMethodKey.mastercard => l.uiClientPaymentCardNote,
  GzPaymentMethodKey.applePay => l.uiClientPaymentApplePayNote,
  GzPaymentMethodKey.googlePay => l.uiClientPaymentGooglePayNote,
};

/// Typeset placeholders for the card marks (no brand artwork is copied): a name in ink on a paper tile.
String _mark(GzPaymentMethodKey m) => switch (m) {
  GzPaymentMethodKey.knet => 'KNET',
  GzPaymentMethodKey.visa => 'VISA',
  GzPaymentMethodKey.mastercard => 'MC',
  GzPaymentMethodKey.applePay => 'Pay',
  GzPaymentMethodKey.googlePay => 'G Pay',
};

/// PaymentMethodRow (CA-PAY): one way to pay as a radio row. The mark is a 56 x 32 hairline tile set in ink; selected = ink border and
/// the gold bead. [unavailable] (Apple Pay on Android) is muted, with the reason, and not a target; [note] replaces the default sub-line
/// (the KNET-failure recommendation). iOS orders Apple Pay first, Android KNET first (the caller orders the rows).
class GzPaymentMethodRow extends StatelessWidget {
  const GzPaymentMethodRow({required this.method, this.selected = false, this.onSelect, this.unavailable = false, this.note, this.last = false, this.previewState, super.key});

  final GzPaymentMethodKey method;
  final bool selected;
  final VoidCallback? onSelect;
  final bool unavailable;
  final String? note;

  /// Kept for the web signature; the rows are separate boxes, so it changes nothing.
  final bool last;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final label = _label(l, method);
    final sub = unavailable ? l.uiClientPaymentUnavailable : (note ?? _note(l, method));
    final enabled = !unavailable;
    final markStyle = gz.text(GzTextRole.figLabel).copyWith(
      fontWeight: gz.text(GzTextRole.figTitle).fontWeight,
      letterSpacing: gz.text(GzTextRole.label).letterSpacing,
      color: unavailable ? c.textDisabled : c.textStrong,
      decoration: TextDecoration.none,
    );

    Widget box(bool pressed) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
      decoration: BoxDecoration(
        color: unavailable ? c.surfaceCanvas : (pressed ? c.surfaceQuiet : c.surfaceRaised),
        borderRadius: GzRadius.mdAll,
        border: Border.all(color: unavailable ? c.borderHairline : (selected ? c.controlChipBorderSelected : c.controlChipBorder), width: GzStroke.hair),
      ),
      child: Row(
        children: [
          Container(
            width: GzSize.timelineTimeCol,
            height: GzSize.disk,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceCanvas, borderRadius: GzRadius.xsAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
            child: Directionality(textDirection: TextDirection.ltr, child: Text(_mark(method), style: markStyle, softWrap: false)),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GzText(label, role: GzTextRole.title, color: unavailable ? c.textDisabled : c.textStrong),
                GzText(sub, role: GzTextRole.caption, color: c.textSecondary),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzThreadBead(tone: selected ? GzBeadTone.gold : GzBeadTone.hollow),
        ],
      ),
    );

    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: '$label, $sub${selected ? ', ${l.uiClientPaymentSelected}' : ''}',
      onTap: enabled ? onSelect : null,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: enabled ? (onSelect ?? () {}) : null,
        borderRadius: GzRadius.mdAll,
        scale: 1,
        minHeight: 0,
        builder: (context, st) => box(st.pressed || previewState == GzPreviewState.pressed),
      ),
    );
  }
}
