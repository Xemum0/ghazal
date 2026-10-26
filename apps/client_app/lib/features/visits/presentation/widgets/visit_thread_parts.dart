import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Message, MessageFrom, MessageKind, ThreadMember, ThreadRole, VisitThread;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class VisitThreadSlivers extends StatelessWidget {
  const VisitThreadSlivers({required this.thread, required this.meId, super.key});

  final VisitThread thread;
  final String? meId;

  /// A system line says what happened in a few words (the seeded and the store's lines are full sentences).
  String _shortLine(BuildContext context, Message m) {
    final l = context.l10n;
    if (m.kind == MessageKind.visitCard) return l.clientVisitsSysConfirmed;
    final en = (m.text?.en ?? '').toLowerCase();
    if (en.contains('group chat opened')) return l.clientVisitsSysOpened;
    if (en.contains('could not offer')) return l.clientVisitsSysDeclined;
    if (en.contains('cancelled')) return l.clientVisitsSysCancelled;
    if (en.contains('arrival confirmed')) return l.clientVisitsSysArrived;
    if (en.contains('visit is complete')) return l.clientVisitsSysCompleted;
    if (en.contains('missed')) return l.clientVisitsSysMissed;
    if (en.contains('read-only')) return l.clientVisitsSysClosed;
    if (en.contains('hotel confirmed your visit')) return l.clientVisitsSysConfirmed;
    return m.text?.of(context.gz.locale.languageCode) ?? '';
  }

  /// The glyph of a system line: what happened, read from the seeded English line (the web `systemIcon`).
  IconData _systemIcon(Message m) {
    final key = '${m.id} ${m.text?.en ?? ''}'.toLowerCase();
    if (RegExp('cancel|declin|could not offer').hasMatch(key)) return GzIcons.close;
    if (RegExp('closed|read-only').hasMatch(key)) return GzIcons.lock;
    if (RegExp('arriv').hasMatch(key)) return GzIcons.pin;
    if (RegExp('complete|visit is done').hasMatch(key)) return GzIcons.checkDouble;
    if (RegExp('propos|asked').hasMatch(key)) return GzIcons.calendarDots;
    if (RegExp('missed').hasMatch(key)) return GzIcons.userMinus;
    if (RegExp('confirm').hasMatch(key) || m.kind == MessageKind.visitCard) return GzIcons.calendarCheck;
    return GzIcons.usersThree;
  }

  @override
  Widget build(BuildContext context) {
    final f = context.gzFormat;
    final lang = context.gz.locale.languageCode;
    final messages = thread.messages.where((m) => !m.draft).toList();
    if (messages.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
          child: GzEmptyState(fill: false, illustration: GzIllustrationName.emptyMessages, title: context.l10n.clientVisitsSysOpened),
        ),
      );
    }
    String? lastKey;
    return SliverPadding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s3, bottom: GzSpace.s4),
      sliver: SliverList.builder(
        itemCount: messages.length,
        itemBuilder: (context, i) {
          final m = messages[i];
          final d = f.isoDay(m.at);
          final newDay = i == 0 || f.isoDay(messages[i - 1].at) != d;
          final sys = m.kind == MessageKind.system || m.kind == MessageKind.visitCard;
          final key = sys ? 'system' : m.from.value;
          final runStart = newDay || key != lastKey || lastKey == 'system';
          lastKey = key;
          final next = i + 1 < messages.length ? messages[i + 1] : null;
          final nextKey = next == null
              ? null
              : (next.kind == MessageKind.system || next.kind == MessageKind.visitCard)
              ? 'system'
              : next.from.value;
          final runEnd = nextKey != key || (next != null && f.isoDay(next.at) != d);
          final own = !sys && m.from == MessageFrom.client;
          ThreadMember? member;
          if (!sys && !own) {
            final role = m.from == MessageFrom.venue ? ThreadRole.hotelRepresentative : ThreadRole.support;
            member = thread.thread.members?.where((x) => x.role == role).firstOrNull;
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (newDay) ...[const SizedBox(height: GzSpace.s4), GzChatDateDivider(date: d), if (sys) const SizedBox(height: GzSpace.s3)],
              if (sys) ...[
                const SizedBox(height: GzSpace.s3),
                VisitSystemLine(text: _shortLine(context, m), icon: _systemIcon(m)),
                const SizedBox(height: GzSpace.s3),
              ] else ...[
                SizedBox(height: runStart ? GzSpace.s4 : GzSpace.s1),
                if (member != null) VisitSenderLine(member: member, lang: lang),
                GzChatBubble(message: m, side: GzChatSide.client, showMeta: runEnd),
              ],
            ],
          );
        },
      ),
    );
  }
}

class VisitSystemLine extends StatelessWidget {
  const VisitSystemLine({required this.text, required this.icon, super.key});

  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Align(
      alignment: Alignment.center,
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceQuiet, borderRadius: GzRadius.xsAll),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(vertical: GzSpace.s1, horizontal: GzSpace.s3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GzIcon(icon, size: GzIconSize.xs, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              Flexible(
                child: GzText(text, role: GzTextRole.caption, color: c.textSecondary, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class VisitSenderLine extends StatelessWidget {
  const VisitSenderLine({required this.member, required this.lang, super.key});

  final ThreadMember member;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final short = member.role == ThreadRole.hotelRepresentative ? l.clientVisitsRoleHotel : l.clientVisitsRoleSupport;
    final full = member.role == ThreadRole.hotelRepresentative ? context.gzL10n.commonRoleHotelRep : context.gzL10n.commonRoleSupport;
    final name = lang == 'ar' ? member.name : member.nameLatin;
    final (Color bg, Color fg) = member.role == ThreadRole.hotelRepresentative
        ? (c.statusNeutralBg, c.statusNeutralText)
        : (c.surfaceTint, c.textStrong);
    return Semantics(
      container: true,
      label: '$name, $full',
      child: ExcludeSemantics(
        // The web chip (`.gzvt-sc`): 4 in from the bubble edge, 8 / 4 padding, no border, the pill minimum high.
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.s1, end: GzSpace.s1, bottom: GzSpace.s1),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              constraints: const BoxConstraints(minHeight: GzSize.pillMin),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s2, vertical: GzSpace.s1),
              decoration: BoxDecoration(color: bg, borderRadius: GzRadius.xsAll),
              child: GzText(short, role: GzTextRole.pill, color: fg, softWrap: false, overflow: TextOverflow.visible),
            ),
          ),
        ),
      ),
    );
  }
}

class VisitChatSkeleton extends StatelessWidget {
  const VisitChatSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          GzSkeleton(blockSize: 112),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(inlineSize: 248, blockSize: 72),
          SizedBox(height: GzSpace.s3),
          GzSkeleton(inlineSize: 216, blockSize: 72),
        ],
      ),
    );
  }
}
