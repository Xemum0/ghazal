// Client gallery, part C (agent C3): the Flutter twin of sections 13 to 19 of design/src/gallery/client.tsx (planner-tier, service-tile,
// vendor-card, chat, conversation-row, checklist, budget). Same specimens, states and sample text as the web gallery files
// ServiceSections.tsx, ChatSections.tsx and PlanSections.tsx; every object comes from the mock through the real repositories.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/src/client/client_c.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import '../world.dart';
import 'gz_gallery.dart';

/// The mock data of the sections, loaded once with real async (outside `testWidgets`).
class ClientCData {
  ClientCData._(this.packages, this.categories, this.vendors, this.areas, this.messages, this.conversations, this.pendingItems, this.confirmedItems, this.pendingBudget, this.confirmedBudget);

  final List<PlannerPackage> packages;
  final List<ServiceCategory> categories;
  final List<ServiceProvider> vendors;
  final Map<String, Area> areas;
  final Map<String, Message> messages;
  final List<Conversation> conversations;
  final List<ChecklistItem> pendingItems;
  final List<ChecklistItem> confirmedItems;
  final Budget pendingBudget;
  final Budget confirmedBudget;

  Message msg(String id) => messages[id] ?? (throw StateError('message $id not visible to reem (have ${messages.keys.toList()..sort()})'));

  static Future<ClientCData> load(GzWorld world) async {
    final reem = world.repos('reem');
    final packages = await reem.planners.listPlannerPackages();
    final cats = await reem.services.listServiceCategories();
    final categories = [...cats.primary, ...cats.secondary]..sort((a, b) => a.order.compareTo(b.order));
    final vendors = <ServiceProvider>[];
    String? cursor;
    do {
      final page = await reem.services.listServiceProviders(cursor: cursor, limit: 50);
      vendors.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    for (final id in const ['vendor-catering-qahwat-diwan', 'vendor-catering-bayt-karam', 'vendor-decor-masrah']) {
      if (vendors.any((v) => v.id == id)) continue;
      // Not listed to a client (an unpublished fixture vendor): take the fixture row itself, as the web gallery does.
      final rows = jsonDecode(File('../ghazal_mock_api/assets/seed/ServiceProvider.seed.json').readAsStringSync()) as List<dynamic>;
      vendors.add(ServiceProvider.fromJson((rows.firstWhere((r) => (r as Map)['id'] == id) as Map).cast<String, Object?>()));
    }
    final areas = {for (final a in (await reem.venues.listAreas()).areas) a.id: a};
    final convs = <Conversation>[];
    cursor = null;
    do {
      final page = await reem.chat.listConversations(cursor: cursor, limit: 50);
      convs.addAll(page.items);
      cursor = page.nextCursor;
    } while (cursor != null);
    final messages = <String, Message>{};
    for (final c in convs) {
      String? mcur;
      do {
        final mc = await reem.chat.listMessages(conversationId: c.id, cursor: mcur, limit: 50);
        for (final m in mc.items) {
          messages[m.id] = m;
        }
        mcur = mc.nextCursor;
      } while (mcur != null);
    }
    // The hotel-side drafts (msg-003, msg-004) are never visible to the couple: read them as the venue's own staff.
    final aurelia = convs.firstWhere((c) => c.id == 'conv-aurelia-reem');
    final staff = world.repos('hotel_manager', venueId: aurelia.venueId);
    String? scur;
    do {
      final page = await staff.chat.listMessages(conversationId: aurelia.id, cursor: scur, limit: 50);
      for (final m in page.items) {
        messages.putIfAbsent(m.id, () => m);
      }
      scur = page.nextCursor;
    } while (scur != null);
    final pendingChecklist = await reem.wedding.getChecklist();
    final pendingBudget = await reem.wedding.getBudget();
    world.control.jumpToStory('confirmed');
    final confirmedChecklist = await reem.wedding.getChecklist();
    final confirmedBudget = await reem.wedding.getBudget();
    world.control.jumpToStory('pending');
    return ClientCData._(packages, categories, vendors, areas, messages, convs, pendingChecklist.items, confirmedChecklist.items, pendingBudget.budget, confirmedBudget.budget);
  }
}

// ---------------------------------------------------------------------------------------------------------------- kit
String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

/// `Section` of the web client kit: khayt, d2 title, note (gap 8), then the specimens (gap 32) after a gap of 20.
Widget _sec(BuildContext context, {required String title, required String note, required List<Widget> specs}) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
      const SizedBox(height: GzSpace.s2),
      GzText(title, role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(note, role: GzTextRole.bodyS, color: c.textSecondary),
      const SizedBox(height: GzSpace.s5),
      for (var i = 0; i < specs.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s8), specs[i]],
    ],
  );
}

