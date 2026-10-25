// PackageCards and PackageSheet (web `PackageCards.tsx`): the packages of a listing, each with a standard price and a voucher price on the same
// basis (per person or per package), and the sheet that edits one. A voucher is offered only when the saving beats the voucher fee
// (voucher-model 4.1); otherwise the package says so, in words, before a client could ever see it.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText, PriceStructure;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/listing_draft.dart';
import 'prov_bits.dart';

class PackageCards extends StatelessWidget {
  const PackageCards({required this.packages, required this.feeFils, required this.onEdit, required this.onAdd, this.error = false, super.key});

  final List<PackageDraft> packages;
  final int feeFils;
  final ValueChanged<PackageDraft> onEdit;
  final VoidCallback onAdd;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in packages) ...[
          RepaintBoundary(
            child: GzPressable(
              onPressed: () => onEdit(p),
              semanticLabel: p.nameIn(lang).isEmpty ? l.hotelProviderPkgUnnamed : p.nameIn(lang),
              borderRadius: GzRadius.mdAll,
              minHeight: 0,
              child: Container(
                padding: GzSpace.panel,
                decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderStrong, width: GzStroke.hair)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: GzUserText(p.nameIn(lang).isEmpty ? l.hotelProviderPkgUnnamed : p.nameIn(lang), role: GzTextRole.title, color: c.textStrong)),
                        const SizedBox(width: GzSpace.s3),
                        GzText(p.structure == PriceStructure.perPerson ? g.commonPricingPerPerson : g.commonPricingPackage, role: GzTextRole.caption, color: c.textSecondary),
                        const SizedBox(width: GzSpace.s3),
                        GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
                      ],
                    ),
                    const SizedBox(height: GzSpace.s3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _PriceCell(label: g.commonStandardPrice, fils: p.standardFils, notDecided: g.commonLabelNotDecided),
                        const SizedBox(width: GzSpace.s6),
                        _PriceCell(label: g.commonVoucherPrice, fils: p.voucherFils, notDecided: g.commonLabelNotDecided),
                      ],
                    ),
                    if (p.savingFils != null) ...[
                      const SizedBox(height: GzSpace.s3),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
                            child: p.voucherOffered(feeFils) ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.iconSuccess) : GzIcon(GzIcons.info, size: GzIconSize.xs, color: c.iconSecondary),
                          ),
                          const SizedBox(width: GzSpace.s2),
                          Expanded(
                            child: GzText(
                              p.voucherOffered(feeFils) ? g.commonYouSave(f.money(p.savingFils!)) : l.hotelProviderPkgNoVoucher,
                              role: GzTextRole.caption,
                              color: p.voucherOffered(feeFils) ? c.textSuccess : c.textSecondary,
                              figures: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: GzSpace.s3),
        ],
        if (error) ...[FieldError(l.hotelProviderPkgNeeded), const SizedBox(height: GzSpace.s3)],
        GzButton(label: l.hotelProviderPkgAdd, variant: GzButtonVariant.secondary, iconStart: GzIcons.plus, onPressed: onAdd),
      ],
    );
  }
}

class _PriceCell extends StatelessWidget {
  const _PriceCell({required this.label, required this.fils, required this.notDecided});

  final String label;
  final int? fils;
  final String notDecided;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GzText(label, role: GzTextRole.caption, color: c.textSecondary),
        const SizedBox(height: GzSpace.s1),
        if (fils != null) GzPrice(fils: fils!, size: GzPriceSize.strong) else GzText(notDecided, role: GzTextRole.bodyS, color: c.textStrong),
      ],
    );
  }
}

/// The body of the package sheet: both names, the basis, both prices with the saving line, the inclusions. Save validates; Delete only
/// leaves the listing (the provider package itself stays).
class PackageSheetBody extends StatefulWidget {
  const PackageSheetBody({required this.initial, required this.isNew, required this.feeFils, required this.onSave, this.onDelete, super.key});

  final PackageDraft initial;
  final bool isNew;
  final int feeFils;
  final ValueChanged<PackageDraft> onSave;
  final VoidCallback? onDelete;

  @override
  State<PackageSheetBody> createState() => _PackageSheetBodyState();
}

class _PackageSheetBodyState extends State<PackageSheetBody> {
  late PackageDraft _d = widget.initial;
  String _typed = '';
  int _typedKey = 0;
  bool _tried = false;

