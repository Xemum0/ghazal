// Small shared pieces of the provider screens (web `provider/_components/bits.tsx` and `fields.tsx`): an in-flow note (tint, never a border),
// the inline field error, a bilingual field pair with its completeness marker, and the KD price field that keeps integer fils.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show MoneyOptions;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/listing_draft.dart';

enum NoteTone { info, danger, success, quiet }

/// A quiet in-flow message: an icon, the sentence, an optional action under it. Tint, never a border.
class ProvNote extends StatelessWidget {
  const ProvNote({required this.text, this.tone = NoteTone.info, this.icon, this.actionLabel, this.onAction, this.figures = false, super.key});

  final String text;
  final NoteTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool figures;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final bg = switch (tone) {
      NoteTone.danger => c.statusDangerBg,
      NoteTone.success => c.statusSuccessBg,
      NoteTone.quiet => c.surfaceQuiet,
      NoteTone.info => c.surfaceTintSoft,
    };
    final glyph = icon ??
        switch (tone) {
          NoteTone.danger => GzIcons.warningCircle,
          NoteTone.success => GzIcons.checkCircle,
          _ => GzIcons.info,
        };
    final iconColor = switch (tone) {
      NoteTone.danger => c.iconDanger,
      NoteTone.success => c.iconSuccess,
      NoteTone.quiet => c.iconSecondary,
      NoteTone.info => c.iconAccent,
    };
    return Semantics(
      container: true,
      liveRegion: tone == NoteTone.danger,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: GzRadius.smAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(glyph, size: GzIconSize.sm, color: iconColor)),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzText(text, role: GzTextRole.bodyS, color: tone == NoteTone.danger ? c.statusDangerText : c.textPrimary, figures: figures),
                    if (actionLabel != null) GzButton(label: actionLabel!, variant: GzButtonVariant.tertiary, onPressed: onAction),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// An inline message under a control: glyph and words, danger ink (state is never colour alone).
class FieldError extends StatelessWidget {
  const FieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger)),
        const SizedBox(width: GzSpace.s2),
        Expanded(child: GzText(text, role: GzTextRole.caption, color: c.textDanger)),
      ],
    );
  }
}

/// Arabic and English completeness: both are required before a listing goes to review (PA-LST-02).
class Completeness extends StatelessWidget {
  const Completeness({required this.ar, required this.en, super.key});

  final bool ar;
  final bool en;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget item(bool done, String label) {
      final c = context.gz.colors;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GzIcon(done ? GzIcons.checkCircle : GzIcons.clock, size: GzIconSize.xs, color: done ? c.iconSuccess : c.iconSecondary),
          const SizedBox(width: GzSpace.s1),
          GzText(label, role: GzTextRole.caption, color: done ? c.textSuccess : c.textSecondary),
        ],
      );
    }

    return Semantics(
      container: true,
      liveRegion: true,
      child: Wrap(
        spacing: GzSpace.s4,
        runSpacing: GzSpace.s1,
        children: [item(ar, l.hotelProviderLangArabic), item(en, l.hotelProviderLangEnglish)],
      ),
    );
  }
}

/// The current language's field first, then the other; one completeness marker under the pair.
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
    this.rows = 3,
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
  final int rows;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    Widget field(String code) {
      final value = code == 'ar' ? ar : en;
      final set = code == 'ar' ? onAr : onEn;
      final error = code == 'ar' ? errorAr : errorEn;
      final name = code == 'ar' ? l.hotelProviderFieldInArabic(label) : l.hotelProviderFieldInEnglish(label);
      return multiline
          ? GzTextArea(key: ValueKey('f-$code'), label: name, lang: code, value: value, onValueChange: set, error: error, maxLength: maxLength, rows: rows)
          : GzTextField(key: ValueKey('f-$code'), label: name, lang: code, value: value, onValueChange: set, error: error, maxLength: maxLength);
    }

    final order = lang == 'ar' ? ['ar', 'en'] : ['en', 'ar'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final code in order) ...[field(code), const SizedBox(height: GzSpace.s3)],
        Completeness(ar: ar.trim().isNotEmpty, en: en.trim().isNotEmpty),
      ],
    );
  }
}

/// A KD amount: numeric keypad, Eastern digits normalised, up to three decimals, stored as integer fils.
class PriceField extends StatefulWidget {
  const PriceField({required this.label, required this.fils, required this.onChanged, this.error, super.key});

  final String label;
  final int? fils;
  final ValueChanged<int?> onChanged;
  final String? error;

  @override
  State<PriceField> createState() => _PriceFieldState();
}

class _PriceFieldState extends State<PriceField> {
  late String _text = kdText(widget.fils);

  @override
  void didUpdateWidget(PriceField old) {
    super.didUpdateWidget(old);
    final parsed = parseKd(context.gzFormat, _text);
    if (widget.fils != null && widget.fils != parsed) _text = kdText(widget.fils);
  }

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final parsed = parseKd(f, _text);
    final invalid = _text.trim().isNotEmpty && parsed == null;
    return GzTextField(
      label: widget.label,
      value: _text,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      error: widget.error ?? (invalid ? context.l10n.hotelProviderPriceError : null),
      dir: GzFieldDir.ltr,
      startAdornment: GzText(f.moneyParts(0, const MoneyOptions()).currency, role: GzTextRole.label, color: context.gz.colors.textSecondary),
      onValueChange: (v) {
        setState(() => _text = v);
        widget.onChanged(parseKd(f, v));
      },
    );
  }
}