/// `Spec`: a state caption over a hairline (gap 12), then the live components with a gap of 24.
Widget _spec(BuildContext context, String state, List<Widget> children) {
  final gz = context.gz;
  final c = gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsets.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Text(state, style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
      ),
      const SizedBox(height: GzSpace.s3),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
}

/// `Row`: side-by-side cells of equal width, gap 12.
Widget _row(List<Widget> cells) => Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [for (var i = 0; i < cells.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), Expanded(child: cells[i])]],
);

Widget _list(List<Widget> children) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);

Message _variant(Message base, Map<String, Object?> over) => Message.fromJson({...base.toJson(), ...over});

/// A tiny stateful holder so the specimens that are interactive on the web (pick a tier, tick a task, play a voice note) are too.
class _State<T> extends StatefulWidget {
  const _State({required this.initial, required this.builder});

  final T initial;
  final Widget Function(BuildContext context, T value, void Function(T) set) builder;

  @override
  State<_State<T>> createState() => _StateState<T>();
}

class _StateState<T> extends State<_State<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(context, _value, (v) => setState(() => _value = v));
}

// ------------------------------------------------------------------------------------------------------------ sections
/// The web section ids and their place on the client gallery page (the `NN` of `NN-<id>.<lang>.png`).
const Map<String, int> clientCSectionNumbers = {
  'planner-tier': 13,
  'service-tile': 14,
  'vendor-card': 15,
  'chat': 16,
  'conversation-row': 17,
  'checklist': 18,
  'budget': 19,
};

List<GzGallerySection> clientCGallerySections(ClientCData Function() data) {
  final builders = <String, WidgetBuilder>{
    'planner-tier': (c) => _planner(c, data()),
    'service-tile': (c) => _serviceTile(c, data()),
    'vendor-card': (c) => _vendor(c, data()),
    'chat': (c) => _chat(c, data()),
    'conversation-row': (c) => _conversation(c, data()),
    'checklist': (c) => _checklist(c, data()),
    'budget': (c) => _budget(c, data()),
  };
  return [for (final e in builders.entries) GzGallerySection(e.key, e.value, number: clientCSectionNumbers[e.key])];
}

Widget _planner(BuildContext context, ClientCData d) => _sec(
  context,
  title: _t(context, 'Planner tiers', 'باقات المخطط'),
  note: _t(
    context,
    'Silver, Gold and Royal are planner packages only. One, two and three gold beads mark the tier; there is no metallic colour. The 25% deposit is a proposal, arranged after the consultation.',
    'الفضية والذهبية والملكية لباقات المخطط فقط. تُرمز خرزة ذهبية واحدة أو اثنتان أو ثلاث إلى الباقة؛ ولا ألوان معدنية. العربون 25% مقترح يُتفق عليه بعد الاستشارة.',
  ),
  specs: [
    _spec(context, _t(context, 'Choose a tier · selected is an ink border', 'اختيار الباقة · المحددة بإطار حبري'), [
      _State<String>(
        initial: 'planner-gold',
        builder: (context, pick, set) => _list([
          for (var i = 0; i < d.packages.length; i++) ...[
            if (i > 0) const SizedBox(height: GzSpace.s6),
            GzPlannerTierCard(pkg: d.packages[i], selected: pick == d.packages[i].id, onSelect: () => set(d.packages[i].id), onRequest: pick == d.packages[i].id ? () {} : null),
          ],
        ]),
      ),
    ]),
    _spec(context, _t(context, 'Loading', 'التحميل'), [GzPlannerTierCard(pkg: d.packages.first, loading: true)]),
  ],
);

