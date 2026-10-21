// The voucher gallery, part A: the Flutter twin of sections 1 to 8 of design/src/gallery/voucher.tsx (#/gallery/voucher): voucher-card, qr,
// price-compare, purchase-summary, confirm-window, role-badge, group-chat and visit-card. Same specimens, states and sample text as
// design/src/system/domain-voucher/gallery/{VoucherSections,GroupSections}.tsx, driven by real objects from GzWorld.
// Parity: `node tools/parity/parity.mjs --gallery voucher --sections 1,2,3,4,5,6,7,8` after `flutter test test/gallery/voucher_a_gallery_test.dart`.
// Deliberate differences from the web page (its copy predates ADR 0035): the purchase summary's third rule and the lapsed confirm window
// speak of a credit voucher and an invalid voucher, never "ask for your payment back" or "free to use again".
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalDate, Message, MessageFrom, MessageKind, PriceStructure, ThreadRole, Voucher;
import 'package:ghazal_ui/src/client/client.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/visits/visits.dart';
import 'package:ghazal_ui/src/voucher/voucher.dart';

import 'gz_gallery.dart';
import 'voucher_a_gallery_kit.dart';

export 'voucher_a_gallery_kit.dart' show VoucherAData;

/// The eight sections of this part; [data] is read when a section renders (after `VoucherAData.load`).
List<GzGallerySection> voucherAGallerySections(VoucherAData Function() data) => [
  GzGallerySection('voucher-card', (c) => _voucherCard(c, data()), number: 1),
  GzGallerySection('qr', (c) => _qr(c, data()), number: 2),
  GzGallerySection('price-compare', (c) => _priceCompare(c, data()), number: 3),
  GzGallerySection('purchase-summary', (c) => _purchaseSummary(c, data()), number: 4),
  GzGallerySection('confirm-window', _confirmWindow, number: 5),
  GzGallerySection('role-badge', (c) => _roleBadge(c, data()), number: 6),
  GzGallerySection('group-chat', (c) => _groupChat(c, data()), number: 7),
  GzGallerySection('visit-card', (c) => _visitCard(c, data()), number: 8),
];

void _no() {}

const _hero = 'vch-GV-2611-K7QM';

