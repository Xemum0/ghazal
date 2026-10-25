// Form pieces of the venue editors (web `fields.tsx`): the bilingual field pair with its completeness chip, the sheet column with a pinned
// footer, the language chip and the time labels. Times are Kuwait times, never converted to the device zone.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_ui/ghazal_ui.dart';

import 'venue_bits.dart';

import '../../../../l10n/l10n.dart';

/// `4:00 PM` of an `HH:mm` string in Kuwait time, written by the shared formatter.
String kuwaitTime(GzFormat f, String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = int.tryParse(parts.last) ?? 0;
  return f.time(DateTime.utc(2027, 1, 14, h, m).subtract(const Duration(hours: 3)));
}

/// Start and end choices every half hour.
final List<String> kTimeSlots = <String>[for (var i = 0; i < 48; i++) '${(i ~/ 2).toString().padLeft(2, '0')}:${i.isEven ? '00' : '30'}'];

/// A quiet tone label with a glyph: which language still misses something (a to-do, not an error).
class LangChip extends StatelessWidget {
  const LangChip({required this.arGaps, required this.enGaps, super.key});

  final int arGaps;
  final int enGaps;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final complete = arGaps == 0 && enGaps == 0;
    final text = [if (arGaps != 0) l.hotelVenueLangArMissing(arGaps), if (enGaps != 0) l.hotelVenueLangEnMissing(enGaps)].join(' · ');
    return Semantics(
      label: complete ? l.hotelVenueLangBoth : null,
      child: Container(
        constraints: const BoxConstraints(minHeight: GzSize.pillMin),
        padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s3),
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
              child: GzIcon(complete ? GzIcons.check : GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconSecondary),
            ),
            if (!complete) ...[
              const SizedBox(width: GzSpace.s2),
              Flexible(
                child: GzText(text, role: GzTextRole.caption, color: c.textPrimary, figures: true),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The current language's field first, then the other; one completeness chip under the pair.
class BilingualField extends StatelessWidget {
  const BilingualField({
    required this.label,
    required this.ar,
    required this.en,
    required this.onAr,
    required this.onEn,
    this.multiline = false,
    this.errorAr,
    this.errorEn,
    this.maxLength,
    this.required = true,
    super.key,
  });

  final String label;
  final String ar;
  final String en;
  final ValueChanged<String> onAr;
  final ValueChanged<String> onEn;
  final bool multiline;
  final String? errorAr;
  final String? errorEn;
  final int? maxLength;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isAr = context.gz.locale.languageCode == 'ar';
    Widget field(bool arabic) {
      final name = arabic ? l.hotelVenueFieldInArabic(label) : l.hotelVenueFieldInEnglish(label);
      final value = arabic ? ar : en;
      final set = arabic ? onAr : onEn;
      final error = arabic ? errorAr : errorEn;
      return multiline
          ? GzTextArea(
              key: ValueKey('$label.${arabic ? 'ar' : 'en'}'),
              label: name,
              lang: arabic ? 'ar' : 'en',
              rows: 3,
              maxLength: maxLength,
              defaultValue: value,
              onValueChange: set,
              error: error,
            )
          : GzTextField(
              key: ValueKey('$label.${arabic ? 'ar' : 'en'}'),
              label: name,
              lang: arabic ? 'ar' : 'en',
              maxLength: maxLength,
              defaultValue: value,
              onValueChange: set,
              error: error,
            );
    }

    final order = isAr ? [true, false] : [false, true];
    return Semantics(
      container: true,
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          field(order[0]),
          const SizedBox(height: GzSpace.s3),
          field(order[1]),
          if (required) ...[
            const SizedBox(height: GzSpace.s3),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LangChip(arGaps: ar.trim().isEmpty ? 1 : 0, enGaps: en.trim().isEmpty ? 1 : 0),
            ),
          ],
        ],
      ),
    );
  }
}