Widget _serviceTile(BuildContext context, ClientCData d) {
  final rows = <Widget>[];
  for (var i = 0; i < d.categories.length; i += 2) {
    final pair = d.categories.skip(i).take(2).toList();
    rows.add(_row([for (final c in pair) GzServiceTile(category: c, onOpen: () {})]));
  }
  return _sec(
    context,
    title: _t(context, 'Service tiles', 'بلاطات الخدمات'),
    note: _t(
      context,
      'The 16 service categories as photograph tiles with a wall label: the name, then the price anchor with its unit. Two across.',
      'فئات الخدمات الست عشرة كبلاطات صور بلوحة تعريفية: الاسم ثم السعر التقريبي بوحدته. اثنتان في الصف.',
    ),
    specs: [
      _spec(context, _t(context, 'All 16 categories', 'الفئات الست عشرة كلها'), rows),
      _spec(context, _t(context, 'Pressed · loading', 'الضغط · التحميل'), [
        _row([GzServiceTile(category: d.categories.first, previewState: GzPreviewState.pressed), GzServiceTile(category: d.categories.first, loading: true)]),
      ]),
    ],
  );
}

Widget _vendor(BuildContext context, ClientCData d) {
  // The web gallery's picks, in the fixtures' own order: the first rated + verified + female-team vendor, the first without a rating,
  // the longest Arabic name. (The API lists vendors in its own sort order, so the three are named by id.)
  ServiceProvider byId(String id) => d.vendors.firstWhere((v) => v.id == id);
  final rated = byId('vendor-catering-qahwat-diwan');
  final fresh = byId('vendor-catering-bayt-karam');
  final long = byId('vendor-decor-masrah');
  Area? area(ServiceProvider v) => d.areas[v.areaId];
  return _sec(
    context,
    title: _t(context, 'Vendor card', 'بطاقة المورّد'),
    note: _t(
      context,
      'A supplier: portfolio strip, monogram, name, rating or "New", area, the from price with its unit, plain facts and the verified mark. The row form is for lists and the saved tab.',
      'مورّد: شريط أعمال وحرف أول والاسم والتقييم أو «جديد» والمنطقة والسعر ابتداءً من بوحدته وحقائق واضحة وعلامة التوثيق. الصيغة المختصرة للقوائم وتبويب المفضلة.',
    ),
    specs: [
      _spec(context, _t(context, 'Verified · rated · female team · save heart', 'موثّق · مقيَّم · فريق نسائي · قلب الحفظ'), [
        _State<bool>(initial: false, builder: (context, fav, set) => GzVendorCard(vendor: rated, area: area(rated), favourite: fav, onFavouriteChange: set, onOpen: () {})),
      ]),
      _spec(context, _t(context, 'New vendor (no rating) · longest name', 'مورّد جديد (بلا تقييم) · أطول اسم'), [
        GzVendorCard(vendor: fresh, area: area(fresh), onOpen: () {}),
        GzVendorCard(vendor: long, area: area(long), onOpen: () {}),
      ]),
      _spec(context, _t(context, 'Row · pressed · loading', 'صف مختصر · الضغط · التحميل'), [
        GzVendorCard(vendor: rated, area: area(rated), variant: GzVendorVariant.row, onOpen: () {}),
        GzVendorCard(vendor: fresh, area: area(fresh), variant: GzVendorVariant.row, previewState: GzPreviewState.pressed),
        GzVendorCard(vendor: rated, area: area(rated), loading: true),
      ]),
    ],
  );
}

