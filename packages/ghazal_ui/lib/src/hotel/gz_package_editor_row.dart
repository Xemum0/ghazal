import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, Package, PriceStructure, WirePriceUnit;

import '../core/core.dart';
import '../foundation.dart';
import '../inputs/inputs.dart';
import 'hotel_bits.dart';
import 'hotel_c_kit.dart';

/// What the phone edits of a package: both prices (fils, null while the field is not an amount or empty), the guest range, the
/// inclusions and whether the package is on offer.
@immutable
class GzPackageDraft {
  const GzPackageDraft({
    required this.priceFils,
    required this.voucherFils,
    required this.minGuests,
    required this.maxGuests,
    required this.inclusions,
    required this.active,
  });

  final int? priceFils;
  final int? voucherFils;
  final int minGuests;
  final int maxGuests;
  final List<LocalizedText> inclusions;
  final bool active;
}

/// The voucher fee: the client's saving must beat it, else no voucher is offered (ADR 0033).
const int _feeFils = 2000;

String _kdText(int fils) => fils % 1000 == 0 ? '${fils ~/ 1000}' : (fils / 1000).toStringAsFixed(3);

/// PackageEditorRow: one package in "Packages and extras" with its edit controls in place (HL-VENU-02 / 03, HA-VMGT-03 / 04). Closed
/// it is a 64+ row: the name, "KD 440 per guest, 200 to 650 guests", the active switch and the disclosure. Open it carries the
/// things the phone edits: the TWO prices of the package on the same basis (standard and voucher, ADR 0033 D4: numeric fields in KD,
/// up to three decimals, Eastern digits normalised, stored as integer fils; the voucher price must be lower and the client's saving
/// must beat the KD 2 voucher fee, the row says so in words), the minimum and maximum guests (steppers that move by the package's
/// guest step, the maximum never below the minimum) and the inclusions (removable chips plus an Add chip). Seasonal, holiday and
/// special-date prices stay on the dashboard and the row says so. Draft state lives here; the screen gets every change through
/// [onChange] and owns Save.
class GzPackageEditorRow extends StatefulWidget {
  const GzPackageEditorRow({
    required this.pkg,
    required this.priceFils,
    this.voucherFils,
    this.defaultExpanded = false,
    this.onChange,
    this.onAddInclusion,
    this.last = false,
    super.key,
  });

  final Package pkg;

  /// Weekend standard price in fils on the package's basis (from the package's price rules).
  final int priceFils;

  /// Weekend voucher price in fils on the same basis; null = the package has no voucher price.
  final int? voucherFils;
  final bool defaultExpanded;
  final ValueChanged<GzPackageDraft>? onChange;
  final VoidCallback? onAddInclusion;
  final bool last;

  @override
  State<GzPackageEditorRow> createState() => _GzPackageEditorRowState();
}

class _GzPackageEditorRowState extends State<GzPackageEditorRow> {
  late bool _open = widget.defaultExpanded;
  late String _text = _kdText(widget.priceFils);
  late String _vtext = widget.voucherFils == null ? '' : _kdText(widget.voucherFils!);
  late int _min = widget.pkg.minGuests;
  late int _max = widget.pkg.maxGuests;
  late List<LocalizedText> _inc = List.of(widget.pkg.inclusions);
  late bool _active = widget.pkg.active;

