// The Ink band of the Today screen (web `TodayHeader.tsx`, direction 3 "Ink panels", rule 9), in two parts so it costs little of a small
// screen: [TodayBar] pinned under the status bar (the venue switcher in serif and the bell with its unread count, 56 high) and [TodayIntro], the
// first block of the scroll body, still on Ink: the day as a quiet caption and the status as a figure, closed by a 1 dp gold khayt.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class TodayBar extends StatelessWidget {
  const TodayBar({required this.name, required this.unread, this.stamp, this.multiVenue = true, this.onVenue, this.onBell, super.key});

  final String name;
  final int unread;

  /// Offline: the persistent stamp (a glyph and the time of the last update) under the venue row.
  final String? stamp;
  final bool multiVenue;
  final VoidCallback? onVenue;
  final VoidCallback? onBell;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final safeTop = MediaQuery.paddingOf(context).top;
    final chipBody = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: GzText(name, role: GzTextRole.d1, color: c.textOnDark, maxLines: 1),
        ),
        if (multiVenue) ...[const SizedBox(width: GzSpace.s2), GzIcon(GzIcons.chevronDown, size: GzIconSize.sm, color: c.iconOnDark)],
      ],
    );
    final chip = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: GzSize.controlLg),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        child: multiVenue
            ? GzPressable(
                onPressed: onVenue,
                semanticLabel: l.hotelTodaySwitchVenue(name),
                borderRadius: GzRadius.smAll,
                minHeight: GzSize.controlLg,
                onDark: true,
                child: chipBody,
              )
            : chipBody,
      ),
    );
    final bell = Stack(
      clipBehavior: Clip.none,
      children: [
        GzIconButton(
          icon: GzIcons.bell,
          variant: GzIconButtonVariant.onScrim,
          label: unread > 0 ? l.hotelTodayBellUnread(unread) : l.hotelTodayBell,
          onPressed: onBell,
        ),
        if (unread > 0)
          PositionedDirectional(
            top: GzSpace.s2 + GzStroke.hair,
            end: 0,
            child: IgnorePointer(
              child: ExcludeSemantics(child: GzCountBadge(count: unread, max: 9)),
            ),
          ),
      ],
    );
    return ColoredBox(
      color: c.surfaceDark,
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: safeTop),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: chip),
                  const SizedBox(width: GzSpace.s3),
                  bell,
                ],
              ),
            ),
            if (stamp != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, bottom: GzSpace.s2),
                child: Semantics(
                  liveRegion: true,
                  label: l.hotelTodayOfflineStamp(stamp!),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        GzIcon(GzIcons.offline, size: GzIconSize.xs, color: c.iconOnDark),
                        const SizedBox(width: GzSpace.s2),
                        GzText(stamp!, role: GzTextRole.caption, color: c.textOnDarkMuted, figures: true),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TodayIntro extends StatelessWidget {
  const TodayIntro({required this.dateLine, this.roleWord, this.status, super.key});

  final String dateLine;

  /// The role is named only where it is not the default Manager.
  final String? roleWord;
  final Widget? status;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceDark,
        border: Border(
          bottom: BorderSide(color: c.markKhayt, width: GzStroke.hair),
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s1, bottom: GzSpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Chrome rounds Almarai's ascent and descent to whole pixels: the Arabic caption line is 22, the English one 20.
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: context.gz.isAr ? 22 : 0),
              child: Row(
              children: [
                GzText(dateLine, role: GzTextRole.caption, color: c.textOnDarkMuted, figures: true),
                if (roleWord != null) ...[
                  const SizedBox(width: GzSpace.s2),
                  Container(
                    width: GzSpace.s1,
                    height: GzSpace.s1,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: c.markKhayt),
                  ),
                  const SizedBox(width: GzSpace.s2),
                  GzText(roleWord!, role: GzTextRole.caption, color: c.textOnDarkMuted),
                ],
              ],
            ),
            ),
            if (status != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
                child: status,
              ),
          ],
        ),
      ),
    );
  }
}

/// The status on the Ink band: a glyph in a gold-ringed disk, a figure, the time left at inline-end. The sentence is read, not shown.
class StatusBand extends StatelessWidget {
  const StatusBand({required this.icon, required this.say, this.figure, this.extra, super.key});

  final IconData icon;
  final String? figure;
  final Widget? extra;
  final String say;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Semantics(
      container: true,
      label: say,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: GzSize.controlMd, maxHeight: GzSize.controlMd),
          child: Row(
            children: [
              Container(
                width: GzSize.avatarSm,
                height: GzSize.avatarSm,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.markKhayt, width: GzStroke.hair),
                ),
                child: GzIcon(icon, size: GzIconSize.md, color: c.textOnDarkGold),
              ),
              if (figure != null) ...[const SizedBox(width: GzSpace.s3), gzFigText(context, figure!, role: GzTextRole.kpi, color: c.textOnDark)],
              const Spacer(),
              ?extra,
            ],
          ),
        ),
      ),
    );
  }
}
