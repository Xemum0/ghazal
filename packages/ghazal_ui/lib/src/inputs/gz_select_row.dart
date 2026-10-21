import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_field_input.dart' show gzFirstStrong;
import 'gz_field_shell.dart';
import 'gz_search_field.dart';
import 'gz_search_normalize.dart';

/// One option of a picker: a value, its label, an optional second line (the area's governorate, a rule), extra search-only words
/// (aliases, ADR 0012 D8) and a disabled flag.
class GzSelectOption<V> {
  const GzSelectOption({required this.value, required this.label, this.description, this.aliases, this.disabled = false});

  final V value;
  final String label;
  final String? description;
  final String? aliases;
  final bool disabled;
}

/// `field`: label above a 56 high input-like box with a chevron-down (forms). `row`: a 64 high list row, label above value, a mirrored
/// chevron at the end (Home brief card, settings).
enum GzSelectVariant { field, row }

/// Picker trigger (web `SelectRow`). There is no native select (ADR 0024): the trigger is a button that asks its host to open a bottom
/// sheet with a [GzPickerList]. This widget draws the closed state only (the sheet host belongs to the navigation group): it shows the
/// chosen label(s) from [values] (one or many), the placeholder when none, and calls [onTap] to open. [open] draws the field in its
/// focus look while the sheet is up.
class GzSelectRow<V> extends StatefulWidget {
  const GzSelectRow({
    required this.options,
    required this.label,
    this.values = const [],
    this.onTap,
    this.open = false,
    this.placeholder,
    this.variant = GzSelectVariant.field,
    this.divider = false,
    this.optional = false,
    this.helper,
    this.error,
    this.disabled = false,
    this.disabledReason,
    this.forceFocus = false,
    this.startAdornment,
    super.key,
  });

  final List<GzSelectOption<V>> options;
  final String label;

  /// The chosen values (single selection passes zero or one).
  final List<V> values;

  /// Opens the picker sheet (Enter, Space and ArrowDown work from a focused trigger).
  final VoidCallback? onTap;
  final bool open;

  /// Shown when nothing is chosen.
  final String? placeholder;
  final GzSelectVariant variant;

  /// `row` only: 1 dp hairline under the row.
  final bool divider;
  final bool optional;
  final String? helper;
  final String? error;
  final bool disabled;
  final String? disabledReason;
  final bool forceFocus;
  final Widget? startAdornment;

  @override
  State<GzSelectRow<V>> createState() => _GzSelectRowState<V>();
}

class _GzSelectRowState<V> extends State<GzSelectRow<V>> {
  final FocusNode _focus = FocusNode(debugLabel: 'select-trigger');
  bool _focused = false;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _valueText(BuildContext context) {
    final w = widget;
    if (w.values.isEmpty) return '';
    final f = context.gzFormat;
    String labelOf(V v) => w.options.where((o) => o.value == v).map((o) => o.label).firstOrNull ?? '';
    return w.values.length <= 2
        ? f.list([for (final v in w.values) labelOf(v)])
        : context.gzL10n.uiInputsSelectCount(f.integer(w.values.length));
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final text = _valueText(context);
    final chosen = text.isNotEmpty;
    final shown = chosen ? text : (w.placeholder ?? context.gzL10n.uiInputsSelectChoose);
    final invalid = w.error != null && w.error!.isNotEmpty;
    final msg = invalid ? w.error : (w.disabled && w.disabledReason != null ? w.disabledReason : w.helper);
    final enabled = !w.disabled && w.onTap != null;

    if (w.variant == GzSelectVariant.row) {
      final base = gz.text(GzTextRole.body);
      final valueStyle = base.copyWith(
        color: w.disabled ? c.textDisabled : (chosen ? c.textStrong : c.textSecondary),
        fontWeight: chosen ? gz.text(GzTextRole.title).fontWeight : base.fontWeight,
        decoration: TextDecoration.none,
      );
      final column = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzPressable(
            onPressed: enabled ? w.onTap : null,
            semanticLabel: '${w.label}, $shown',
            borderRadius: GzRadius.smAll,
            builder: (context, st) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: GzSize.briefRow),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
                child: Row(
                  children: [
                    if (w.startAdornment != null) ...[
                      IconTheme(
                        data: IconThemeData(color: c.iconSecondary),
                        child: w.startAdornment!,
                      ),
                      const SizedBox(width: GzSpace.s3),
                    ],
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzText(w.label, role: GzTextRole.caption, color: w.disabled ? c.textDisabled : c.textSecondary),
                          Text(shown, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis, textDirection: gzFirstStrong(shown)),
                        ],
                      ),
                    ),
                    const SizedBox(width: GzSpace.s3),
                    GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: w.disabled ? c.iconDisabled : c.iconSecondary),
                  ],
                ),
              ),
            ),
          ),
          if (msg != null && msg.isNotEmpty)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s2),
              child: GzText(msg, role: GzTextRole.caption, color: invalid ? c.textDanger : c.textSecondary),
            ),
        ],
      );
      return w.divider
          ? DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                ),
              ),
              child: column,
            )
          : column;
    }

    final valueStyle = gz
        .text(GzTextRole.body)
        .copyWith(color: w.disabled ? c.textDisabled : (chosen ? c.textStrong : c.textSecondary), decoration: TextDecoration.none);
    return GzFieldShell(
      label: w.label,
      optional: w.optional,
      helper: w.helper,
      error: w.error,
      disabled: w.disabled,
      disabledReason: w.disabledReason,
      forceFocus: w.forceFocus || w.open,
      focused: _focused,
      startAdornment: w.startAdornment,
      child: Semantics(
        container: true,
        button: true,
        enabled: enabled,
        label: '${w.label}, $shown',
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
            const SingleActivator(LogicalKeyboardKey.arrowDown): const ActivateIntent(),
          },
          actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => w.onTap?.call())},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? w.onTap : null,
            child: SizedBox(
              height: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        shown,
                        style: valueStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textDirection: gzFirstStrong(shown),
                      ),
                    ),
                  ),
                  const SizedBox(width: GzSpace.s3),
                  GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, color: w.disabled ? c.iconDisabled : c.iconSecondary),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The listbox the picker sheet shows (web `SelectRow` sheet body): an optional search field (Arabic-aware matching, aliases) and one