  void _addInclusion() {
    final v = _typed.trim();
    final lang = context.gz.locale.languageCode;
    if (v.isEmpty || _d.includes.any((i) => i.of(lang) == v) || _d.includes.length >= 8) return;
    final item = isArabicText(v) ? LocalizedText(ar: v) : LocalizedText(en: v);
    setState(() {
      _d = _d.copyWith(includes: [..._d.includes, item]);
      _typed = '';
      _typedKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final g = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final d = _d;
    final saving = d.savingFils;
    final over = d.standardFils != null && d.voucherFils != null && d.voucherFils! > d.standardFils!;
    final required = l.hotelProviderRequired;
    final basis = d.structure == PriceStructure.perPerson ? g.commonUnitPerGuest : l.hotelProviderPkgPerPackage;
    final offered = d.voucherOffered(widget.feeFils);
    final ok = d.complete;
    Widget gap([double h = GzSpace.s4]) => SizedBox(height: h);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        BilingualField(
          label: l.hotelProviderPkgName,
          ar: d.nameAr,
          en: d.nameEn,
          onAr: (v) => setState(() => _d = d.copyWith(nameAr: v)),
          onEn: (v) => setState(() => _d = d.copyWith(nameEn: v)),
          errorAr: _tried && d.nameAr.trim().isEmpty ? required : null,
          errorEn: _tried && d.nameEn.trim().isEmpty ? required : null,
          maxLength: 48,
        ),
        gap(),
        GzText(g.commonPricingStructure, role: GzTextRole.label, color: c.textSecondary),
        gap(GzSpace.s2),
        GzPricingStructureToggle(
          value: d.structure == PriceStructure.perPerson ? GzPricingStructure.perPerson : GzPricingStructure.package,
          onChanged: (v) => setState(() => _d = d.copyWith(structure: v == GzPricingStructure.perPerson ? PriceStructure.perPerson : PriceStructure.package)),
        ),
        gap(),
        PriceField(
          label: '${g.commonStandardPrice} · $basis',
          fils: d.standardFils,
          onChanged: (v) => setState(() => _d = d.copyWith(standardFils: v)),
          error: _tried && (d.standardFils == null || d.standardFils! <= 0) ? required : null,
        ),
        gap(),
        PriceField(
          label: '${g.commonVoucherPrice} · $basis',
          fils: d.voucherFils,
          onChanged: (v) => setState(() => _d = d.copyWith(voucherFils: v)),
          error: over ? l.hotelProviderPkgVoucherOver : (_tried && d.voucherFils == null ? required : null),
        ),
        if (saving != null && !over) ...[
          gap(),
          Semantics(
            liveRegion: true,
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
              decoration: BoxDecoration(color: offered ? c.statusSuccessBg : c.surfaceQuiet, borderRadius: GzRadius.smAll),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(offered ? GzIcons.checkCircle : GzIcons.info, size: GzIconSize.sm, color: offered ? c.iconSuccess : c.iconSecondary)),
                  const SizedBox(width: GzSpace.s3),
                  Expanded(
                    child: GzText(
                      offered ? l.hotelProviderPkgSaving(f.money(saving)) : l.hotelProviderPkgNoVoucherFull(f.money(widget.feeFils)),
                      role: GzTextRole.bodyS,
                      color: c.textPrimary,
                      figures: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        gap(),
        GzText(l.hotelProviderPkgIncludes, role: GzTextRole.label, color: c.textSecondary),
        gap(GzSpace.s2),
        if (d.includes.isNotEmpty) ...[
          Wrap(
            spacing: GzSpace.s2,
            runSpacing: GzSpace.s2,
            children: [
              for (var i = 0; i < d.includes.length; i++)
                Container(
                  constraints: const BoxConstraints(minHeight: GzSize.touchMin),
                  padding: const EdgeInsetsDirectional.only(start: GzSpace.s3, end: GzSpace.s1),
                  decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.smAll, border: Border.all(color: c.controlChipBorder, width: GzStroke.hair)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(child: GzUserText(d.includes[i].of(lang), role: GzTextRole.bodyS)),
                      const SizedBox(width: GzSpace.s2),
                      GzPressable(
                        onPressed: () => setState(() => _d = d.copyWith(includes: [...d.includes]..removeAt(i))),
                        semanticLabel: l.hotelProviderPkgRemoveIncl(d.includes[i].of(lang)),
                        child: Center(child: GzIcon(GzIcons.close, size: GzIconSize.xs, color: c.iconSecondary)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          gap(GzSpace.s2),
        ],
        GzTextField(
          key: ValueKey('incl-$_typedKey'),
          label: l.hotelProviderPkgInclPlaceholder,
          value: _typed,
          maxLength: 60,
          onValueChange: (v) => setState(() => _typed = v),
          onSubmitted: (_) => _addInclusion(),
          endAdornment: GzButton(label: g.commonActionAdd, variant: GzButtonVariant.tertiary, onPressed: _typed.trim().isEmpty ? null : _addInclusion),
        ),
        gap(),
        GzSheetFooter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzButton(
                label: l.hotelProviderPkgSave,
                fullWidth: true,
                onPressed: () {
                  if (!ok) {
                    setState(() => _tried = true);
                    return;
                  }
                  widget.onSave(d);
                },
              ),
              if (widget.onDelete != null && !widget.isNew) ...[
                const SizedBox(height: GzSpace.s2),
                GzButton(label: l.hotelProviderPkgDelete, variant: GzButtonVariant.tertiary, fullWidth: true, onPressed: widget.onDelete),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
