import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;

import '../core/core.dart';
import '../foundation.dart';
import 'gz_calendar.dart';
import 'gz_calendar_model.dart';
import 'gz_field_shell.dart';

/// The title of the sheet a date field opens: "Choose a date" / "Choose dates".
String gzDateFieldSheetTitle(BuildContext context, {bool range = false}) =>
    range ? context.gzL10n.uiInputsDateFieldChooseDates : context.gzL10n.uiInputsDateFieldChooseDate;

/// Date field (web `DateField`): a 56 high input-like button showing the date (or range) with a calendar glyph. It opens the
/// calendar in a bottom sheet (no native date input, ADR 0011 D5 / ADR 0024): this widget draws the closed field and calls [onTap];
/// the sheet host (navigation group) shows [GzDateFieldSheetContent] under the title [gzDateFieldSheetTitle] and passes [open] back
/// while it is up so the field keeps its focus look.
class GzDateField extends StatefulWidget {
  const GzDateField({
    this.value,
    this.onTap,
    this.open = false,
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.placeholder,
    super.key,
  }) : range = false,
       rangeValue = null;

  const GzDateField.range({
    GzDateRange? value,
    this.onTap,
    this.open = false,
    this.label,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.placeholder,
    super.key,
  }) : range = true,
       rangeValue = value,
       value = null;

  final bool range;

  /// Single mode: the chosen date key (`2027-01-14`).
  final String? value;

  /// Range mode.
  final GzDateRange? rangeValue;

  /// Opens the sheet (Enter and Space work from a focused field).
  final VoidCallback? onTap;

  /// The sheet is open: the field keeps its focus look.
  final bool open;
  final String? label;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;
  final bool forceFocus;
  final String? placeholder;

  @override
  State<GzDateField> createState() => _GzDateFieldState();
}

class _GzDateFieldState extends State<GzDateField> {
  final FocusNode _focus = FocusNode(debugLabel: 'datefield');
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _text(BuildContext context) {
    final w = widget;
    final f = context.gzFormat;
    if (w.range) {
      final r = w.rangeValue;
      if (r?.start == null) return '';
      if (r!.end != null && r.end != r.start) {
        return context.gzL10n.uiInputsDateFieldRange(
          f.plain(f.date(r.start!, DateStyle.compact)),
          f.plain(f.date(r.end!, DateStyle.compact)),
        );
      }
      return f.date(r.start!, DateStyle.full);
    }
    return w.value == null ? '' : f.date(w.value!, DateStyle.full);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final text = _text(context);
    final has = text.isNotEmpty;
    final enabled = !w.disabled && w.onTap != null;
    final shown = has ? text : (w.placeholder ?? gzDateFieldSheetTitle(context, range: w.range));
    final msg = w.error ?? (w.disabled ? w.disabledReason : w.helper);
    return GzFieldShell(
      label: w.label,
      optional: w.optional,
      helper: w.helper,
      error: w.error,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus || w.open,
      focused: _focused,
      startAdornment: const GzIcon(GzIcons.calendar, size: GzIconSize.sm),
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: [?w.label, shown].join(', '),
        hint: msg,
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
                child: GzText(
                  shown,
                  role: GzTextRole.body,
                  color: w.disabled ? c.textDisabled : (has ? c.textStrong : c.textSecondary),
                  figures: has,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The body of the date sheet: the calendar working on a draft, then Confirm (commits, disabled with its reason until a date or a full
/// range is chosen) and Clear. Closing the sheet without Confirm discards the draft. The host places it inside its sheet; the
/// selection summary under the grid carries the full date and, in Arabic only, the Hijri line ([hijri]).
class GzDateFieldSheetContent extends StatefulWidget {
  const GzDateFieldSheetContent({
    required this.onConfirm,
    this.value,
    this.days = const {},
    this.minDate,
    this.maxDate,
    this.today,
    this.priceBasis,
    this.showViewToggle,
    this.defaultView = GzCalendarView.availability,
    this.isSelectable,
    this.hijri = true,
    this.label,
    super.key,
  }) : range = false,
       rangeValue = null,
       onConfirmRange = null;

  const GzDateFieldSheetContent.range({
    required ValueChanged<GzDateRange> onConfirm,
    GzDateRange? value,
    this.days = const {},
    this.minDate,
    this.maxDate,
    this.today,
    this.priceBasis,
    this.showViewToggle,
    this.defaultView = GzCalendarView.availability,
    this.isSelectable,
    this.hijri = true,
    this.label,
    super.key,
  }) : range = true,
       rangeValue = value,
       value = null,
       onConfirm = null,
       onConfirmRange = onConfirm;

  final bool range;
  final String? value;
  final GzDateRange? rangeValue;

  /// Single mode: receives the confirmed date key (null when cleared and confirmed).
  final ValueChanged<String?>? onConfirm;
  final ValueChanged<GzDateRange>? onConfirmRange;
  final Map<String, GzCalendarDayInfo> days;
  final String? minDate;
  final String? maxDate;
  final String? today;
  final String? priceBasis;
  final bool? showViewToggle;
  final GzCalendarView defaultView;
  final bool Function(String iso, GzDayStatus status)? isSelectable;
  final bool hijri;
  final String? label;

  @override
  State<GzDateFieldSheetContent> createState() => _GzDateFieldSheetContentState();
}

class _GzDateFieldSheetContentState extends State<GzDateFieldSheetContent> {
  late String? _single = widget.value;
  late GzDateRange _range = widget.rangeValue ?? GzDateRange.empty;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final l10n = context.gzL10n;
    final start = w.range ? _range.start : _single;
    final canConfirm = w.range ? (_range.start != null && _range.end != null) : _single != null;
    final reason = canConfirm ? null : gzDateFieldSheetTitle(context, range: w.range);
    final calendar = w.range
        ? GzCalendar.range(
            value: _range,
            onChanged: (r) => setState(() => _range = r),
            days: w.days,
            minDate: w.minDate,
            maxDate: w.maxDate,
            today: w.today,
            priceBasis: w.priceBasis,
            showViewToggle: w.showViewToggle,
            defaultView: w.defaultView,
            isSelectable: w.isSelectable,
            summary: w.hijri,
            label: w.label ?? gzDateFieldSheetTitle(context, range: true),
          )
        : GzCalendar(
            value: _single,
            onChanged: (v) => setState(() => _single = v),
            days: w.days,
            minDate: w.minDate,
            maxDate: w.maxDate,
            today: w.today,
            priceBasis: w.priceBasis,
            showViewToggle: w.showViewToggle,
            defaultView: w.defaultView,
            isSelectable: w.isSelectable,
            summary: w.hijri,
            label: w.label ?? gzDateFieldSheetTitle(context),
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        calendar,
        const SizedBox(height: GzSpace.s4),
        GzButton(
          label: l10n.commonActionConfirm,
          fullWidth: true,
          reason: reason,
          onPressed: canConfirm
              ? () {
                  if (w.range) {
                    w.onConfirmRange?.call(_range);
                  } else {
                    w.onConfirm?.call(_single);
                  }
                }
              : null,
        ),
        const SizedBox(height: GzSpace.s2),
        GzButton(
          label: l10n.commonActionClear,
          variant: GzButtonVariant.tertiary,
          fullWidth: true,
          onPressed: start == null
              ? null
              : () => setState(() {
                  _single = null;
                  _range = GzDateRange.empty;
                }),
        ),
      ],
    );
  }
}
