/// Notifications produced by events (api-conventions: "dispatched by event"). The mock fills the notification centre of the people the real push
/// would reach; copy is bilingual from small templates, params carry the ids so a client could re-render from `kind` and `params`.
library;

import '../core/app.dart';
import '../engine/json.dart';

typedef Vars = Map<String, Object>;

String _fill(String tpl, Vars vars, String lang) => tpl.replaceAllMapped(RegExp(r'\{(\w+)\}'), (m) {
  final v = vars[m[1]];
  if (v == null) return '';
  if (v is Map) return (v[lang] ?? v['en'] ?? '').toString();
  return v.toString();
});

class _T {
  const _T(this.tone, this.titleEn, this.titleAr, this.bodyEn, this.bodyAr, {this.tag, this.channel = 'transactional'});
  final String tone;
  final String titleEn, titleAr, bodyEn, bodyAr;
  final bool? tag;
  final String channel;
}

const _templates = <String, _T>{
  'request_sent': _T(
    'neutral',
    'Request sent',
    'تم إرسال الطلب',
    'Request sent to {venue} at the voucher price for {date}. Expected reply by {replyBy}.',
    'تم إرسال طلبكم إلى {venue} بسعر الكوبون ليوم {date}. الرد المتوقع قبل {replyBy}.',
  ),
  'request_approved': _T(
    'success',
    'Approved: confirm within 24 hours',
    'تمت الموافقة: أكدوا خلال 24 ساعة',
    '{venue} approved {date}. Confirm by {confirmBy} to keep the date.',
    'وافق {venue} على {date}. أكدوا قبل {confirmBy} للحفاظ على التاريخ.',
  ),
  'confirm_reminder': _T(
    'gold',
    'Confirm soon',
    'أكدوا قريبًا',
    'Your approval at {venue} for {date} ends at {confirmBy}. After that the date is released and the voucher is not valid.',
    'تنتهي موافقة {venue} على {date} عند {confirmBy}. بعدها يُحرَّر التاريخ ولا يصلح الكوبون.',
  ),
  'request_confirmed': _T(
    'success',
    'Booking confirmed',
    'تم تأكيد الحجز',
    '{date} at {venue} is confirmed. Settle the price directly with the venue; show your voucher on the day.',
    'تم تأكيد {date} في {venue}. سددوا السعر مباشرة للقاعة وأظهروا كوبونكم يوم المناسبة.',
  ),
  'request_declined': _T(
    'neutral',
    'Not accepted',
    'لم يُقبل الطلب',
    '{venue} could not accept {date}. Your voucher is still yours: use it again or ask for a credit voucher.',
    'لم تتمكن {venue} من قبول {date}. كوبونكم ما زال لكم: استخدموه مجددًا أو اطلبوا كوبون رصيد.',
  ),
  'request_expired': _T(
    'neutral',
    'Request expired',
    'انتهت مهلة الطلب',
    '{venue} did not reply in time for {date}. Nothing was lost: your voucher is still yours.',
    'لم تردّ {venue} في الوقت المحدد على {date}. لم تخسروا شيئًا: كوبونكم ما زال لكم.',
  ),
  'booking_cancelled': _T('neutral', 'Request cancelled', 'تم إلغاء الطلب', '{date} at {venue} was cancelled.', 'تم إلغاء {date} في {venue}.'),
  'voucher_ready': _T(
    'success',
    'Your voucher is ready',
    'كوبونكم جاهز',
    'Voucher {code} is bound to {venue}. Send your request at the voucher price.',
    'الكوبون {code} مرتبط بـ {venue}. أرسلوا طلبكم بسعر الكوبون.',
  ),
  'voucher_released': _T(
    'neutral',
    'Your voucher is still yours',
    'كوبونكم ما زال لكم',
    'Voucher {code} is back in your wallet. Use it again at the same place until {reuseUntil}.',
    'عاد الكوبون {code} إلى محفظتكم. استخدموه مجددًا في المكان نفسه حتى {reuseUntil}.',
  ),
  'voucher_redeemed': _T('success', 'Voucher used', 'تم استخدام الكوبون', 'Voucher {code} was used at {venue}.', 'تم استخدام الكوبون {code} في {venue}.'),
  'voucher_forfeited': _T(
    'neutral',
    'Confirm window ended',
    'انتهت مهلة التأكيد',
    'The 24 hours to confirm {date} at {venue} passed. The date is released and voucher {code} is no longer valid.',
    'مرّت 24 ساعة على تأكيد {date} في {venue}. تم تحرير التاريخ ولم يعد الكوبون {code} صالحًا.',
  ),
  'credit_voucher_issued': _T(
    'success',
    'Credit voucher issued',
    'تم إصدار كوبون رصيد',
    'Support added a credit voucher for you. Use it at any hall, hotel or service within 60 days.',
    'أضاف الدعم كوبون رصيد لكم. استخدموه في أي قاعة أو فندق أو خدمة خلال 60 يومًا.',
  ),
  'visit_requested': _T(
    'neutral',
    'Visit requested',
    'تم طلب الزيارة',
    'Your visit to {venue} on {slot} was sent. A group chat with the hotel and Ghazal support is open.',
    'تم إرسال طلب زيارتكم إلى {venue} يوم {slot}. محادثة جماعية مع الفندق ودعم غزل مفتوحة.',
  ),
  'visit_confirmed': _T(
    'success',
    'Visit confirmed',
    'تم تأكيد الزيارة',
    'Your visit to {venue} is confirmed for {slot}. Ghazal support is in the group chat.',
    'تم تأكيد زيارتكم لـ {venue} يوم {slot}. دعم غزل في المحادثة الجماعية.',
  ),
  'visit_message': _T(
    'neutral',
    'Visit update',
    'تحديث الزيارة',
    'The visit to {venue} on {slot} changed. Open the group chat for details.',
    'تغيّرت زيارة {venue} يوم {slot}. افتحوا المحادثة الجماعية للتفاصيل.',
  ),
  'planner_assigned': _T(
    'neutral',
    'Planner assigned',
    'تعيين منسّقة',
    '{planner} is your wedding planner. Video call on {meetingAt}, Kuwait time.',
    '{planner} هي منسّقة زفافكم. مكالمة الفيديو {meetingAt} بتوقيت الكويت.',
  ),
  'message': _T('neutral', '{sender}', '{sender}', '{sender} replied to your message.', 'ردّ {sender} على رسالتكم.'),
  'review_prompt': _T(
    'neutral',
    'How was {venue}?',
    'كيف كانت {venue}؟',
    'Tell other couples about {date} at {venue}.',
    'أخبروا العرسان الآخرين عن {date} في {venue}.',
    channel: 'transactional',
  ),
  // partner side
  'new_request': _T(
    'gold',
    'New request · {client}',
    'طلب جديد · {client}',
    '{date} · {guests} guests · voucher attached',
    '{date} · {guests} ضيفًا · الكوبون مرفق',
    tag: true,
  ),
  'client_confirmed': _T(
    'success',
    'Client confirmed · {client}',
    'أكّد العميل · {client}',
    '{date} is now a confirmed booking. The client settles with you directly.',
    'أصبح {date} حجزًا مؤكدًا. يسدد العميل لكم مباشرة.',
  ),
  'client_lapsed': _T(
    'neutral',
    'Confirm window ended · {client}',
    'انتهت مهلة التأكيد · {client}',
    '{date} · 24 hours passed without confirmation; the date is open again',
    '{date} · مرّت 24 ساعة دون تأكيد والتاريخ متاح مجددًا',
  ),
  'voucher_redeemed_by_you': _T(
    'success',
    'Voucher redeemed by you',
    'تم استخدام كوبون بواسطتكم',
    '{client} · {date} · redeemed by {staff}',
    '{client} · {date} · تم الاستخدام بواسطة {staff}',
  ),
  'visit_request': _T(
    'gold',
    'Visit request · {client}',
    'طلب زيارة · {client}',
    '{slot} · {visitors} visitors · a group chat is open with Ghazal support',
    '{slot} · {visitors} زائرين · محادثة جماعية مفتوحة مع دعم غزل',
    tag: true,
  ),
  'listing_submitted': _T('neutral', 'Listing sent for review', 'تم إرسال الإعلان للمراجعة', '{title} is waiting for review.', '{title} بانتظار المراجعة.'),
  'listing_approved': _T(
    'success',
    'Listing approved',
    'تمت الموافقة على الإعلان',
    '{title} is approved and live.',
    'تمت الموافقة على {title} وهو منشور الآن.',
  ),
  'listing_rejected': _T(
    'danger',
    'Listing needs changes',
    'الإعلان يحتاج تعديلات',
    '{title} was not approved. Open it to see what to change.',
    'لم تتم الموافقة على {title}. افتحوه لمعرفة المطلوب.',
  ),
  'review_received': _T(
    'neutral',
    'New review',
    'تقييم جديد',
    'A guest left a review. Reply once to thank them.',
    'ترك أحد الضيوف تقييمًا. ردّوا مرة واحدة لشكره.',
  ),
  'invite': _T('neutral', 'Invitation sent · {email}', 'تم إرسال دعوة · {email}', '{role} · valid for 3 days', '{role} · صالحة لمدة 3 أيام'),
};

