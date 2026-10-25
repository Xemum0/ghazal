// Small pieces every venue screen shares (web `venue/_components/bits.tsx`, `editor.tsx`): the page and section rhythm, a fact line, a read-only
// row, the pinned Save bar with its stated reason, the offline strip, the form skeleton and the discard guard. Numbers come from the formatter.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemMessage;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../app/state/state.dart' show ActionResult;
import '../../../../l10n/l10n.dart';

/// The page column of a screen body: gutter 20, sections 32 apart.
class VenuePage extends StatelessWidget {
  const VenuePage({required this.children, this.gap = GzSpace.section, super.key});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s5, bottom: GzSpace.s8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
      ],
    ),
  );
}

/// A section of a form or a list: the khayt and a title, then its body 16 below.
class VenueSection extends StatelessWidget {
  const VenueSection({required this.title, required this.children, this.action, super.key});

  final String title;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzSectionHeader(title: title, voice: GzHeaderVoice.partner, action: action),
      for (final w in children) ...[const SizedBox(height: GzSpace.s4), w],
    ],
  );
}

/// A quiet caption line with a leading glyph (a fact, a rule the app states instead of enforcing silently).
class FactLine extends StatelessWidget {
  const FactLine(this.text, {this.icon = GzIcons.info, this.danger = false, super.key});

  final String text;
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final color = danger ? c.textDanger : c.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s1),
          child: GzIcon(icon, size: GzIconSize.xs, color: danger ? c.iconDanger : c.iconSecondary),
        ),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: GzText(text, role: GzTextRole.caption, color: color, figures: true),
        ),
      ],
    );
  }
}

/// One line of read-only fact: the label at inline-start, the value at inline-end.
class ReadOnlyRow extends StatelessWidget {
  const ReadOnlyRow({required this.label, required this.value, this.last = false, super.key});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.touchMin),
      padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s2),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: GzText(label, role: GzTextRole.bodyS, color: c.textPrimary),
          ),
          const SizedBox(width: GzSpace.s4),
          GzText(value, role: GzTextRole.bodyS, color: c.textStrong, figures: true, textAlign: TextAlign.end),
        ],
      ),
    );
  }
}

/// The pinned Save: disabled states always carry their reason.
GzActionBar venueSaveBar(
  BuildContext context, {
  required bool dirty,
  String? problem,
  bool saving = false,
  bool saved = false,
  required VoidCallback onSave,
  String? label,
}) {
  final l = context.l10n;
  return GzActionBar(
    action: GzActionBarAction(
      label: saved ? l.hotelVenueSavedState : (label ?? l.hotelVenueSave),
      iconEnd: saved ? GzIcons.check : null,
      loading: saving,
      disabled: saved || problem != null || !dirty,
      reason: saved ? null : problem,
      onPressed: onSave,
    ),
  );
}

/// The loading frame of a form: a title line, then fields as 56 blocks (the shape of what is coming).
class FormSkeleton extends StatelessWidget {
  const FormSkeleton({this.rows = 5, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s5),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: AlignmentDirectional.centerStart, child: GzSkeleton(blockSize: 28, inlineSize: 160)),
        for (var i = 0; i < rows; i++) ...[
          const SizedBox(height: GzSpace.s4),
          GzSkeleton(variant: GzSkeletonVariant.block, blockSize: i % 3 == 2 ? 96 : 56),
        ],
      ],
    ),
  );
}

/// "Discard changes?": true when the person confirms leaving. Without edits it answers true at once.
Future<bool> confirmDiscard(BuildContext context, {required bool dirty}) async {
  if (!dirty) return true;
  final l = context.l10n;
  final answer = await GzNavigatorScope.of(context).openDialog(
    GzDialogSpec(
      title: l.hotelVenueGuardTitle,
      body: l.hotelVenueGuardBody,
      icon: GzIcons.warningCircle,
      confirmLabel: l.hotelVenueGuardDiscard,
      cancelLabel: l.hotelVenueGuardKeep,
      tone: GzDialogTone.destructive,
    ),
  );
  return answer == GzDialogResult.confirm;
}