  void _emit({String? text, String? vtext, int? min, int? max, List<LocalizedText>? inc, bool? active}) {
    final f = context.gzFormat;
    final t = text ?? _text;
    final v = vtext ?? _vtext;
    widget.onChange?.call(
      GzPackageDraft(
        priceFils: gzParseKdToFils(f, t),
        voucherFils: v.trim().isEmpty ? null : gzParseKdToFils(f, v),
        minGuests: min ?? _min,
        maxGuests: max ?? _max,
        inclusions: inc ?? _inc,
        active: active ?? _active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.gzL10n;
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final pkg = widget.pkg;
    final name = pkg.name.of(lang);
    final parsed = gzParseKdToFils(f, _text);
    final vparsed = _vtext.trim().isEmpty ? null : gzParseKdToFils(f, _vtext);
    final flat = pkg.priceUnit == WirePriceUnit.flat;
    final shownPrice = parsed ?? widget.priceFils;
    final shownVoucher = vparsed ?? widget.voucherFils;
    final saving = parsed != null && vparsed != null ? parsed - vparsed : null;
    final voucherInvalid = _vtext.trim().isNotEmpty && (vparsed == null || (parsed != null && vparsed >= parsed));
    final unit = flat ? GzPriceUnit.perNight : GzPriceUnit.perGuest;
    final kd = GzText(l.uiHotelPackageKd, role: GzTextRole.label, color: c.textSecondary);
    return Container(
      decoration: gzRuleBelow(c, last: widget.last),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    expanded: _open,
                    child: GzPressable(
                      onPressed: () => setState(() => _open = !_open),
                      semanticLabel: l.uiHotelPackageEdit(name),
                      borderRadius: GzRadius.smAll,
                      scale: 1,
                      minHeight: GzSize.rowMin,
                      builder: (context, st) => Container(
                        constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                        padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
                        decoration: BoxDecoration(color: st.pressed ? c.surfaceQuiet : null, borderRadius: GzRadius.smAll),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GzUserBlock(name, role: GzTextRole.title, color: c.textStrong),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: GzSpace.s3,
                                    children: [
                                      GzPrice(
                                        fils: (shownVoucher != null && shownVoucher != 0) ? shownVoucher : shownPrice,
                                        size: GzPriceSize.card,
                                        unit: unit,
                                      ),
                                      GzFigText(
                                        l.uiHotelPackageGuests(f.integer(_min), f.integer(_max)),
                                        role: GzTextRole.caption,
                                        color: c.textSecondary,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: GzSpace.s3),
                            GzIcon(_open ? GzIcons.chevronUp : GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                GzSwitch(
                  checked: _active,
                  onChanged: (v) {
                    setState(() => _active = v);
                    _emit(active: v);
                  },
                  label: l.uiHotelPackageActiveOf(name),
                ),
              ],
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(top: GzSpace.s2, bottom: GzSpace.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GzText(
                    l.uiHotelPackageStructure(
                      pkg.priceStructure == PriceStructure.package ? l.uiHotelPackagePackage : l.uiHotelPackagePerPerson,
                    ),
                    role: GzTextRole.caption,
                    color: c.textSecondary,
                  ),
                  const SizedBox(height: GzSpace.s5),
                  GzTextField(
                    label: flat ? l.uiHotelPackagePriceFlat : l.uiHotelPackagePrice,
                    helper: l.uiHotelPackagePriceHelper,
                    error: parsed == null ? l.uiHotelPackagePriceError : null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    dir: GzFieldDir.ltr,
                    value: _text,
                    onValueChange: (v) {
                      setState(() => _text = v);
                      _emit(text: v);
                    },
                    startAdornment: kd,
                  ),
                  const SizedBox(height: GzSpace.s5),
                  GzTextField(
                    label: flat ? l.uiHotelPackageVoucherPriceFlat : l.uiHotelPackageVoucherPrice,
                    helper: saving != null && saving > 0 ? null : l.uiHotelPackageVoucherHelper,
                    error: voucherInvalid ? (vparsed == null ? l.uiHotelPackagePriceError : l.uiHotelPackageVoucherError) : null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    dir: GzFieldDir.ltr,
                    value: _vtext,
                    onValueChange: (v) {
                      setState(() => _vtext = v);
                      _emit(vtext: v);
                    },
                    startAdornment: kd,
                  ),
                  if (saving != null && saving > 0) ...[
                    const SizedBox(height: GzSpace.s5),
                    GzFigText(
                      saving > _feeFils
                          ? l.uiHotelPackageSaving(f.money(saving), flat ? '' : ' ${l.commonUnitPerGuest}')
                          : l.uiHotelPackageVoucherSmall(f.money(saving)),
                      role: GzTextRole.caption,
                      color: saving > _feeFils ? c.textSuccess : c.textSecondary,
                    ),
                  ],
                  const SizedBox(height: GzSpace.s5),
                  GzStepper(
                    label: l.uiHotelPackageMin,
                    caption: l.uiHotelPackageRule(f.integer(pkg.guestStep)),
                    value: _min,
                    min: pkg.guestStep,
                    max: _max,
                    step: pkg.guestStep,
                    onChanged: (v) {
                      setState(() => _min = v);
                      _emit(min: v);
                    },
                  ),
                  GzStepper(
                    label: l.uiHotelPackageMax,
                    value: _max,
                    min: _min,
                    max: 1500,
                    step: pkg.guestStep,
                    onChanged: (v) {
                      setState(() => _max = v);
                      _emit(max: v);
                    },
                  ),
                  const SizedBox(height: GzSpace.s5),
                  GzText(l.uiHotelPackageInclusions, role: GzTextRole.label, color: c.textPrimary),
                  const SizedBox(height: GzSpace.s2),
                  Wrap(
                    spacing: GzSpace.s2,
                    runSpacing: GzSpace.s2,
                    children: [
                      for (var k = 0; k < _inc.length; k++)
                        _InclusionChip(
                          label: _inc[k].of(lang),
                          removeLabel: l.uiHotelPackageRemove(_inc[k].of(lang)),
                          onRemove: () {
                            final next = [..._inc]..removeAt(k);
                            setState(() => _inc = next);
                            _emit(inc: next);
                          },
                        ),
                      _AddChip(label: l.uiHotelPackageAdd, onPressed: widget.onAddInclusion),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s5),
                  GzText(l.uiHotelPackageDashboard, role: GzTextRole.caption, color: c.textSecondary),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _InclusionChip extends StatelessWidget {
  const _InclusionChip({required this.label, required this.removeLabel, required this.onRemove});

  final String label;
  final String removeLabel;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s1),
      decoration: BoxDecoration(
        color: c.controlBg,
        borderRadius: GzRadius.smAll,
        border: Border.all(color: c.controlChipBorder, width: GzStroke.hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: gzUserStyle(label, GzTextRole.bodyS, c.textPrimary),
              textDirection: gzFirstStrongOr(label, Directionality.of(context)),
            ),
          ),
          const SizedBox(width: GzSpace.s1),
          GzPressable(
            onPressed: onRemove,
            semanticLabel: removeLabel,
            borderRadius: GzRadius.smAll,
            child: SizedBox(
              width: GzSize.touchMin,
              height: GzSize.touchMin,
              child: Center(
                child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.iconSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  const _AddChip({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return GzPressable(
      onPressed: onPressed ?? () {},
      semanticLabel: label,
      borderRadius: GzRadius.smAll,
      builder: (context, st) => Container(
        constraints: const BoxConstraints(minHeight: GzSize.touchMin),
        padding: const EdgeInsets.symmetric(horizontal: GzSpace.s3),
        decoration: BoxDecoration(
          color: st.pressed ? c.surfaceQuiet : c.controlBg,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: c.controlChipBorder, width: GzStroke.hair),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GzIcon(GzIcons.plus, size: GzIconSize.xs, color: c.actionTertiaryLabel),
            const SizedBox(width: GzSpace.s2),
            Text(
              label,
              style: gzResetLabelStyle(context.gz).copyWith(color: c.actionTertiaryLabel, decoration: TextDecoration.none),
            ),
          ],
        ),
      ),
    );
  }
}