Widget _chat(BuildContext context, ClientCData d) {
  final own = _variant(d.msg('msg-006'), {
    'text': {'en': 'Hello Nouf, we need help designing the kosha.', 'ar': 'أهلًا نوف، نحتاج مساعدة في تصميم الكوشة.'},
    'origin': 'ar',
  });
  final english = _variant(own, {
    'id': 'msg-en',
    'origin': 'en',
    'from': 'planner',
    'text': {'en': 'Happy to help. Send me any photos you like, in English or Arabic.', 'ar': 'يسعدني ذلك.'},
  });
  final system = _variant(own, {
    'id': 'msg-sys',
    'kind': 'system',
    'from': 'system',
    'text': {'en': 'Handled by Hind Al-Enezi', 'ar': 'يتابع معكم هند العنزي'},
    'origin': 'en',
  });
  final long = _variant(own, {
    'id': 'msg-long',
    'from': 'venue',
    'origin': 'ar',
    'text': {
      'en': '',
      'ar': 'وعليكم السلام ورحمة الله، هلا فيكم. نعم الخميس 14 يناير متاح للحفل النسائي في قاعة الدانة، ويمكننا تثبيت التاريخ لكم لمدة 24 ساعة بعد الموافقة. أرسلوا لنا عدد الضيوف التقريبي وسنجهز لكم عرض السعر.',
    },
  });
  return _sec(
    context,
    title: _t(context, 'Chat', 'المحادثة'),
    note: _t(
      context,
      'Text is shown as typed, in its own language and direction; labels are never dialect. Own messages sit at inline-end in ink, received on ink-50; the tail corner is 4. Voice shows a waveform and the duration; documents show the file name as an LTR isolate.',
      'يُعرض النص كما كُتب بلغته واتجاهه؛ ولا تكون العناوين بلهجة محلية. رسائلكم عند نهاية السطر بالحبر والمستلمة على رمادي فاتح؛ وزاوية الذيل 4. الصوت يعرض موجة ومدة، والمستندات تعرض اسم الملف بعزل من اليسار إلى اليمين.',
    ),
    specs: [
      _spec(context, _t(context, 'Text · own and received · an English message in an Arabic thread · long text', 'نص · مرسل ومستلم · رسالة إنجليزية في محادثة عربية · نص طويل'), [
        const GzChatDateDivider(date: '2026-11-12'),
        GzChatBubble(message: d.msg('msg-005')),
        GzChatBubble(message: own),
        GzChatBubble(message: english),
        GzChatBubble(message: long),
        GzChatBubble(message: system),
      ]),
      _spec(context, _t(context, 'Voice · idle and playing (progress shown)', 'صوت · متوقف ويعمل (مع التقدم)'), [
        GzChatBubble(message: d.msg('msg-003'), side: GzChatSide.hotel),
        _State<bool>(
          initial: false,
          builder: (context, playing, set) => GzChatBubble(message: d.msg('msg-019'), playing: playing, progress: playing ? 0.4 : 0, onPlay: () => set(!playing)),
        ),
      ]),
      _spec(context, _t(context, 'Image · document · draft (hotel side, never visible to the couple)', 'صورة · مستند · مسودة (جهة المكان، لا تظهر للعروسين)'), [
        GzChatBubble(message: d.msg('msg-018')),
        GzChatBubble(message: d.msg('msg-011')),
        GzChatBubble(message: d.msg('msg-004'), side: GzChatSide.hotel),
      ]),
      _spec(context, _t(context, 'Structured cards · meeting, quote request', 'بطاقات منظمة · اجتماع وطلب عرض سعر'), [
        GzChatBubble(message: d.msg('msg-007')),
        GzChatBubble(message: d.msg('msg-009'), side: GzChatSide.client),
      ]),
    ],
  );
}

Widget _conversation(BuildContext context, ClientCData d) {
  const ids = ['conv-aurelia-reem', 'conv-planner-nouf', 'conv-vendor-lamha', 'conv-jawharat-reem', 'conv-support-reem', 'conv-lumi-reem'];
  return _sec(
    context,
    title: _t(context, 'Conversation row', 'صف المحادثة'),
    note: _t(
      context,
      'Monogram, name, one line of preview, the time and the gold unread count. An unread preview is strong; a pinned thread without unread shows the pin.',
      'حرف أول واسم وسطر معاينة واحد والوقت وعدّاد ذهبي لغير المقروء. معاينة غير المقروء بخط أوضح؛ والمحادثة المثبتة بلا رسائل جديدة تعرض الدبوس.',
    ),
    specs: [
      _spec(context, _t(context, 'The Messages list (Reem’s six threads)', 'قائمة الرسائل (محادثات ريم الست)'), [
        _list([
          for (final id in ids)
            () {
              final c = d.conversations.firstWhere((x) => x.id == id);
              final mine = d.messages.values.where((m) => m.conversationId == id && !m.draft).toList()..sort((a, b) => a.seq.compareTo(b.seq));
              return GzConversationRow(conversation: c, last: mine.isEmpty ? null : mine.last, onOpen: () {});
            }(),
        ]),
      ]),
    ],
  );
}

