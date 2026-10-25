import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification, NotificationChannel, NotificationKind, NotificationTone;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/messages_format.dart' show shortDuration;
import '../../application/notification_view.dart';
import '../../application/ntf_data.dart';

IconData _iconOf(NotificationKind k) => gzNotificationIcon(k);

String? _titleOf(AppLocalizationsAlias l, NotificationKind k) => switch (k) {
  NotificationKind.requestSent => l.clientMessagesNtfKindRequestSent,
  NotificationKind.requestApproved => l.clientMessagesNtfKindApproved,
  NotificationKind.confirmReminder => l.clientMessagesNtfKindConfirmReminder,
  NotificationKind.requestConfirmed => l.clientMessagesNtfKindConfirmed,
  NotificationKind.requestDeclined => l.clientMessagesNtfKindDeclined,
  NotificationKind.requestExpired => l.clientMessagesNtfKindExpired,
  NotificationKind.bookingCancelled => l.clientMessagesNtfKindCancelled,
  NotificationKind.voucherReady => l.clientMessagesNtfKindVoucherReady,
  NotificationKind.voucherReleased => l.clientMessagesNtfKindVoucherKept,
  NotificationKind.voucherRedeemed => l.clientMessagesNtfKindRedeemed,
  NotificationKind.creditVoucherIssued => l.clientMessagesNtfKindRefunded,
  NotificationKind.voucherForfeited => l.clientMessagesNtfKindExpired,
  NotificationKind.voucherExpiring => l.clientMessagesNtfKindExpiring,
  NotificationKind.visitRequested => l.clientMessagesNtfKindVisitRequested,
  NotificationKind.visitConfirmed => l.clientMessagesNtfKindVisitConfirmed,
  NotificationKind.visitReminder => l.clientMessagesNtfKindVisitSoon,
  NotificationKind.visitMessage => l.clientMessagesNtfKindVisitChat,
  NotificationKind.newVenue => l.clientMessagesNtfKindNewVenue,
  NotificationKind.reviewPrompt => l.clientMessagesNtfKindReview,
  NotificationKind.countdown => l.clientMessagesNtfKindCountdown,
  NotificationKind.checklistDue => l.clientMessagesNtfKindChecklist,
  _ => null,
};

typedef AppLocalizationsAlias = AppL10n;

/// One notification of the centre, as a glyph and a few words (ADR 0034): a tone disk, the title in at most two words (from the kind),
/// the venue as a quiet line (or a fact: time left, days to the wedding, a due date), the clock and, while unread, the gold bead.
class NtfRow extends ConsumerWidget {
  const NtfRow({required this.notification, required this.onOpen, this.last = false, super.key});

  final AppNotification notification;
  final VoidCallback onOpen;
  final bool last;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.l10n;
    final f = context.gzFormat;
    final lang = gz.locale.languageCode;
    final n = notification;
    final unread = !n.read;
    final title = _titleOf(l, n.kind) ?? n.title.of(lang);
    final venueName = kAboutVenue.contains(n.kind) && n.venueId != null ? ref.watch(venueNameProvider(n.venueId!)).value?.of(lang) : null;
    String? str(String k) => n.params[k] is String ? n.params[k] as String : null;
    final confirmBy = str('confirmBy');
    final now = ref.watch(clockProvider)();

    final facts = <Widget>[];
    if ((n.kind == NotificationKind.requestApproved || n.kind == NotificationKind.confirmReminder) && confirmBy != null) {
      final hours = ((DateTime.parse(confirmBy).difference(now).inMinutes) / 60).ceil().clamp(0, 1 << 20);
      facts.add(
        GzFactChip(
          icon: GzIcons.timer,
          label: l.clientMessagesFactTimeLeft,
          value: shortDuration(f, hours * 3600000),
          tone: GzFactTone.accent,
          small: true,
        ),
      );
    }
    final weddingDate = n.kind == NotificationKind.countdown ? str('weddingDate') : null;
    final dueOn = n.kind == NotificationKind.checklistDue ? str('dueOn') : null;
    final meetingAt = n.kind == NotificationKind.plannerAssigned ? str('meetingAt') : null;
    if (weddingDate != null) {
      final days = DateTime.parse(weddingDate).difference(DateTime.parse(f.isoDay(n.at))).inDays.clamp(0, 1 << 20);
      facts.add(
        GzFactChip(
          icon: GzIcons.timer,
          label: l.clientMessagesFactDaysLeft,
          value: shortDuration(f, days * 86400000),
          tone: GzFactTone.accent,
          small: true,
        ),
      );
    } else if (dueOn != null) {
      facts.add(
        GzFactChip(
          icon: GzIcons.calendar,
          label: l.clientMessagesFactDue,
          value: f.date(dueOn, DateStyle.dayMonth),
          tone: GzFactTone.muted,
          small: true,
        ),
      );
    } else if (meetingAt != null) {
      facts.add(
        GzFactChip(
          icon: GzIcons.calendar,
          label: l.clientMessagesFactMeeting,
          value: f.date(meetingAt, DateStyle.dayMonth),
          tone: GzFactTone.muted,
          small: true,
        ),
      );
    }

    final (Color diskBg, Color diskFg) = switch (n.tone) {
      NotificationTone.gold => (c.statusPendingBg, c.statusPendingText),
      NotificationTone.success => (c.statusSuccessBg, c.statusSuccessText),
      NotificationTone.danger => (c.statusDangerBg, c.statusDangerText),
      _ => (c.statusNeutralBg, c.statusNeutralText),
    };
    final titleStyle = gz
        .text(GzTextRole.title)
        .copyWith(color: c.textStrong, decoration: TextDecoration.none, fontWeight: unread ? null : gz.text(GzTextRole.body).fontWeight);
    final spoken = [title, ?venueName, f.time(n.at), if (unread) l.clientMessagesNtfUnread].join(', ');

    return Column(
      key: ValueKey<String>('messages.ntf.${n.id}'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPressable(
          onPressed: onOpen,
          semanticLabel: spoken,
          scale: 1,
          minHeight: 0,
          minWidth: 0,
          builder: (context, st) => Container(
            color: st.pressed ? c.surfaceQuiet : null,
            constraints: const BoxConstraints(minHeight: GzSize.rowMin),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s3),
            child: Row(
              children: [
                Container(
                  width: GzSize.thumbSm,
                  height: GzSize.thumbSm,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: diskBg),
                  child: Center(
                    child: GzIcon(_iconOf(n.kind), size: GzIconSize.sm, color: diskFg),
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(title, style: titleStyle)),
                          if (n.channel == NotificationChannel.marketing) ...[
                            const SizedBox(width: GzSpace.s2),
                            GzBadge(label: l.clientMessagesNtfOffer, variant: GzBadgeVariant.quiet),
                          ],
                        ],
                      ),
                      if (venueName != null || facts.isNotEmpty) ...[
                        const SizedBox(height: GzSpace.s1),
                        Wrap(
                          spacing: GzSpace.s3,
                          runSpacing: GzSpace.s1,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (venueName != null) GzText(venueName, role: GzTextRole.bodyS, color: c.textSecondary),
                            ...facts,
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: GzSpace.s3),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GzText(f.time(n.at), role: GzTextRole.caption, color: c.textSecondary, figures: true, softWrap: false),
                    if (unread) ...[const SizedBox(height: GzSpace.s2), const GzThreadBead()],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (!last)
          Container(
            margin: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
            height: GzStroke.hair,
            color: c.borderHairline,
          ),
      ],
    );
  }
}
