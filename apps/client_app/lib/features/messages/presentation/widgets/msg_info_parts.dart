import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart' show Audience, Booking;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import 'inbox_row.dart' show statusOfBooking;

/// A ruled section of the details sheet (web `gzm-info__section`): a hairline above, 12 of air, the rows 8 apart. Sections are ruled,
/// not carded.
class MsgInfoSection extends StatelessWidget {
  const MsgInfoSection({required this.children, this.gap = GzSpace.s2, super.key});

  final List<Widget> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[if (i > 0) SizedBox(height: gap), children[i]],
        ],
      ),
    );
  }
}

/// The linked request in the details sheet (web `gzm-info__request`): its three facts at the start, the status glyph and a chevron at
/// the end, always one line, one press target to the booking.
class MsgInfoRequestRow extends StatelessWidget {
  const MsgInfoRequestRow({required this.booking, required this.onOpen, super.key});

  final Booking booking;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final audience = booking.sections.isEmpty ? Audience.women : booking.sections.first.audience;
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    final status = statusOfBooking(booking.status);
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: l.clientMessagesContextView,
      scale: 1,
      minHeight: GzSize.touchMin,
      minWidth: 0,
      borderRadius: GzRadius.smAll,
      child: Row(
        children: [
          Expanded(
            child: GzFactRow(
              label: l.clientMessagesInfoBooking,
              children: [
                GzFactChip(icon: GzIcons.calendar, label: l.clientMessagesFactDate, value: f.date(booking.eventDate.toString(), DateStyle.dayMonth)),
                GzFactChip(
                  icon: switch (audience) {
                    Audience.men => GzIcons.sectionMen,
                    Audience.mixed => GzIcons.sectionMixed,
                    _ => GzIcons.sectionWomen,
                  },
                  label: switch (audience) {
                    Audience.men => l.clientMessagesAudienceMen,
                    Audience.mixed => l.clientMessagesAudienceMixed,
                    _ => l.clientMessagesAudienceWomen,
                  },
                ),
                GzFactChip(icon: GzIcons.usersThree, label: l.clientMessagesFactGuests, value: f.integer(guests)),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s4),
          if (status != null) ...[GzStatusIcon(status: status, large: true), const SizedBox(width: GzSpace.s2)],
          GzIcon(GzIcons.chevronRight, size: GzIconSize.sm, color: c.iconSecondary),
        ],
      ),
    );
  }
}
