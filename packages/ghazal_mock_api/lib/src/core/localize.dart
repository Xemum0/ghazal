/// English responses carry Latin person names where the web prototype's English UI shows them. The client app shows every known name in its
/// Latin spelling (`User.nameLatin`, `StaffMember.nameLatin`). The partner app shows its own staff in Latin but the guests and clients as
/// authored in Arabic (`clientName`, `senderName`, `contact.name`), exactly as the web does. Arabic responses are untouched.
library;

import 'app.dart';

const _nameKeys = {'clientName', 'actorName', 'senderName', 'blockedBy', 'invitedBy'};
const _staffKeys = {'actorName', 'blockedBy', 'invitedBy'};

Object? localizeNames(MockApp app, Object? body, String lang, {bool partner = false}) {
  if (lang != 'en' || body == null) return body;
  final latin = <String, String>{};
  for (final collection in partner ? const ['StaffMember'] : const ['User', 'StaffMember']) {
    for (final d in app.db.raw(collection)) {
      final ar = d['name'], en = d['nameLatin'];
      if (ar is String && en is String && en.isNotEmpty) latin[ar] = en;
    }
  }
  if (latin.isEmpty) return body;
  final keys = partner ? _staffKeys : _nameKeys;
  Object? walk(Object? v, {bool contact = false}) {
    if (v is List) return [for (final e in v) walk(e)];
    if (v is Map) {
      // A staff or chat member carries both spellings: the English response leads with the Latin one (the client's own profile keeps its name).
      final lead =
          v['nameLatin'] is String && (v['nameLatin'] as String).isNotEmpty && v['name'] is String && v['role'] != 'client' && v['nameLatin'] != v['name'];
      return {
        if (lead) 'name': v['nameLatin'],
        for (final e in v.entries)
          if (!(lead && e.key == 'name'))
            e.key: (e.value is String && (keys.contains(e.key) || (!partner && contact && e.key == 'name')))
                ? (latin[e.value] ?? e.value)
                : walk(e.value, contact: e.key == 'contact'),
      };
    }
    return v;
  }

  return walk(body);
}
