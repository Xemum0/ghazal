import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_ui/ghazal_ui.dart';

/// The header of the quote sheet (web `SheetHeader` with the provider as its title): the category glyph in a rose disk and the name in
/// the title role (not the display role of a sentence title), the close button at the end. "Request quote" is only the sheet's accessible
/// name. The sheet draws no gutter around a pinned header, so both gutters are drawn here.
class QuoteHead extends StatelessWidget {
  const QuoteHead({required this.name, required this.glyph, required this.accessibleTitle, required this.onClose, super.key});

  final String name;
  final IconData glyph;
  final String accessibleTitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Padding(
        // The web header sits inside the sheet body (its own gutter) and wears its own start gutter and end 8 on top of it.
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter * 2, end: GzSpace.gutter + GzSpace.s2),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                label: '$accessibleTitle, $name',
                excludeSemantics: true,
                child: Row(
                  children: [
                    SizedBox(
                      width: GzSpace.s8,
                      height: GzSpace.s8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                        child: Center(child: GzIcon(glyph, size: GzIconSize.sm, color: c.textStrong)),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(
                      child: GzText(name, role: GzTextRole.title, color: c.textStrong, maxLines: 1),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GzSpace.s3),
            GzBarButton(key: const ValueKey('gz:sheet.close'), icon: GzIcons.close, label: context.gzL10n.commonActionClose, onPressed: onClose),
          ],
        ),
      ),
    );
  }
}

/// A field whose name is the accessible name only (ADR 0034: the glyph is the label): the visible label row of the kit field is left
/// out and the name is read as a container label around it.
class QuoteNamed extends StatelessWidget {
  const QuoteNamed({required this.name, required this.child, super.key});

  final String name;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(container: true, explicitChildNodes: true, label: name, child: child);
}

/// The date field of the quote sheet (web `DatePick`): the kit date field with the compact value (`14 Jan 2027`, no weekday) because a
/// row that already wears the calendar glyph needs none. Flow-local twin until the kit `GzDateField` takes a compact format.
class QuoteDateField extends StatefulWidget {
  const QuoteDateField({required this.value, required this.placeholder, required this.onTap, this.error, this.disabled = false, super.key});

  final String? value;
  final String placeholder;
  final VoidCallback? onTap;
  final String? error;
  final bool disabled;

  @override
  State<QuoteDateField> createState() => _QuoteDateFieldState();
}

class _QuoteDateFieldState extends State<QuoteDateField> {
  final FocusNode _focus = FocusNode(debugLabel: 'quote-date');
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final c = context.gz.colors;
    final f = context.gzFormat;
    final has = w.value != null;
    final text = has ? f.date(w.value!, DateStyle.compact) : w.placeholder;
    final enabled = !w.disabled && w.onTap != null;
    final spoken = has ? f.plain(f.date(w.value!, DateStyle.full)) : w.placeholder;
    return GzFieldShell(
      error: w.error,
      disabled: w.disabled,
      focused: _focused,
      startAdornment: const GzIcon(GzIcons.calendar, size: GzIconSize.sm),
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: spoken,
        hint: w.error,
        onTap: enabled ? w.onTap : null,
        excludeSemantics: true,
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: _focus,
          onFocusChange: (v) => setState(() => _focused = v),
          shortcuts: {
            const SingleActivator(LogicalKeyboardKey.enter): const ActivateIntent(),
            const SingleActivator(LogicalKeyboardKey.space): const ActivateIntent(),
          },
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => w.onTap?.call())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? w.onTap : null,
            child: SizedBox(
              height: double.infinity,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: GzText(text, role: GzTextRole.body, color: w.disabled ? c.textDisabled : (has ? c.textStrong : c.textSecondary), figures: has, maxLines: 1),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
