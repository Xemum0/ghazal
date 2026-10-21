import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import 'gz_roving.dart';

/// `held` sessions stay selectable (requests allowed) and carry a gold bead and the word; `booked` ones are struck and say so.
enum GzSessionStatus { available, held, booked }

/// A wall time in the venue's zone.
class GzTimeOfDay {
  const GzTimeOfDay(this.h, this.m);

  final int h;
  final int m;
}

/// One session of the day. An [end] at or before the [start] means the session ends after midnight on the next day (ADR 0002 D2).
class GzTimeSession {
  const GzTimeSession({
    required this.id,
    required this.label,
    required this.start,
    required this.end,
    this.status = GzSessionStatus.available,
    this.price,
  });

  final String id;

  /// `Afternoon`, `Evening`, `Full day` (ADR 0002 D3 presets) or the hall's own session name.
  final String label;
  final GzTimeOfDay start;
  final GzTimeOfDay end;
  final GzSessionStatus status;

  /// Per-session price in integer fils (shown with [GzTimeSlotPicker.priceUnit]).
  final int? price;
}

/// Session picker (web `TimeSlotPicker`, ADR 0002 D3: Afternoon, Evening, Full day). A radio group of 12-radius rows: the name, the
/// time range in the figures voice, a price or the reason it cannot be chosen. Selected = ink border and ring with a gold bead, like a
/// chip. Booked sessions are struck and say so; held sessions stay selectable and carry a gold bead and the word. Render it only when
/// more than one session is free that day (ADR 0002 D5).
class GzTimeSlotPicker extends StatefulWidget {
  const GzTimeSlotPicker({
    required this.sessions,
    this.value,
    this.defaultValue,
    this.onChanged,
    this.date,
    this.label,
    this.priceUnit,
    this.disabled = false,
    super.key,
  });

  final List<GzTimeSession> sessions;
  final String? value;
  final String? defaultValue;
  final ValueChanged<String?>? onChanged;

  /// The business day the sessions belong to (`YYYY-MM-DD`). Default: today by the formatter's clock.
  final String? date;

  /// Accessible name of the group (`Session`).
  final String? label;

  /// The unit that follows a price (`per guest`): a price never appears without its unit (ADR 0010 D9).
  final String? priceUnit;
  final bool disabled;

  @override
  State<GzTimeSlotPicker> createState() => _GzTimeSlotPickerState();
}

class _GzTimeSlotPickerState extends State<GzTimeSlotPicker> {
  final GzFocusNodes _focus = GzFocusNodes();
  String? _inner;