/// Creates a notification for [userId] and stores it. [vars] are the placeholders of the template (strings or `{en, ar}` maps); [params] are the
/// raw ids and values for re-rendering. Returns the stored document.
Json notify(
  MockApp app, {
  required String userId,
  required String kind,
  required String audience,
  Vars vars = const {},
  Json params = const {},
  String? bookingId,
  String? venueId,
  String? conversationId,
  String? voucherId,
  String? visitId,
  String? listingId,
  bool force = false,
}) {
  final t = _templates[kind] ?? const _T('neutral', 'Update', 'تحديث', 'There is an update.', 'هناك تحديث.');
  final id = 'ntf-m${app.db.next('ntf').toString().padLeft(4, '0')}';
  final doc = <String, dynamic>{
    'id': id,
    'audience': audience,
    'userId': userId,
    'kind': kind,
    'title': {'en': _fill(t.titleEn, vars, 'en'), 'ar': _fill(t.titleAr, vars, 'ar')},
    'body': {'en': _fill(t.bodyEn, vars, 'en'), 'ar': _fill(t.bodyAr, vars, 'ar')},
    'params': params,
    'at': app.clock.now,
    'read': false,
    'tone': t.tone,
    'tag': t.tag == true ? {'en': 'Needs reply', 'ar': 'بانتظار الرد'} : null,
    'bookingId': bookingId,
    'venueId': venueId,
    'conversationId': conversationId,
    'channel': t.channel,
    'voucherId': voucherId,
    'visitId': visitId,
    'listingId': listingId,
  };
  app.db.put('Notification', doc);
  app.logEvent('notification', {'userId': userId, 'kind': kind, 'id': id});
  return doc;
}
