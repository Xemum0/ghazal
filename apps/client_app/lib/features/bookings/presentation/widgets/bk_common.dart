import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, GzFormat, ScreenState;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/bookings_data.dart';

const String _nbsp = ' ';

/// `13 Nov 12:40 PM`: an instant as a figure (no weekday, no comma), the way the Booking Thread writes it.
String bkStamp(GzFormat f, DateTime at) {
  final c = f.civil(at);
  return '${f.integer(c.day)}$_nbsp${f.monthName(c.month, short: true)}$_nbsp${f.time(at).replaceAll(RegExp(r'\s'), _nbsp)}';
}

/// `14 Jan`: a day and a short month. [d] is a [LocalDate] or a [DateTime].
String bkDayMon(GzFormat f, Object d) {
  final c = f.civil(d is LocalDate ? d.toString() : d);
  return '${f.integer(c.day)}$_nbsp${f.monthName(c.month, short: true)}';
}

/// `14 Jan 2027`.
String bkDayYear(GzFormat f, Object d) => f.date(d is LocalDate ? d.toString() : d, DateStyle.compact);

/// `Thursday 14 January 2027`.
String bkDayFull(GzFormat f, Object d) => f.date(d is LocalDate ? d.toString() : d, DateStyle.full);

/// The glyph of the reception (women, men, mixed).
IconData bkAudienceGlyph(Audience a) => switch (a) {
  Audience.men => GzIcons.sectionMen,
  Audience.mixed => GzIcons.sectionMixed,
  _ => GzIcons.sectionWomen,
};

String bkAudienceLabel(AppL10n l, Audience a) => switch (a) {
  Audience.men => l.clientBookingsAudienceMen,
  Audience.mixed => l.clientBookingsAudienceMixed,
  _ => l.clientBookingsAudienceWomen,
};

/// The session glyph and word by the start hour: the sun of a day reception, the sunset of an afternoon one, the moon of an evening one.
({IconData icon, String label}) bkSession(AppL10n l, LocalTime start) => start.hour < 12
    ? (icon: GzIcons.sun, label: l.clientBookingsSessionDay)
    : (start.hour < 17
          ? (icon: GzIcons.sunset, label: l.clientBookingsSessionAfternoon)
          : (icon: GzIcons.moon, label: l.clientBookingsSessionEvening));

/// The text of a bilingual value in the language of the screen.
extension BkBi on BuildContext {
  String bi(LocalizedText t) => t.of(gz.locale.languageCode);
}

/// A column with a fixed gap (the web `display: flex; flex-direction: column; gap`).
class BkGap extends StatelessWidget {
  const BkGap({required this.children, this.gap = GzSpace.s4, this.cross = CrossAxisAlignment.stretch, super.key});

  final List<Widget> children;
  final double gap;
  final CrossAxisAlignment cross;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(SizedBox(height: gap));
      items.add(children[i]);
    }
    return Column(crossAxisAlignment: cross, mainAxisSize: MainAxisSize.min, children: items);
  }
}

/// The screen gutter around [child].
class BkPad extends StatelessWidget {
  const BkPad({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
    child: child,
  );
}

/// The five states of a screen body: a skeleton while it loads (a stale value stays while it reloads), the problem with retry, the offline
/// banner over the stale content, never a spinner and never blank.
class BkAsync<T> extends StatelessWidget {
  const BkAsync({required this.value, required this.data, required this.loading, this.onRetry, super.key});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final state = ScreenState.from<T>(keepStale(value));
    return state.when(
      loading: () => Semantics(
        container: true,
        label: context.gzL10n.commonStateLoading,
        child: ExcludeSemantics(child: loading),
      ),
      data: data,
      empty: () => const SizedBox.shrink(),
      error: (p) => GzErrorState(kind: gzProblemKind(p), body: gzProblemMessage(context.gzL10n, p), onRetry: onRetry, fill: false),
      offline: (stale) => stale == null
          ? GzOfflineState(onRetry: onRetry, fill: false)
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzBanner(message: context.gzL10n.commonStateOffline, tone: GzBannerTone.offline, shape: GzBannerShape.flush),
                data(stale),
              ],
            ),
    );
  }
}

