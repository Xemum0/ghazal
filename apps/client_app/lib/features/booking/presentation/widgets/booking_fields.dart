import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/booking_flow_model.dart';
import '../booking_glyphs.dart';
import 'booking_layout.dart';

const int _stepFallback = 5;

/// The guests as a 64 dp stepper row (steps of the package guest step; the glyph is the label), preset chips and the live check against
/// the hall and package limits. Below the minimum the price is for the minimum (a quiet fact with its figure, not an error); above the
/// hall's capacity it is an error with its glyph and a figure, and the step cannot continue.
class BookingGuestsField extends ConsumerWidget {
  const BookingGuestsField({required this.section, required this.onChanged, super.key});

  final SectionModel section;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final step = section.options.isEmpty
        ? _stepFallback
        : (section.options.first.pkg.guestStep > 0 ? section.options.first.pkg.guestStep : _stepFallback);
    final guests = section.guests;
    final below = guests < section.minGuests;
    final over = guests > section.maxGuests;
    final presets = <int>[
      for (final d in [0, step * 10, step * 20, step * 40])
        if (section.minGuests + d <= section.maxGuests) section.minGuests + d,
    ];
    return BookingGap(
      gap: GzSpace.s3,
      children: [
        GzStepper(
          labelWidget: GzIcon(GzIcons.usersThree, size: GzIconSize.md, color: c.iconSecondary),
          semanticLabel: l10n.clientBookingGuestsLabel,
          value: guests,
          onChanged: onChanged,
          min: 1,
          max: section.maxGuests + step * 10,
          step: step,
          valueText: f.guests,
        ),
        GzChipGroup<int>(
          label: l10n.clientBookingGuestsPresets,
          options: [for (final n in presets) GzChipOption<int>(value: n, label: f.integer(n))],
          value: presets.contains(guests) ? guests : null,
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
        if (below)
          _Hint(icon: GzIcons.info, text: f.minGuests(section.minGuests), role: 'status', color: c.textSecondary, iconColor: c.iconSecondary),
        if (over)
          _Hint(
            icon: GzIcons.warningCircle,
            text: f.digits(l10n.commonUnitUpToGuests(section.maxGuests)),
            role: 'alert',
            color: c.textDanger,
            iconColor: c.iconDanger,
          ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({required this.icon, required this.text, required this.role, required this.color, required this.iconColor});

  final IconData icon;
  final String text;
  final String role;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      child: Row(
        children: [
          GzIcon(icon, size: GzIconSize.xs, color: iconColor),
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: GzText(text, role: GzTextRole.caption, color: color, figures: true),
          ),
        ],
      ),
    );
  }
}

/// Which hall, shown only when more than one fits (ADR 0002): a single-choice list rather than a segmented control, because a hall name is
/// a serif name and must never be cut. Each row carries the name and what the hall holds; the choice is an ink border and a check.
class BookingHallChoice extends ConsumerWidget {
  const BookingHallChoice({required this.label, required this.halls, required this.value, required this.onChanged, super.key});

  final String label;
  final List<({Hall hall, int max})> halls;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    return Semantics(
      container: true,
      label: label,
      child: BookingGap(
        gap: GzSpace.s3,
        children: [
          for (final h in halls)
            GzPressable(
              onPressed: () => onChanged(h.hall.id),
              semanticLabel: context.bi(h.hall.name),
              selected: h.hall.id == value,
              minWidth: 0,
              scale: 1,
              borderRadius: GzRadius.mdAll,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surfaceRaised,
                  borderRadius: GzRadius.mdAll,
                  border: Border.all(color: h.hall.id == value ? c.controlChipBorderSelected : c.borderStrong, width: GzStroke.hair),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4, vertical: GzSpace.s3),
                    child: Row(
                      children: [
                        BookingMark(on: h.hall.id == value),
                        const SizedBox(width: GzSpace.s3),
                        Expanded(
                          child: GzText(context.bi(h.hall.name), role: GzTextRole.d1, color: c.textStrong),
                        ),
                        const SizedBox(width: GzSpace.s3),
                        GzFactChip(icon: GzIcons.usersThree, label: f.digits(l10n.commonUnitUpToGuests(h.max)), value: f.integer(h.max)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The choice mark of a card or row: an empty ring, or an ink disc with a check (choice is ink, never gold alone).
class BookingMark extends StatelessWidget {
  const BookingMark({required this.on, super.key});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ExcludeSemantics(
      child: Container(
        width: GzSize.iconMd,
        height: GzSize.iconMd,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? c.controlToggleOn : null,
          border: Border.all(color: on ? c.controlToggleOn : c.borderControl, width: GzStroke.icon),
        ),
        child: on
            ? Center(
                child: GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.controlToggleKnob),
              )
            : null,
      ),
    );
  }
}