// ------------------------------------------------------------------------------------------------------------ 1 voucher-card
Widget _voucherCard(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final hero = d.v(_hero);
  Widget full(String id, {bool actions = false}) => voucherCard(context, d.v(id), onCopy: actions ? _no : null, onShowFull: actions ? _no : null);
  Widget compact(VoucherSpecimen s) => voucherCard(context, s, variant: GzVoucherCardVariant.compact, onOpen: _no);
  return gcSection(
    context,
    title: t('Voucher card', 'بطاقة الكوبون'),
    note: t(
      'The KD 2 voucher as a ticket: ink hairline, a perforation, the QR drawn from the signed payload in ink tokens, the code as a left-to-right isolate in the figures voice, the venue or provider it is bound to, the bound quote (standard struck through, voucher price) and the state chip. No gold fill: a voucher is a fact.',
      'كوبون 2 د.ك كتذكرة: إطار حبري رفيع وخط تثقيب وQR مرسوم من الحمولة الموقّعة بألوان الحبر، والرمز معزول من اليسار إلى اليمين بصوت الأرقام، والمكان أو مقدّم الخدمة المرتبط به، والعرض المرتبط (السعر العادي مشطوب وسعر الكوبون) وشارة الحالة. بلا تعبئة ذهبية: الكوبون حقيقة.',
    ),
    specs: [
      gcSpec(context, t('Bound to the story request · copy and full screen', 'مرتبط بطلب القصة · نسخ وملء الشاشة'), [
        voucherCard(context, hero, onCopy: _no, onShowFull: _no),
        const SizedBox.shrink(), // the web caption is a lone space: an empty flex item that still takes its gap
      ]),
      gcSpec(context, t('Ready to use (released after a venue fault: reusable, or ask support for a credit voucher)', 'جاهز للاستخدام (أُفرج عنه بعد تقصير المكان: قابل لإعادة الاستخدام أو اطلبوا كوبون رصيد من الدعم)'), [
        full('vch-GV-2611-QD9X', actions: true),
      ]),
      gcSpec(context, t('A service provider voucher', 'كوبون خاص بمقدّم خدمة'), [full('vch-GV-2611-QY57', actions: true)]),
      gcSpec(context, t('Used · expired · not valid (24 h lapsed): the code stays, the QR is muted', 'مستخدم · منتهٍ · غير صالح (انتهت الـ 24 ساعة): يبقى الرمز ويخفت الـQR'), [
        full('vch-GV-2608-378X'),
        full('vch-GV-2608-D5QN'),
        full('vch-GV-2609-F6TM'),
      ]),
      gcSpec(context, t('Credit voucher · granted by support, unbound: any hall, hotel or service, 60 days', 'كوبون رصيد · منحه الدعم، غير مرتبط: أي قاعة أو فندق أو خدمة، لمدة 60 يومًا'), [
        full('vch-GV-2611-C4RD', actions: true),
        compact(d.v('vch-GV-2611-C4RD')),
      ]),
      gcSpec(context, t('Compact rows · the wallet list', 'صفوف مختصرة · قائمة المحفظة'), [
        for (final id in ['vch-GV-2611-K7QM', 'vch-GV-2611-QD9X', 'vch-GV-2611-M2WD', 'vch-GV-2608-378X', 'vch-GV-2609-F6TM', 'vch-GV-2610-H9XB']) compact(d.v(id)),
      ]),
      gcSpec(context, t('Voucher chip · bound · ready · quiet', 'شارة الكوبون · مرتبط · جاهز · هادئ'), [
        gcRow([
          GzVoucherChip(code: hero.voucher.code),
          GzVoucherChip(code: hero.voucher.code, tone: GzVoucherChipTone.ready),
          GzVoucherChip(code: hero.voucher.code, tone: GzVoucherChipTone.quiet),
        ]),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------------ 2 qr
Widget _qr(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final hero = d.v(_hero).voucher;
  final used = d.v('vch-GV-2608-378X').voucher;
  return gcSection(
    context,
    title: t('QR code', 'رمز QR'),
    note: t(
      'Generated from the voucher’s signed payload with qrcode-generator (MIT), drawn as one vector path in ink on the canvas token. Error correction M, a two-module quiet zone. The payload is never printed as text.',
      'يُولَّد من الحمولة الموقّعة للكوبون بمكتبة qrcode-generator (MIT) ويُرسم كمسار متجهي واحد بالحبر على لون الخلفية. تصحيح الخطأ M ومنطقة هادئة بعرض وحدتين. لا تُطبع الحمولة نصًّا أبدًا.',
    ),
    specs: [
      gcSpec(context, t('144 · 96 · muted (a used voucher)', '144 · 96 · خافت (كوبون مستخدم)'), [
        gcRow([
          for (final (v, muted) in [(hero, false), (hero, false), (used, true)])
            LayoutBuilder(builder: (context, box) => Align(alignment: AlignmentDirectional.centerStart, child: GzQrCode(payload: v.qr.payload, label: v.code, size: box.maxWidth, muted: muted))),
        ]),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 3 price-compare
Widget _priceCompare(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final q = (d.v(_hero).voucher as Voucher).quoteFils;
  Widget inline({bool guest = false, bool perPerson = true}) => GzPriceCompare(
    standard: perPerson ? 52000 : q.standard,
    voucher: perPerson ? 44000 : q.voucher,
    structure: perPerson ? PriceStructure.perPerson : PriceStructure.package,
    guests: perPerson ? 350 : null,
    variant: GzPriceCompareVariant.inline,
    audience: guest ? GzPriceCompareAudience.guest : GzPriceCompareAudience.member,
  );
  return gcSection(
    context,
    title: t('Price compare', 'مقارنة السعر'),
    note: t(
      'The two prices of one quote on the same basis. The voucher price is the headline in the figures voice; the standard price sits under it, quiet and struck through; then the saving, the net saving after the KD 2 voucher and the basis. A signed-out visitor sees the standard price and a locked voucher teaser with a sign-up action.',
      'السعران لعرض واحد بالأساس نفسه. سعر الكوبون هو العنوان بصوت الأرقام، والسعر العادي تحته هادئًا ومشطوبًا؛ ثم التوفير والتوفير الصافي بعد كوبون 2 د.ك والأساس. يرى الزائر غير المسجّل السعر العادي ولمحة مقفلة عن سعر الكوبون مع إجراء التسجيل.',
    ),
    specs: [
      gcSpec(context, t('Package · 350 guests · registered', 'باقة · 350 ضيفًا · مسجّل'), [
        GzPriceCompare(standard: q.standard, voucher: q.voucher, structure: PriceStructure.package, guests: 350),
      ]),
      gcSpec(context, t('Per person · hero size', 'للضيف · حجم العنوان'), [
        const GzPriceCompare(standard: 52000, voucher: 44000, structure: PriceStructure.perPerson, guests: 350, size: GzPriceCompareSize.display),
      ]),
      gcSpec(context, t('Guest (signed out): the voucher price is behind registration', 'زائر (غير مسجّل): سعر الكوبون خلف التسجيل'), [
        GzPriceCompare(standard: q.standard, voucher: q.voucher, structure: PriceStructure.package, guests: 350, audience: GzPriceCompareAudience.guest, onRegister: _no),
      ]),
      gcSpec(context, t('Inline for cards and rows · registered · guest', 'سطر واحد للبطاقات والصفوف · مسجّل · زائر'), [
        inline(),
        inline(perPerson: false),
        inline(guest: true),
      ]),
      gcSpec(context, t('No voucher price: the standard price alone, no strike, no voucher mention', 'لا سعر كوبون: السعر العادي وحده بلا شطب ولا إشارة للكوبون'), [
        GzPriceCompare(standard: q.standard, voucher: null, structure: PriceStructure.package, guests: 350),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 4 purchase-summary
Widget _purchaseSummary(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final s = d.v(_hero);
  final v = s.voucher as Voucher;
  final lang = context.gz.locale.languageCode;
  return gcSection(
    context,
    title: t('Voucher purchase summary', 'ملخص شراء الكوبون'),
    note: t(
      'What the KD 2 buys and what it does not: the bound quote, the two prices and the saving, the one amount paid to Ghazal today, the plain sentence that the rest is settled with the venue directly, and three rules in words. Never a deposit or a balance.',
      'ما يشتريه كوبون 2 د.ك وما لا يشتريه: العرض المرتبط والسعران والتوفير، والمبلغ الوحيد المدفوع لغزل اليوم، والجملة الواضحة بأن الباقي يُسدَّد للمكان مباشرة، وثلاث قواعد بالكلمات. لا عربون ولا متبقٍّ أبدًا.',
    ),
    specs: [
      gcSpec(context, t('The story quote · Aurelia Gulf Hotel', 'عرض القصة · فندق أوريليا الخليج'), [
        GzVoucherPurchaseSummary(
          targetName: s.target!.of(lang),
          packageName: t('Ladies’ Reception, Weekend', 'الحفل النسائي في نهاية الأسبوع'),
          eventDate: LocalDate.parse(v.eventDate.toString()),
          guests: 350,
          standardFils: v.quoteFils.standard,
          voucherFils: v.quoteFils.voucher,
        ),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 5 confirm-window
final DateTime _deadline = DateTime.parse('2026-11-13T16:00:00+03:00');

Widget _confirmWindow(BuildContext context) {
  String t(String en, String ar) => tr(context, en, ar);
  DateTime at(String iso) => DateTime.parse(iso);
  return gcSection(
    context,
    title: t('Confirm window (24 hours)', 'مهلة التأكيد (24 ساعة)'),
    note: t(
      'The owner’s fixed rule: the client confirms within 24 hours of approval. Calm by design: an absolute deadline sentence, the time left in hours and minutes (never seconds, never a ticking digit), a thread bar that only shows how much has passed and never turns red, and one reassurance line. Under an hour it says minutes; at the end it says the window closed and what happens to the voucher.',
      'قاعدة المالك الثابتة: يؤكد العميل خلال 24 ساعة من الموافقة. هادئة بالتصميم: جملة بموعد مطلق، والوقت المتبقي بالساعات والدقائق (لا ثوانٍ ولا رقم يتغير)، وشريط خيط لا يُظهر إلا ما مضى ولا يتحول إلى الأحمر، وسطر طمأنة واحد. قبل انتهاء الساعة الأخيرة يذكر الدقائق؛ وعند النهاية يقول إن المهلة انتهت وما يحدث للكوبون.',
    ),
    specs: [
      gcSpec(context, t('Open · 23 hours 40 minutes left · with the one primary action', 'مفتوحة · باقي 23 ساعة و40 دقيقة · مع الإجراء الأساسي الوحيد'), [
        GzConfirmWindow(deadline: _deadline, now: at('2026-11-12T16:20:00+03:00'), onConfirm: _no),
      ]),
      gcSpec(context, t('Half way · 11 hours 30 minutes left', 'في المنتصف · باقي 11 ساعة و30 دقيقة'), [
        GzConfirmWindow(deadline: _deadline, now: at('2026-11-13T04:30:00+03:00')),
      ]),
      gcSpec(context, t('The last hour · 45 minutes left (minutes only, no seconds)', 'الساعة الأخيرة · باقي 45 دقيقة (دقائق فقط بلا ثوانٍ)'), [
        GzConfirmWindow(deadline: _deadline, now: at('2026-11-13T15:15:00+03:00'), onConfirm: _no),
      ]),
      gcSpec(context, t('Lapsed · the voucher is no longer valid', 'انتهت المهلة · لم يعد الكوبون صالحًا'), [
        GzConfirmWindow(deadline: _deadline, now: at('2026-11-13T16:30:00+03:00')),
      ]),
      gcSpec(context, t('Confirmed', 'تم التأكيد'), [
        GzConfirmWindow(deadline: _deadline, confirmedAt: at('2026-11-12T18:05:00+03:00'), now: at('2026-11-12T18:10:00+03:00')),
      ]),
      gcSpec(context, t('On an ink panel · open', 'على لوحة داكنة · مفتوحة'), [
        GzConfirmWindow(deadline: _deadline, now: at('2026-11-12T16:20:00+03:00'), onDark: true),
        Align(alignment: AlignmentDirectional.centerStart, child: GzButton(label: t('Cancel request', 'إلغاء الطلب'), variant: GzButtonVariant.tertiary, onDark: true, onPressed: _no)),
      ], ink: true),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 6 role-badge
Widget _roleBadge(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final members = d.clientThread.thread.members!;
  return gcSection(
    context,
    title: t('Role badges and members', 'شارات الأدوار والأعضاء'),
    note: t(
      'Exactly three roles in every visit group chat: Client, Hotel representative, Ghazal support. A text chip, never a glyph that could pass for a face; monogram avatars only. The roles differ by tone and by words, never by colour alone.',
      'ثلاثة أدوار فقط في كل محادثة زيارة جماعية: العميل وممثل الفندق ودعم غزل. شارة نصية بلا رمز قد يُظن وجهًا، وصور رمزية بالحرف الأول فقط. تختلف الأدوار بالنبرة والكلمات لا باللون وحده.',
    ),
    specs: [
      gcSpec(context, t('Badges · client · hotel representative · support · “You”', 'الشارات · العميل · ممثل الفندق · الدعم · «أنتم»'), [
        gcRow([
          const GzRoleBadge(role: ThreadRole.client),
          const GzRoleBadge(role: ThreadRole.hotelRepresentative),
          const GzRoleBadge(role: ThreadRole.support),
          const GzRoleBadge(role: ThreadRole.client, you: true),
        ]),
      ]),
      gcSpec(context, t('Participant strip · the header of the group chat (opens the member sheet)', 'شريط المشاركين · رأس المحادثة الجماعية (يفتح ورقة الأعضاء)'), [
        GzParticipantStrip(members: members, meId: 'user-reem', onOpen: _no),
      ]),
      gcSpec(context, t('Member sheet form · with the organisation under the representative', 'شكل ورقة الأعضاء · مع اسم الجهة تحت الممثل'), [
        GzParticipantStrip(members: members, meId: 'user-reem', showOrganisation: true),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 7 group-chat
Widget _groupChat(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final ar = context.gz.isAr;
  final members = d.clientThread.thread.members!;
  ThreadRole? roleOf(Message m) => switch (m.from) {
    MessageFrom.client => ThreadRole.client,
    MessageFrom.venue => ThreadRole.hotelRepresentative,
    MessageFrom.support => ThreadRole.support,
    _ => null,
  };
  String nameOf(ThreadRole r) {
    final m = members.firstWhere((x) => x.role == r);
    return ar ? m.name : m.nameLatin;
  }

  List<Widget> run(List<Message> all, GzChatSide side) {
    final msgs = all.take(6).toList();
    return [
      for (var i = 0; i < msgs.length; i++)
        () {
          final m = msgs[i];
          final role = roleOf(m);
          final first = i == 0 || msgs[i - 1].from != m.from;
          final own = side == GzChatSide.client ? m.from == MessageFrom.client : m.from == MessageFrom.venue;
          return Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : GzSpace.s3),
            child: GzChatBubble(
              message: m,
              side: side,
              group: m.kind == MessageKind.system,
              sender: role != null && first ? GzChatSender(name: nameOf(role), role: role, you: own) : null,
              showMeta: i + 1 >= msgs.length || msgs[i + 1].from != m.from,
            ),
          );
        }(),
    ];
  }

  return gcSection(
    context,
    title: t('Group chat', 'المحادثة الجماعية'),
    note: t(
      'The shared ChatBubble with two additions for the three-way chat: a sender line above the first bubble of a run (name, then the role badge) and a quiet glyph on system lines (opened, confirmed, arrived, read-only). Own messages sit at inline-end in ink; a visit card shows the appointment.',
      'ChatBubble المشترك مع إضافتين للمحادثة الثلاثية: سطر المرسل فوق أول فقاعة في كل سلسلة (الاسم ثم شارة الدور) ورمز هادئ على أسطر النظام (فتح المحادثة والتأكيد والوصول وللقراءة فقط). رسائل المستخدم عند نهاية السطر بالحبر؛ وبطاقة الزيارة تعرض الموعد.',
    ),
    specs: [
      gcSpec(context, t('The client’s phone', 'هاتف العميل'), [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzChatDateDivider(date: d.clientThread.messages.first.at.toIso8601String()),
            const SizedBox(height: GzSpace.s3),
            ...run(d.clientThread.messages, GzChatSide.client),
          ],
        ),
      ]),
      gcSpec(context, t('The hotel representative’s phone (same chat, own messages flip sides)', 'هاتف ممثل الفندق (المحادثة نفسها وتنقلب رسائله)'), [
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: run(d.hotelThread.messages, GzChatSide.hotel)),
      ]),
    ],
  );
}

// ------------------------------------------------------------------------------------------------------------ 8 visit-card
Widget _visitCard(BuildContext context, VoucherAData d) {
  String t(String en, String ar) => tr(context, en, ar);
  final lang = context.gz.locale.languageCode;
  Widget card(String id, {GzVisitAudience audience = GzVisitAudience.client, bool open = false}) {
    final s = d.visit(id);
    final rep = s.representative;
    return GzVisitCard(
      visit: s.visit,
      audience: audience,
      venueName: s.venue.of(lang),
      representativeName: rep == null ? null : (lang == 'ar' ? rep.name : rep.nameLatin),
      onOpenChat: _no,
      onOpen: open ? _no : null,
    );
  }

  return gcSection(
    context,
    title: t('Visit card', 'بطاقة الزيارة'),
    note: t(
      'One site visit: status pill, the date and the 30-minute arrival window in the figures voice, who it is with, the party size and one action into the group chat. The client sees the venue; the partner sees the client. A visit is free and independent of the voucher.',
      'زيارة واحدة للقاعة: شارة الحالة والتاريخ ونافذة الوصول (30 دقيقة) بصوت الأرقام، ومع من هي وعدد الزائرين وإجراء واحد إلى المحادثة الجماعية. يرى العميل المكان ويرى الشريك العميل. الزيارة مجانية ومستقلة عن الكوبون.',
    ),
    specs: [
      gcSpec(context, t('Client · confirmed · open the group chat', 'العميل · مؤكدة · فتح المحادثة الجماعية'), [card('visit-aurelia-reem', open: true)]),
      gcSpec(context, t('Client · completed (chat read-only)', 'العميل · مكتملة (المحادثة للقراءة فقط)'), [card('visit-lumi-reem')]),
      gcSpec(context, t('Partner · requested', 'الشريك · طلب زيارة'), [card('visit-aurelia-rashed', audience: GzVisitAudience.hotel, open: true)]),
    ],
  );
}