Widget _checklist(BuildContext context, ClientCData d) {
  String? catName(ChecklistItem it) {
    final id = it.serviceCategoryId;
    if (id == null) return null;
    for (final c in d.categories) {
      if (c.id == id) return c.name.of(context.gz.locale.languageCode);
    }
    return null;
  }

  return _sec(
    context,
    title: _t(context, 'Checklist', 'قائمة المهام'),
    note: _t(
      context,
      'A 64 row with a 24 box in a 44 target. Done is quiet ink, never struck through; overdue is said in words with a glyph; the Venue task completes itself at confirmation and shows a lock. The progress line is gold because it is state.',
      'صف بارتفاع 64 ومربع 24 داخل هدف لمس 44. المنجز بحبر هادئ دون شطب؛ والمتأخر يُقال بالكلمات مع رمز؛ ومهمة القاعة تكتمل تلقائيًا عند التأكيد وتعرض قفلًا. خط التقدم ذهبي لأنه حالة.',
    ),
    specs: [
      _spec(context, _t(context, 'Interactive · tick a task, open its category', 'تفاعلي · علّموا مهمة وافتحوا فئتها'), [
        _State<Set<String>>(
          initial: {for (final i in d.pendingItems.where((i) => i.done)) i.id},
          builder: (context, done, set) {
            final items = [for (final i in d.pendingItems) _tick(i, done.contains(i.id))];
            return _list([
              GzChecklistProgress(done: done.length, total: items.length),
              const SizedBox(height: GzSpace.s6),
              for (var i = 0; i < items.length; i++)
                GzChecklistItem(
                  item: items[i],
                  today: LocalDate.parse('2026-11-16'),
                  last: i == items.length - 1,
                  onToggle: (v) => set(v ? {...done, items[i].id} : ({...done}..remove(items[i].id))),
                  onChoose: () {},
                  actionLabel: catName(items[i]),
                ),
            ]);
          },
        ),
      ]),
      _spec(context, _t(context, 'After confirmation: the Venue task is done by the system (11%)', 'بعد التأكيد: أنجز النظام مهمة القاعة (11%)'), [
        GzChecklistProgress(done: d.confirmedItems.where((i) => i.done).length, total: d.confirmedItems.length),
        _list([for (var i = 0; i < 2; i++) GzChecklistItem(item: d.confirmedItems[i], last: i == 1)]),
      ]),
    ],
  );
}

ChecklistItem _tick(ChecklistItem i, bool done) => done == i.done
    ? i
    : ChecklistItem.fromJson({...i.toJson(), 'done': done, 'doneAt': done ? '2026-11-12T16:00:00+03:00' : null});

Widget _budget(BuildContext context, ClientCData d) {
  final conf = d.confirmedBudget;
  Map<String, Object?> cat(BudgetCategory c, {int? paid, int? committed}) => {
    ...c.toJson(),
    'paid': paid == null ? c.paid.toJson() : {'fils': paid, 'currency': 'KWD'},
    'committed': committed == null ? c.committed.toJson() : {'fils': committed, 'currency': 'KWD'},
  };
  Budget with_(Budget b, {MoneyAmount? total, List<Map<String, Object?>>? categories}) =>
      Budget.fromJson({...b.toJson(), 'total': (total ?? b.total).toJson(), 'categories': categories ?? [for (final c in b.categories) c.toJson()]});
  final over = with_(conf, categories: [for (final c in conf.categories) c.id == BudgetCategoryId.flowersDecor ? cat(c, paid: 4920000, committed: 1600000) : c.toJson()]);
  final empty = with_(d.pendingBudget, categories: [for (final c in d.pendingBudget.categories.take(2)) c.toJson()]);
  final stress = with_(conf, total: const MoneyAmount(6000000));
  return _sec(
    context,
    title: _t(context, 'Budget summary', 'ملخص الميزانية'),
    note: _t(
      context,
      'The total, a stacked bar (paid in ink, committed in gold, the rest on the track), the three meanings in words, and category rows with their own bars. An alert appears only when a category or the whole budget goes over, and says so in words.',
      'الإجمالي وشريط مكدّس (المدفوع بالحبر والملتزم به بالذهبي والباقي على المسار) والمعاني الثلاثة بالكلمات وصفوف الفئات بأشرطتها. لا يظهر التنبيه إلا عند تجاوز فئة أو الميزانية كلها ويُذكر بالكلمات.',
    ),
    specs: [
      _spec(context, _t(context, 'Confirmed booking: voucher paid, the venue price committed', 'حجز مؤكد: الكوبون مدفوع وسعر المكان ملتزم به'), [GzBudgetSummary(budget: conf)]),
      _spec(context, _t(context, 'Nothing spent yet', 'لم يُصرف شيء بعد'), [GzBudgetSummary(budget: empty)]),
      _spec(context, _t(context, 'A category over its share: the alert, in words', 'فئة تجاوزت حصتها: التنبيه بالكلمات'), [GzBudgetSummary(budget: over)]),
      _spec(context, _t(context, 'Stress: a very large committed amount', 'ضغط: مبلغ ملتزم به كبير جدًا'), [GzBudgetSummary(budget: stress)]),
    ],
  );
}
