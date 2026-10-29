/// SexChoice (CA-AUTH-14, ADR 0038): female or male as two large radio tiles. Port of
/// design/src/screens/client/auth/_components/SexChoice.tsx (CL-AUTH-03 About you) and the glyph switch of CL-PROF-03 (Personal info).
///
/// Each tile is the registry's abstract gender symbol (`section-women`, `section-men`: no faces, no figures) and one word; the chosen
/// tile shows an ink check on its own disk, never colour alone, and an ink border. A group label sits above, a "required" error with a
/// danger glyph below (the tiles then take the error border). Two equal tiles in one row, 12 dp apart: female at the inline-start (the
/// right in Arabic). Targets are far above 44 dp. Sex is stored on the account, not shown to venues and not used to filter (OQ-R2-02).
///
/// [GzSexChoice.switcher] is the same control as a two-option glyph switch (a [GzIconSegmented] with both words shown), the form used in
/// Personal info where the sex is editable but already answered; there [label] is the accessible name only (nothing is drawn above it).
/// The widget is controlled: [value] is the chosen sex (null or [Sex.unknown] = none), [onChanged] reports a tap. All words arrive as
/// parameters (the app owns them), like the web component.
library;

import 'dart:ui' show SemanticsValidationResult;

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Sex;

import '../foundation.dart';
import '../inputs/inputs.dart';

class GzSexChoice extends StatelessWidget {
  const GzSexChoice({
    required this.value,
    required this.label,
    required this.femaleLabel,
    required this.maleLabel,
    this.onChanged,
    this.error,
    this.disabled = false,
    super.key,
  }) : _switcher = false;

  /// The glyph switch of Personal info: one 44 dp track with the two options, both words shown.
  const GzSexChoice.switcher({
    required this.value,
    required this.label,
    required this.femaleLabel,
    required this.maleLabel,
    this.onChanged,
    this.disabled = false,
    super.key,
  }) : _switcher = true,
       error = null;

  /// The chosen sex; null (or [Sex.unknown]) = none chosen yet.
  final Sex? value;

  /// The visible group label (tiles) or the accessible name of the switch.
  final String label;
  final String femaleLabel;
  final String maleLabel;
  final ValueChanged<Sex>? onChanged;

  /// The required message under the tiles ("Required"); set when the person continued without choosing.
  final String? error;
  final bool disabled;
  final bool _switcher;

  @override
  Widget build(BuildContext context) {
    if (_switcher) {
      return GzIconSegmented<Sex>(
        label: label,
        value: value == Sex.unknown ? null : value,
        onChanged: onChanged,
        labels: GzIconSegmentedLabels.all,
        disabled: disabled,
        options: [
          GzIconSegmentedOption(value: Sex.female, icon: GzIcons.sectionWomen, label: femaleLabel),
          GzIconSegmentedOption(value: Sex.male, icon: GzIcons.sectionMen, label: maleLabel),
        ],
      );
    }
    final c = context.gz.colors;
    final chosen = value == Sex.unknown ? null : value;
    Widget tile(Sex v, IconData icon, String name) => Expanded(
      child: _SexTile(
        icon: icon,
        name: name,
        selected: chosen == v,
        error: error != null,
        disabled: disabled,
        onPressed: onChanged == null ? null : () => onChanged!(v),
      ),
    );
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      isRequired: true,
      validationResult: error == null ? SemanticsValidationResult.none : SemanticsValidationResult.invalid,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: GzText(label, role: GzTextRole.label, color: c.textPrimary)),
          const SizedBox(height: GzSpace.s2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              tile(Sex.female, GzIcons.sectionWomen, femaleLabel),
              const SizedBox(width: GzSpace.s3),
              tile(Sex.male, GzIcons.sectionMen, maleLabel),
            ],
          ),
          if (error != null) ...[
            const SizedBox(height: GzSpace.s2),
            Semantics(
              liveRegion: true,
              container: true,
              label: error,
              excludeSemantics: true,
              child: Row(
                children: [
                  GzIcon(GzIcons.warningCircle, size: GzIconSize.xs, color: c.iconDanger),
                  const SizedBox(width: GzSpace.s2),
                  Expanded(child: GzText(error!, role: GzTextRole.caption, color: c.textDanger)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One tile: the gender symbol and its check disk on top, the word under them. A radio of a mutually exclusive pair.
class _SexTile extends StatelessWidget {
  const _SexTile({required this.icon, required this.name, required this.selected, required this.error, required this.disabled, required this.onPressed});

  final IconData icon;
  final String name;
  final bool selected;
  final bool error;
  final bool disabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final enabled = !disabled && onPressed != null;
    final border = error ? c.borderError : (selected ? c.controlChipBorderSelected : c.borderStrong);
    return Semantics(
      container: true,
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: name,
      onTap: enabled ? onPressed : null,
      excludeSemantics: true,
      child: GzPressable(
        onPressed: enabled ? onPressed : null,
        expand: true,
        borderRadius: GzRadius.mdAll,
        builder: (context, st) => Container(
          padding: const EdgeInsetsDirectional.all(GzSpace.s4),
          decoration: BoxDecoration(
            color: c.controlBg,
            borderRadius: GzRadius.mdAll,
            border: Border.all(color: border, width: GzStroke.hair),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GzIcon(icon, size: GzIconSize.lg, color: selected ? c.iconPrimary : c.iconSecondary),
                  _CheckDisk(selected: selected),
                ],
              ),
              const SizedBox(height: GzSpace.s2),
              GzText(name, role: GzTextRole.uiTitle, color: disabled ? c.textDisabled : c.textStrong),
            ],
          ),
        ),
      ),
    );
  }
}

/// The selection mark: a 24 dp ring; chosen it is filled ink with the check in the on-dark colour.
class _CheckDisk extends StatelessWidget {
  const _CheckDisk({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      width: GzSize.iconMd,
      height: GzSize.iconMd,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? c.surfaceDark : null,
        border: Border.all(color: selected ? c.surfaceDark : c.borderStrong, width: GzStroke.hair),
      ),
      child: selected ? GzIcon(GzIcons.check, size: GzIconSize.xs, color: c.textOnDark) : null,
    );
  }
}
