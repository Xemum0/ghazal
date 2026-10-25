// RequestContext (web `RequestContext.tsx`): who and what a decision is about, as a ruled strip (hairline above and below, not a panel). A
// monogram, the name as typed, the hall as a quiet line, then the facts as glyphs and figures with no label: calendar and short date, users
// and guests, the session glyph and the section symbol. The words of each fact are its accessible name. A provider request has no hall,
// session or section, so it shows the date and the quantity only. Used by all four sheets so the frame of every decision reads the same.
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

IconData sessionGlyph(LocalTime start) => start.hour < 12 ? GzIcons.sun : (start.hour < 17 ? GzIcons.sunset : GzIcons.moon);

class RequestContext extends StatelessWidget {
  const RequestContext({required this.detail, this.end, super.key});

  final PartnerRequestDetail detail;
  final Widget? end;

  @override
  Widget build(BuildContext context) {
    final b = detail.booking;
    final l = context.l10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final section = b.sections.isEmpty ? null : b.sections.first;
    final hall = section == null ? null : detail.halls.where((h) => h.id == section.hallId).map((h) => h.name.of(lang)).firstOrNull;
    final subject = hall ?? detail.target.name.of(lang);
    final guests = section?.guests ?? b.service?.quantity ?? 0;
    final audience = section?.audience;
    final audienceWord = switch (audience) {
      Audience.men => l.hotelDecisionsFactMen,
      Audience.mixed => l.hotelDecisionsFactMixed,
      _ => l.hotelDecisionsFactLadies,
    };
    final audienceIcon = switch (audience) {
      Audience.men => GzIcons.sectionMen,
      Audience.mixed => GzIcons.sectionMixed,
      _ => GzIcons.sectionWomen,
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
      decoration: BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: GzAvatar(name: b.clientName, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
              ),
              const SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzUserText(b.clientName, role: GzTextRole.title, color: c.textStrong, maxLines: 2),
                    if (subject.isNotEmpty) GzText(subject, role: GzTextRole.caption, color: c.textSecondary),
                  ],
                ),
              ),
              if (end != null) ...[const SizedBox(width: GzSpace.s3), end!],
            ],
          ),
          const SizedBox(height: GzSpace.s2),
          GzFactRow(
            label: l.hotelDecisionsFactsLabel,
            children: [
              GzFactChip(icon: GzIcons.calendar, label: l.hotelDecisionsFactDate, value: f.date(b.eventDate.toString(), DateStyle.short)),
              if (guests > 0) GzFactChip(icon: GzIcons.usersThree, label: l.hotelDecisionsFactGuests, value: f.integer(guests)),
              if (section != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GzFactChip(icon: sessionGlyph(section.start), label: l.hotelDecisionsFactSession),
                    const SizedBox(width: GzSpace.s3),
                    GzFactChip(icon: audienceIcon, label: audienceWord),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