/// Parses a typed KD amount (up to three decimals, Eastern digits accepted) into integer fils; null when it is not an amount.
int? parseFils(String raw) {
  final s = raw.trim().replaceAll(RegExp('[٫,]'), '.');
  final western = s.split('').map((ch) {
    final u = ch.codeUnitAt(0);
    return (u >= 0x0660 && u <= 0x0669)
        ? String.fromCharCode(u - 0x0660 + 48)
        : ((u >= 0x06f0 && u <= 0x06f9) ? String.fromCharCode(u - 0x06f0 + 48) : ch);
  }).join();
  final m = RegExp(r'^(\d+)(?:\.(\d{1,3}))?$').firstMatch(western);
  if (m == null) return null;
  final whole = int.parse(m.group(1)!);
  final frac = (m.group(2) ?? '').padRight(3, '0');
  return whole * 1000 + int.parse(frac);
}

/// Shows the outcome of a write: [success] as a toast (null for none) and [then] on success, the problem message as a danger toast on failure.
void toastResult<T>(BuildContext context, ActionResult<T> result, {String? success, void Function(T value)? then}) {
  final nav = GzNavigatorScope.of(context);
  result.when(
    success: (v) {
      if (success != null) nav.toast(GzToastSpec(message: success, icon: GzIcons.checkCircle));
      then?.call(v);
    },
    failure: (p) => nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, p), tone: GzToastTone.danger)),
    gated: () {},
  );
}

/// Several reads as one: loading until every one has data, the first error otherwise (the screen shows one state, not three).
AsyncValue<bool> combineAsync(List<AsyncValue<Object?>> values) {
  for (final v in values) {
    if (v.hasError && !v.hasValue) return AsyncValue<bool>.error(v.error!, v.stackTrace ?? StackTrace.empty);
  }
  if (values.any((v) => v.value == null)) return const AsyncValue<bool>.loading();
  return const AsyncValue<bool>.data(true);
}

/// A read-only block: the app states what it does not edit and where that lives. A quiet tone panel, never a card.
class DashboardNote extends StatelessWidget {
  const DashboardNote({this.menus = false, super.key});

  /// Only the menus and the service charge (the other kind lists the price grids too).
  final bool menus;

  void _open(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    nav.openSheetBuilder(
      (sheet) {
        final l = sheet.l10n;
        final c = sheet.gz.colors;
        final items = [if (!menus) ...[l.hotelVenueDashboardItemSeason, l.hotelVenueDashboardItemHoliday, l.hotelVenueDashboardItemSpecial], l.hotelVenueDashboardItemMenus, l.hotelVenueDashboardItemService];
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: GzSpace.s2),
            GzText(l.hotelVenueDashboardLead, role: GzTextRole.body, color: c.textStrong),
            const SizedBox(height: GzSpace.s4),
            for (final t in items)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(GzIcons.check, size: GzIconSize.sm, color: c.iconSecondary)),
                    const SizedBox(width: GzSpace.s3),
                    Expanded(child: GzText(t, role: GzTextRole.bodyS, color: c.textPrimary)),
                  ],
                ),
              ),
            const SizedBox(height: GzSpace.s1),
            GzButton(label: l.commonActionDone, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: nav.closeSheet),
          ],
        );
      },
      options: GzSheetOptions(title: context.l10n.hotelVenueDashboardTitle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.all(GzSpace.panelPad),
      decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s1), child: GzIcon(GzIcons.settings, size: GzIconSize.sm, color: c.iconSecondary)),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: GzButton(label: context.l10n.hotelVenueDashboardCta, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.externalLink, flushInline: true, onPressed: () => _open(context)),
            ),
          ),
        ],
      ),
    );
  }
}
