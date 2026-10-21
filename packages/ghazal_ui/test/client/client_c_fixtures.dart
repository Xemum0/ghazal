import 'package:ghazal_domain/ghazal_domain.dart';

const _img = {
  'file': 'details/details-39-x.jpg',
  'width': 1800,
  'height': 1200,
  'orientation': 'landscape',
  'alt': {'en': 'A photo', 'ar': 'صورة'},
};
Map<String, Object?> _m(int fils) => {'fils': fils, 'currency': 'KWD'};

ChecklistItem checkItem({bool done = false, bool auto = false, bool custom = false, String? due = '2026-11-20', String? category = 'photography', String? doneAt}) => ChecklistItem.fromJson({
      'id': 'chk-1',
      'group': 'photographer',
      'title': {'en': 'Photographer', 'ar': 'اختيار المصوّرة'},
      'dueOn': due,
      'done': done,
      'doneAt': doneAt,
      'auto': auto,
      'custom': custom,
      'serviceCategoryId': category,
      'bookingId': null,
    });

Map<String, Object?> _cat(String id, String icon, int allocated, int paid, int committed, {bool linked = false}) => {
      'id': id,
      'name': {'en': 'Category $id', 'ar': 'فئة $id'},
      'allocated': _m(allocated),
      'paid': _m(paid),
      'committed': _m(committed),
      'autoLinked': linked,
      'icon': icon,
    };

Budget budget({int total = 60000000, List<Map<String, Object?>>? categories}) => Budget.fromJson({
      'total': _m(total),
      'categories': categories ?? [_cat('venue_catering', 'hall', 32000000, 2000, 15400000, linked: true), _cat('photo_video', 'camera', 4000000, 0, 0)],
      'expenses': <Object?>[],
    });

Map<String, Object?> budgetCategory(String id, {required int allocated, int paid = 0, int committed = 0}) => _cat(id, 'flower', allocated, paid, committed);

PlannerPackage plannerPackage({int marks = 2}) => PlannerPackage.fromJson({
      'id': 'planner-gold',
      'tier': 'gold',
      'name': {'en': 'Gold', 'ar': 'الذهبية'},
      'tagline': {'en': 'Planning and styling', 'ar': 'تخطيط وتنسيق'},
      'marks': marks,
      'from': _m(1900000),
      'inclusions': [
        {'en': 'Everything in Silver', 'ar': 'كل ما في الفضية'},
        {'en': 'Two planning meetings', 'ar': 'اجتماعا تخطيط'},
      ],
      'suits': {'en': 'Couples who want help', 'ar': 'لأزواج يريدون مساعدة'},
      'image': _img,
    });

ServiceCategory serviceCategory() => ServiceCategory.fromJson({
      'id': 'catering',
      'groupId': 'hospitality',
      'primary': true,
      'name': {'en': 'Hospitality and catering', 'ar': 'الضيافة والتموين'},
      'description': {'en': 'Coffee', 'ar': 'قهوة'},
      'icon': 'drinks',
      'image': _img,
      'anchor': {'min': _m(6000), 'max': _m(16000), 'unit': {'en': 'per guest', 'ar': 'للضيف الواحد'}},
      'order': 1,
    });

ServiceProvider vendor({bool rated = true, bool voucher = true, bool female = true, bool verified = true}) => ServiceProvider.fromJson({
      'id': 'vendor-1',
      'categoryId': 'catering',
      'alsoCategoryIds': <Object?>[],
      'name': {'en': 'Qahwat Al-Diwan Hospitality', 'ar': 'ضيافة قهوة الديوان'},
      'monogram': 'ض',
      'areaId': 'salmiya',
      'governorateId': 'hawalli',
      'about': {'en': 'About', 'ar': 'نبذة'},
      'rating': rated ? {'average': 4.7, 'count': 61} : null,
      'from': _m(7500),
      'fromVoucher': voucher ? _m(5500) : null,
      'fromUnit': {'en': 'per guest', 'ar': 'للضيف الواحد'},
      'packages': <Object?>[],
      'portfolio': [_img, _img, _img],
      'tags': <Object?>[],
      'femaleTeamForLadies': female,
      'usuallyRepliesHours': 2,
      'verified': verified,
      'phone': '+96550000200',
    });

Message message({String id = 'msg-1', String from = 'client', String kind = 'text', String origin = 'ar', String? en, String? ar, Map<String, Object?>? extra, bool draft = false, String status = 'read', String at = '2026-11-12T11:10:00+03:00'}) =>
    Message.fromJson({
      'id': id,
      'conversationId': 'conv-1',
      'seq': 1,
      'from': from,
      'senderName': null,
      'at': at,
      'kind': kind,
      'text': en == null && ar == null ? null : {'en': en, 'ar': ar},
      'origin': origin,
      'status': status,
      'draft': draft,
      ...?extra,
    });

Conversation conversation({int unread = 0, bool pinned = false}) => Conversation.fromJson({
      'id': 'conv-1',
      'kind': 'planner',
      'title': {'en': 'Nouf Al-Otaibi', 'ar': 'نوف العتيبي'},
      'subtitle': {'en': 'Meeting Sun 15 Nov', 'ar': 'اجتماع الأحد 15 نوفمبر'},
      'monogram': 'ن',
      'clientId': 'user-reem',
      'clientName': 'ريم',
      'venueId': null,
      'bookingId': null,
      'plannerId': 'planner-nouf',
      'vendorId': null,
      'pinned': pinned,
      'unread': {'client': unread, 'hotel': 0},
      'handledBy': null,
      'lastMessageAt': '2026-11-12T11:48:00+03:00',
      'awaitingReplySince': null,
      'usuallyRepliesHours': null,
    });