/// The title row of a sheet screen: title at inline-start, the info glyph and the close at inline-end (the sheet body carries the gutter).
class BkSheetTop extends StatelessWidget {
  const BkSheetTop({this.title, this.info, this.onClose, super.key});

  final String? title;
  final Widget? info;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: Row(
          children: [
            Expanded(
              child: title == null ? const SizedBox.shrink() : GzText(title!, role: GzTextRole.d1, color: c.textStrong, header: true),
            ),
            if (info != null) ...[const SizedBox(width: GzSpace.s3), info!],
            const SizedBox(width: GzSpace.s3),
            GzBarButton(
              key: const ValueKey<String>('gz:sheet.close'),
              icon: GzIcons.close,
              label: context.gzL10n.commonActionClose,
              onPressed: onClose ?? () => context.gzNav.closeSheet(),
            ),
          ],
        ),
      ),
    );
  }
}

/// One ruled line of [BkFactLines]: a glyph and a value, no label on screen (the label is the accessible name).
class BkFactLine {
  const BkFactLine({required this.icon, required this.label, required this.value, this.trailing, this.onPressed, this.autoDir = false});

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final bool autoDir;
}

/// Ruled rows of glyph and value (web `FactLines`): hairline between rows; an [BkFactLine.onPressed] makes the row a button with the chevron.
class BkFactLines extends StatelessWidget {
  const BkFactLines({required this.lines, super.key});

  final List<BkFactLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final hair = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < lines.length; i++)
          Container(
            decoration: BoxDecoration(
              border: Border(top: i == 0 ? hair : BorderSide.none, bottom: hair),
            ),
            child: _line(context, lines[i]),
          ),
      ],
    );
  }

  Widget _line(BuildContext context, BkFactLine line) {
    final c = context.gz.colors;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlLg),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: GzSpace.s2),
        child: Row(
          children: [
            GzIcon(line.icon, size: GzIconSize.sm, color: c.iconSecondary),
            const SizedBox(width: GzSpace.s3),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: line.autoDir
                    ? GzUserText(line.value, role: GzTextRole.bodyS, color: c.textStrong)
                    : GzText(line.value, role: GzTextRole.bodyS, color: c.textStrong, figures: true),
              ),
            ),
            if (line.trailing != null) ...[const SizedBox(width: GzSpace.s3), line.trailing!],
            if (line.onPressed != null) ...[
              const SizedBox(width: GzSpace.s3),
              GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
            ],
          ],
        ),
      ),
    );
    if (line.onPressed == null) return Semantics(label: '${line.label} ${line.value}', excludeSemantics: true, child: body);
    return GzPressable(onPressed: line.onPressed, semanticLabel: line.label, builder: (context, st) => body);
  }
}

/// The composition of a state inside a sheet: a drawing, a title of at most four words, what the state carries (a fact row, the voucher
/// outcome), then the actions (one primary, a quieter second).
class BkStateStack extends StatelessWidget {
  const BkStateStack({required this.illustration, required this.title, this.children = const <Widget>[], this.actions = const <Widget>[], super.key});

  final GzIllustrationName illustration;
  final String title;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GzIllustration(illustration, size: GzIllustrationSize.lg),
        const SizedBox(height: GzSpace.s4),
        GzText(title, role: GzTextRole.d2, color: c.textStrong, textAlign: TextAlign.center, header: true),
        if (children.isNotEmpty) ...[const SizedBox(height: GzSpace.s4), BkGap(gap: GzSpace.s3, children: children)],
        if (actions.isNotEmpty) ...[const SizedBox(height: GzSpace.s4 + GzSpace.s2), BkGap(gap: GzSpace.s3, children: actions)],
      ],
    );
  }
}