  @override
  void initState() {
    super.initState();
    _inner = widget.defaultValue;
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String? get _value => widget.value ?? _inner;

  void _set(String id) {
    if (widget.value == null) setState(() => _inner = id);
    widget.onChanged?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final gz = context.gz;
    final c = gz.colors;
    final f = context.gzFormat;
    final l10n = context.gzL10n;
    final base = (w.date ?? f.isoDay(f.now())).split('-').map(int.parse).toList();
    final flags = [for (final s in w.sessions) w.disabled || s.status == GzSessionStatus.booked];

    String range(GzTimeSession s) {
      final from = f.kuwaitDate(base[0], base[1], base[2], hour: s.start.h, minute: s.start.m);
      final crosses = s.end.h * 60 + s.end.m <= s.start.h * 60 + s.start.m;
      final to = f.kuwaitDate(base[0], base[1], base[2] + (crosses ? 1 : 0), hour: s.end.h, minute: s.end.m);
      return f.timeRange(from, to);
    }

    return Semantics(
      container: true,
      label: w.label ?? l10n.uiInputsSlotSession,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < w.sessions.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s2),
            Builder(
              builder: (context) {
                final s = w.sessions[i];
                final off = flags[i];
                final selected = s.id == _value && !off;
                final booked = s.status == GzSessionStatus.booked;
                final statusWord = booked
                    ? l10n.commonAvailabilityBooked
                    : (s.status == GzSessionStatus.held ? l10n.commonAvailabilityHeld : null);
                final price = s.price != null && !booked ? f.moneyParts(s.price!) : null;
                final heavy = gz.text(selected ? GzTextRole.uiTitle : GzTextRole.title).fontWeight;
                final labelStyle = gz
                    .text(GzTextRole.body)
                    .copyWith(color: booked ? c.textDisabled : c.textStrong, fontWeight: heavy, decoration: TextDecoration.none);
                final border = off ? c.borderHairline : (selected ? c.controlChipBorderSelected : c.controlChipBorder);
                final timeText = range(s);
                return Focus(
                  canRequestFocus: false,
                  onKeyEvent: (_, e) {
                    final next = gzRovingIndex(e, i, flags, rtl: gz.isRtl);
                    if (next == null) return KeyEventResult.ignored;
                    _focus[next].requestFocus();
                    _set(w.sessions[next].id);
                    return KeyEventResult.handled;
                  },
                  child: MergeSemantics(
                    child: Semantics(
                      inMutuallyExclusiveGroup: true,
                      checked: selected,
                      child: GzPressable(
                        focusNode: _focus[i],
                        onPressed: off ? null : () => _set(s.id),
                        semanticLabel: [s.label, GzBidi.strip(timeText), ?statusWord].join(', '),
                        selected: selected,
                        borderRadius: GzRadius.mdAll,
                        scale: 1,
                        builder: (context, st) => AnimatedContainer(
                          duration: GzMotion.durationBase,
                          curve: GzMotion.easeStandard,
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                          padding: EdgeInsetsDirectional.only(
                            top: GzSpace.s3,
                            bottom: GzSpace.s3,
                            start: selected ? GzSpace.s3 : GzSpace.s4,
                            end: GzSpace.s4,
                          ),
                          decoration: BoxDecoration(
                            color: off ? c.surfaceQuiet : (st.pressed ? c.surfaceQuiet : c.controlBg),
                            borderRadius: GzRadius.mdAll,
                            border: Border.all(color: border, width: GzStroke.hair),
                            boxShadow: selected ? [BoxShadow(color: c.controlChipBorderSelected, spreadRadius: GzStroke.hair)] : const [],
                          ),
                          child: Row(
                            children: [
                              if (selected) ...[const GzBead(), const SizedBox(width: GzSpace.s3)],
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s.label, style: labelStyle),
                                    _TimeLine(text: timeText, booked: booked),
                                  ],
                                ),
                              ),
                              const SizedBox(width: GzSpace.s3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (s.status == GzSessionStatus.held) ...[
                                    Transform.rotate(
                                      angle: 0.7853981633974483,
                                      child: SizedBox.square(
                                        dimension: GzSize.knotBead,
                                        child: ColoredBox(color: c.iconAccent),
                                      ),
                                    ),
                                    const SizedBox(width: GzSpace.s2),
                                  ],
                                  if (statusWord != null)
                                    GzText(statusWord, role: GzTextRole.caption, color: booked ? c.textDisabled : c.textSecondary),
                                  if (statusWord != null && price != null) const SizedBox(width: GzSpace.s2),
                                  if (price != null)
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        gzFigText(
                                          context,
                                          price.fractionIsZero ? price.integer : price.amount,
                                          role: GzTextRole.priceStrong,
                                          color: c.textStrong,
                                        ),
                                        GzText(
                                          w.priceUnit == null ? price.currency : '${price.currency} · ${w.priceUnit}',
                                          role: GzTextRole.caption,
                                          color: c.textSecondary,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeLine extends StatelessWidget {
  const _TimeLine({required this.text, required this.booked});

  final String text;
  final bool booked;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final color = booked ? c.textDisabled : c.textSecondary;
    if (!booked) return GzText(text, role: GzTextRole.caption, color: color, figures: true);
    final style = gz
        .text(GzTextRole.caption)
        .copyWith(color: color, decoration: TextDecoration.lineThrough, decorationThickness: 1, decorationColor: color);
    return Text.rich(
      TextSpan(
        children: [
          for (final part in GzFigures.spans(context, text, role: GzTextRole.caption))
            TextSpan(
              text: (part as TextSpan).text,
              style: part.style?.copyWith(decoration: TextDecoration.lineThrough, decorationThickness: 1, decorationColor: color),
            ),
        ],
      ),
      style: style,
    );
  }
}
