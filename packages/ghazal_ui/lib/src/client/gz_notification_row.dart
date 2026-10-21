import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show AppNotification, NotificationChannel, NotificationKind, NotificationTone;

import '../brand/gz_thread_knot.dart';
import '../core/core.dart';
import '../foundation.dart';

/// One glyph per notification kind (the web `KIND_ICON`); an unknown kind reads as a bell.
IconData gzNotificationIcon(NotificationKind kind) {
  final name = switch (kind) {
    NotificationKind.requestSent => 'send',
    NotificationKind.requestApproved => 'check-circle',
    NotificationKind.confirmReminder => 'hourglass',
    NotificationKind.requestConfirmed => 'calendar-check',
    NotificationKind.requestDeclined => 'x-circle',
    NotificationKind.requestExpired => 'clock-off',
    NotificationKind.bookingCancelled => 'x-circle',
    NotificationKind.voucherReady => 'ticket',
    NotificationKind.voucherReleased => 'undo',
    NotificationKind.voucherRedeemed => 'check-double',
    NotificationKind.creditVoucherIssued => 'gift',
    NotificationKind.voucherForfeited => 'x-circle',
    NotificationKind.voucherExpiring => 'clock',
    NotificationKind.visitRequested => 'calendar-plus',
    NotificationKind.visitConfirmed => 'calendar-check',
    NotificationKind.visitReminder => 'bell',
    NotificationKind.visitMessage => 'users-three',
    NotificationKind.newRequest => 'bell',
    NotificationKind.clientConfirmed => 'check-circle',
    NotificationKind.clientLapsed => 'clock-off',
    NotificationKind.voucherRedeemedByYou => 'qr-code',
    NotificationKind.visitRequest => 'calendar-plus',
    NotificationKind.listingSubmitted => 'megaphone',
    NotificationKind.listingApproved => 'check-circle',
    NotificationKind.listingRejected => 'x-circle',
    NotificationKind.listingExpiring => 'clock',
    NotificationKind.reviewReceived => 'star',
    NotificationKind.calendarConfirm => 'calendar-check',
    NotificationKind.invite => 'user-plus',
    NotificationKind.countdown => 'calendar',
    NotificationKind.newVenue => 'venue',
    NotificationKind.plannerAssigned => 'user',
    NotificationKind.message => 'chat',
    NotificationKind.reviewPrompt => 'star',
    NotificationKind.checklistDue => 'checklist',
    NotificationKind.unknown => 'bell',
  };
  return GzIcons.byName[name] ?? GzIcons.byName['bell']!;
}

/// NotificationRow (CA-NTF, ADR 0003 D9): one notification as a row. A glyph in a tone disk (a reinforcement, never the only signal:
/// the title says what happened), the title, up to two lines of the ready-made body, the time and, while unread, a gold bead.
/// Marketing arrives only by opt-in (ADR 0015 D8); the row marks it with a quiet "Offer" tag. One button for assistive technology.
class GzNotificationRow extends StatelessWidget {
  const GzNotificationRow({required this.notification, this.onOpen, this.last = false, this.previewState, super.key});

  final AppNotification notification;
  final VoidCallback? onOpen;

  /// Hides the hairline under the last row of a list.
  final bool last;

  /// Gallery only.
  final GzPreviewState? previewState;

  @override
  Widget build(BuildContext context) {
    final gz = context.gz;
    final c = gz.colors;
    final l = context.gzL10n;
    final lang = gz.locale.languageCode;
    final n = notification;
    final unread = !n.read;
    final title = n.title.of(lang);
    final body = n.body.of(lang);
    final time = context.gzFormat.ago(n.at);
    final (Color diskBg, Color diskFg) = switch (n.tone) {
      NotificationTone.gold => (c.statusPendingBg, c.statusPendingText),
      NotificationTone.success => (c.statusSuccessBg, c.statusSuccessText),
      NotificationTone.danger => (c.statusDangerBg, c.statusDangerText),
      _ => (c.statusNeutralBg, c.statusNeutralText),
    };
    final tag = n.tag?.of(lang) ?? (n.channel == NotificationChannel.marketing ? l.uiClientNotificationMarketing : null);
    final titleStyle = gz.text(GzTextRole.title).copyWith(
      color: c.textStrong,
      decoration: TextDecoration.none,
      fontWeight: unread ? null : gz.text(GzTextRole.body).fontWeight,
    );

    Widget row(bool pressed) => Container(
      constraints: const BoxConstraints(minHeight: GzSize.rowMin),
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4, bottom: GzSpace.s4),
      decoration: BoxDecoration(
        color: pressed ? c.surfaceQuiet : null,
        border: Border(bottom: BorderSide(color: last ? c.scrimClear : c.borderHairline, width: last ? 0 : GzStroke.hair)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: GzSize.thumbSm,
            height: GzSize.thumbSm,
            decoration: BoxDecoration(shape: BoxShape.circle, color: diskBg),
            child: Center(child: GzIcon(gzNotificationIcon(n.kind), size: GzIconSize.sm, color: diskFg)),
          ),
          const SizedBox(width: GzSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: titleStyle)),
                    if (tag != null) ...[const SizedBox(width: GzSpace.s2), GzBadge(label: tag, variant: GzBadgeVariant.quiet)],
                  ],
                ),
                const SizedBox(height: GzSpace.s1),
                GzText(body, role: GzTextRole.bodyS, maxLines: 2, figures: true),
                const SizedBox(height: GzSpace.s1),
                GzText(time, role: GzTextRole.caption, color: c.textSecondary, figures: true),
              ],
            ),
          ),
          if (unread) const Padding(padding: EdgeInsetsDirectional.only(start: GzSpace.s3, top: GzSpace.s2), child: GzThreadBead()),
        ],
      ),
    );

    final label = '$title. $body. $time${unread ? '. ${l.uiClientNotificationUnread}' : ''}';
    return GzPressable(
      onPressed: onOpen,
      semanticLabel: label,
      scale: 1,
      minHeight: 0,
      pressedColor: null,
      builder: (context, st) => row(st.pressed || previewState == GzPreviewState.pressed),
    );
  }
}
