import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show GzFormat;
import 'package:ghazal_domain/ghazal_domain.dart' show Conversation, ConversationKind, Message, MessageKind, ThreadRole, WireLang;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';

/// `11 Nov` / `11 نوفمبر`: the day and the short month name, no weekday, no year (a list column is narrow).
String dayMonthShort(BuildContext context, DateTime at) {
  final f = context.gzFormat;
  final c = f.civil(at);
  return context.l10n.clientMessagesDayMonth(f.integer(c.day), f.monthName(c.month, short: true));
}

/// A row's time: today the clock (`3:12 PM`), any other day the short date (`3 Nov`).
String rowTime(BuildContext context, DateTime at) {
  final f = context.gzFormat;
  return f.isoDay(at) == f.isoDay(f.now()) ? f.time(at) : dayMonthShort(context, at);
}

/// `m:ss` of a voice note.
String clockOf(BuildContext context, int seconds) => '${context.gzFormat.integer(seconds ~/ 60)}:${(seconds % 60).toString().padLeft(2, '0')}';

/// The name of a conversation in the viewer's language.
String conversationName(BuildContext context, Conversation c) {
  final t = c.title.of(context.gz.locale.languageCode);
  // A visit chat is named after the venue ("Site visit · Aurelia Gulf Hotel"): the visit date is a fact under it.
  if (c.kind == ConversationKind.visitGroup && t.contains('·')) return t.split('·').last.trim();
  return t;
}

/// A text message in its own language (each message keeps its script).
String messageText(Message m, String lang) {
  final t = m.text;
  if (t == null) return '';
  return t.of(m.origin == WireLang.ar ? 'ar' : (m.origin == WireLang.en ? 'en' : lang));
}

/// The preview of a message is one line cut at a word boundary: a glimpse, never a paragraph.
String clipWords(String text, [int words = 5]) {
  final parts = text.trim().split(RegExp(r'\s+'));
  return parts.length > words ? '${parts.take(words).join(' ')}…' : text.trim();
}

/// A compact duration for facts: the shared formatter, with an empty trailing
/// unit dropped so whole hours read `2 س`, not `2 س 0 د` (web `useDuration`).
/// Remove when the shared formatter does it (requests.md).
String shortDuration(GzFormat f, num ms) =>
    f.duration(ms).replaceAll(RegExp(' \u2066?[0\u0660]\u2069?\u00a0(?:m|\u062f|h|\u0633)\$'), '');

bool isVisitChat(Conversation c) => c.kind == ConversationKind.visitGroup;

/// The glyph of a role in a visit group chat.
IconData roleIcon(ThreadRole r) => switch (r) {
  ThreadRole.client => GzIcons.user,
  ThreadRole.hotelRepresentative => GzIcons.hotel,
  _ => GzIcons.headset,
};

/// Whether [k] is a message that carries media (voice, photo, document).
bool isMedia(MessageKind k) => k == MessageKind.voice || k == MessageKind.image || k == MessageKind.document;

final RegExp _rtl = RegExp(r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');
final RegExp _latin = RegExp(r'[A-Za-z]');

/// The direction a text takes from its first strong character (every message aligns by its own script, ADR 0014 D8).
TextDirection autoDir(String text) {
  for (final r in text.runes) {
    final ch = String.fromCharCode(r);
    if (_rtl.hasMatch(ch)) return TextDirection.rtl;
    if (_latin.hasMatch(ch)) return TextDirection.ltr;
  }
  return TextDirection.ltr;
}