/// 64 high row per option with the label, a second line, and a mark at the end (a check for a single choice; an empty box that fills
/// for multiple selection, so the choice is a shape). The host puts it in the sheet body and applies the choice. [selected] is the
/// current (draft) selection; [onPick] reports a tapped value.
class GzPickerList<V> extends StatefulWidget {
  const GzPickerList({
    required this.options,
    required this.selected,
    required this.onPick,
    this.multiple = false,
    this.searchable = false,
    this.semanticLabel,
    super.key,
  });

  final List<GzSelectOption<V>> options;
  final List<V> selected;
  final ValueChanged<V> onPick;
  final bool multiple;
  final bool searchable;
  final String? semanticLabel;

  @override
  State<GzPickerList<V>> createState() => _GzPickerListState<V>();
}

class _GzPickerListState<V> extends State<GzPickerList<V>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final visible = [
      for (final o in w.options)
        if (gzMatchesSearch(_query, o.label, o.description, o.aliases)) o,
    ];
    final heavy = gz.text(GzTextRole.title).fontWeight;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (w.searchable)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
            child: GzSearchField(size: GzSearchSize.sm, onValueChange: (q) => setState(() => _query = q)),
          ),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: GzSpace.s6),
            child: Center(
              child: GzText(context.gzL10n.uiInputsSelectNoResults, role: GzTextRole.bodyS, color: c.textSecondary),
            ),
          )
        else
          Semantics(
            container: true,
            label: w.semanticLabel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final o in visible)
                  Builder(
                    builder: (context) {
                      final isSel = w.selected.contains(o.value);
                      final label = gz
                          .text(GzTextRole.body)
                          .copyWith(
                            color: o.disabled ? c.textDisabled : c.textStrong,
                            fontWeight: isSel ? heavy : null,
                            decoration: TextDecoration.none,
                          );
                      return GzPressable(
                        onPressed: o.disabled ? null : () => w.onPick(o.value),
                        semanticLabel: o.description == null ? o.label : '${o.label}, ${o.description}',
                        selected: isSel,
                        scale: 1,
                        pressedColor: c.surfaceQuiet,
                        builder: (context, st) => Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                          padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
                          decoration: BoxDecoration(
                            color: st.pressed && !o.disabled ? c.surfaceQuiet : null,
                            border: Border(
                              bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(o.label, style: label, textDirection: gzFirstStrong(o.label)),
                                    if (o.description != null)
                                      GzText(
                                        o.description!,
                                        role: GzTextRole.caption,
                                        color: o.disabled ? c.textDisabled : c.textSecondary,
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: GzSpace.s4),
                              _Mark(selected: isSel, multiple: w.multiple),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.multiple});

  final bool selected;
  final bool multiple;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      width: GzSize.iconMd,
      height: GzSize.iconMd,
      alignment: Alignment.center,
      decoration: multiple
          ? BoxDecoration(
              color: selected ? c.controlToggleOn : null,
              borderRadius: GzRadius.xsAll,
              border: Border.all(color: selected ? c.controlToggleOn : c.borderControl, width: GzStroke.hair),
            )
          : null,
      child: selected ? GzIcon(GzIcons.check, size: GzIconSize.sm, color: multiple ? c.controlToggleKnob : c.textStrong) : null,
    );
  }
}