/// The sheet column: a scrolling body and a pinned footer under a hairline.
class SheetColumn extends StatelessWidget {
  const SheetColumn({required this.children, required this.footer, super.key});

  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
            ),
          ),
          child: footer,
        ),
      ],
    );
  }
}

/// A select that opens its choices in a sheet (the web `SelectRow`).
class PickRow<V> extends StatelessWidget {
  const PickRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.variant = GzSelectVariant.field,
    this.sheetTitle,
    this.helper,
    this.startAdornment,
    this.disabled = false,
    super.key,
  });

  final String label;
  final V? value;
  final List<GzSelectOption<V>> options;
  final ValueChanged<V> onChanged;
  final GzSelectVariant variant;
  final String? sheetTitle;
  final String? helper;
  final Widget? startAdornment;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    return GzSelectRow<V>(
      label: label,
      options: options,
      values: [if (value != null) value as V],
      variant: variant,
      helper: helper,
      startAdornment: startAdornment,
      disabled: disabled,
      onTap: disabled
          ? null
          : () => nav.openSheetBuilder(
              (_) => GzPickerList<V>(
                options: options,
                selected: [if (value != null) value as V],
                onPick: (v) {
                  nav.closeSheet();
                  onChanged(v);
                },
              ),
              options: GzSheetOptions(title: sheetTitle ?? label),
            ),
    );
  }
}

/// A KD amount with the currency at its start: numeric keypad, Eastern digits normalised, up to three decimals, integer fils (ADR 0010).
class PriceField extends StatefulWidget {
  const PriceField({required this.label, required this.fils, required this.onChanged, this.helper, this.error, this.disabled = false, super.key});

  final String label;
  final int? fils;
  final ValueChanged<int?> onChanged;
  final String? helper;
  final String? error;
  final bool disabled;

  @override
  State<PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<PriceField> {
  String _text = '';
  bool _seeded = false;

  String _write(GzFormat f, int? fils) {
    if (fils == null) return '';
    final whole = fils ~/ 1000;
    final frac = fils % 1000;
    final digits = frac == 0 ? '' : '.${frac.toString().padLeft(3, '0').replaceFirst(RegExp(r'0+$'), '')}';
    return f.digits('$whole$digits');
  }

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    if (!_seeded) {
      _text = _write(f, widget.fils);
      _seeded = true;
    }
    final invalid = _text.trim().isNotEmpty && parseFils(_text) == null;
    return GzTextField(
      label: widget.label,
      helper: widget.helper,
      error: widget.error ?? (invalid ? context.l10n.hotelVenuePriceError : null),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      dir: GzFieldDir.ltr,
      disabled: widget.disabled,
      defaultValue: _text,
      onValueChange: (v) {
        _text = v;
        widget.onChanged(parseFils(v));
      },
      startAdornment: GzText(f.moneyParts(0).currency, role: GzTextRole.label, color: context.gz.colors.textSecondary),
    );
  }
}

/// An inline message under a control: glyph and words in the danger tone (state is never colour alone).
class FormError extends StatelessWidget {
  const FormError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => FactLine(text, icon: GzIcons.warningCircle, danger: true);
}

/// A guest count: the stepper and a rail of preset chips under it.
class GuestPicker extends StatelessWidget {
  const GuestPicker({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.step,
    required this.presets,
    this.caption,
    this.error,
    super.key,
  });

  final String label;
  final String? caption;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final int step;
  final List<int> presets;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzStepper(label: label, caption: caption, value: value, min: min, max: max, step: step, onChanged: onChanged),
        const SizedBox(height: GzSpace.s2),
        GzChipGroup<int>(
          label: label,
          layout: GzChipLayout.rail,
          value: presets.contains(value) ? value : null,
          onChanged: (v) => v == null ? null : onChanged(v),
          options: [
            for (final p in presets)
              GzChipOption<int>(value: p, label: '${f.integer(p)}${p == presets.last ? '+' : ''}', disabled: p < min || p > max),
          ],
        ),
        if (error != null) ...[const SizedBox(height: GzSpace.s2), FormError(error!)],
      ],
    );
  }
}
