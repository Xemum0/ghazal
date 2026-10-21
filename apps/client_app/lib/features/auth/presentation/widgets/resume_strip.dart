import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, gzFormatProvider;
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/auth_resume.dart';

/// The glyph and the noun of each commit moment (web `REASON`).
(IconData, String) authReasonOf(AppL10n l10n, GateReason reason) => switch (reason) {
      GateReason.sendRequest => (GzIcons.send, l10n.clientAuthReasonSendRequest),
      GateReason.voucher => (GzIcons.ticket, l10n.clientAuthReasonVoucher),
      GateReason.visit => (GzIcons.door, l10n.clientAuthReasonVisit),
      GateReason.chat => (GzIcons.chat, l10n.clientAuthReasonChat),
      GateReason.review => (GzIcons.star, l10n.clientAuthReasonReview),
      GateReason.planner => (GzIcons.checklist, l10n.clientAuthReasonPlanner),
      GateReason.quote => (GzIcons.receipt, l10n.clientAuthReasonQuote),
      GateReason.save => (GzIcons.heart, l10n.clientAuthReasonSave),
    };

/// Reasons that carry a booking in flight (a venue, a date, a guest count). The others have nothing to preview.
bool authHasResume(GateReason? reason) => reason == GateReason.sendRequest || reason == GateReason.voucher || reason == GateReason.visit;

/// What is waiting on the other side of the sign-in, told without a sentence (ADR 0007 D9, "never loses a draft"). A request, voucher or
/// visit shows the venue (cover thumb, serif name) and two facts with a quiet glyph at the end edge; every other reason is one rose disk
/// with its glyph and a one-word noun. No label, no caption: the strip is the context line.
class AuthResumeStrip extends ConsumerWidget {
  const AuthResumeStrip({required this.reason, this.compact = false, super.key});

  final GateReason? reason;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reason;
    if (r == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final c = context.gz.colors;
    final (icon, noun) = authReasonOf(l10n, r);
    final rule = BorderSide(color: c.borderHairline, width: GzStroke.hair);
    final pad = compact ? GzSpace.s3 : GzSpace.s4;
    if (!authHasResume(r)) {
      return DecoratedBox(
        decoration: BoxDecoration(border: Border(top: rule, bottom: rule)),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s3),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                child: SizedBox(width: GzSize.thumbMd, height: GzSize.thumbMd, child: Center(child: GzIcon(icon, size: GzIconSize.md, color: c.iconSecondary))),
              ),
              const SizedBox(width: GzSpace.s4),
              Expanded(child: GzText(noun, role: GzTextRole.title, color: c.textStrong)),
            ],
          ),
        ),
      );
    }
    final resume = ref.watch(authResumeProvider).value;
    if (resume == null) return const SizedBox(height: GzSize.thumbMd);
    final f = ref.watch(gzFormatProvider);
    final lang = f.lang.name;
    final cover = resume.venue.cover;
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: rule, bottom: rule)),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: pad),
          child: Row(
            children: [
              if (cover != null) ...[
                ClipRRect(
                  borderRadius: GzRadius.xsAll,
                  child: SizedBox(width: GzSize.thumbMd, height: GzSize.thumbMd, child: GzPhoto(src: gzImageSrc(cover.file, cover.baseUrl), alt: '')),
                ),
                const SizedBox(width: GzSpace.s4),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzText(resume.venue.name.of(lang), role: GzTextRole.d1, color: c.textStrong, maxLines: 2),
                    const SizedBox(height: GzSpace.s1),
                    Wrap(
                      spacing: GzSpace.s3,
                      runSpacing: GzSpace.s1,
                      children: [
                        GzFactChip(icon: GzIcons.calendar, value: f.date(resume.date.toString(), DateStyle.dayMonth), label: l10n.clientAuthSharedDate, small: true),
                        GzFactChip(icon: GzIcons.usersThree, value: f.integer(resume.guests), label: l10n.clientAuthSharedGuests, small: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: GzSpace.s4),
              Semantics(
                label: noun,
                child: DecoratedBox(
                  decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceTint),
                  child: SizedBox(width: GzSize.disk, height: GzSize.disk, child: Center(child: GzIcon(icon, size: GzIconSize.sm, color: c.iconSecondary))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
