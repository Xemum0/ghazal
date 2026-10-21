// The nav gallery: the Flutter twin of design/src/system/nav/demo/NavGallery.tsx (#/gallery/nav). Five sections in the web order and
// with the web section ids as titles (proto, bars, overlays, media, frames), the same specimens, sizes and copy. Parity:
// `node tools/parity/parity.mjs --gallery nav` after `flutter test test/gallery/nav_gallery_test.dart`.
//
// Not comparable pixel for pixel: `proto` (the web prototype player renders the product screens in a bezel; here it is a navigator
// demo) and the four `StaticFrame` specimens of `frames` (they render product screens from the inventory: out of this group).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import 'gz_gallery.dart';
import 'nav_demo.dart';
import 'nav_extras_gallery.dart';
import 'nav_gallery_kit.dart';

const List<String> navGalleryTitles = ['proto', 'bars', 'overlays', 'media', 'frames'];

/// The sections of the nav gallery page (column of 310 dp, like the web reference crops).
List<GzGallerySection> navGallerySections() {
  final builders = <WidgetBuilder>[_proto, _bars, _overlays, _media, _frames];
  return [for (var i = 0; i < builders.length; i++) GzGallerySection(navGalleryTitles[i], builders[i], width: 310), ...navExtrasGallerySections()];
}

// ------------------------------------------------------------------------------------------------------------------ copy
class _Copy {
  const _Copy(this.ar);

  final bool ar;
  String _p(String en, String arabic) => ar ? arabic : en;

  String sectionTitle(String id) => switch (id) {
        'proto' => _p('Live prototype', 'النموذج الحي'),
        'bars' => _p('Bars', 'الأشرطة'),
        'overlays' => _p('Overlays and states', 'الطبقات والحالات'),
        'media' => _p('Pager, carousel, gallery, accordion', 'المنزلق والصور والأكورديون'),
        _ => _p('Device chrome', 'واجهة الجهاز'),
      };
  String get live => _p('Live frame · client', 'إطار حي · client');
  String get protoNote => _p(
        'Tap a hall, open the date sheet, request a date. Tabs keep their own stack; re-tap a tab to return to its root.',
        'اختاروا قاعة، افتحوا ورقة التاريخ، ثم أرسلوا الطلب. لكل تبويب مساره الخاص، والضغط على التبويب الحالي يعيدكم إلى جذره.',
      );
  String get protoRoute => '#/play?app=client|hotel&story=start|client|hotel';
  String get tabClient => _p('TabBar, client (My Wedding dot, Messages count)', 'شريط التبويب، العميل (نقطة زفافكم وعدد الرسائل)');
  String get tabHotel => _p('TabBar, hotel (Bookings count, danger tint with text)', 'شريط التبويب، الفندق (عدد الحجوزات بلون التنبيه مع نص)');
  String get tabPressed => _p('TabBar, pressed', 'شريط التبويب، حالة الضغط');
  String get topStandard => _p('TopBar, standard with actions', 'الشريط العلوي، عادي مع إجراءات');
  String get topLarge => _p('TopBar, large title (scrolled: collapsed)', 'الشريط العلوي، عنوان كبير (بعد التمرير: مطوي)');
  String get topTransparent => _p('TopBar, transparent over a photograph', 'الشريط العلوي، شفاف فوق صورة');
  String get topSolid => _p('TopBar, transparent after the hero (solid)', 'الشريط العلوي، شفاف بعد الصورة (مصمت)');
  String get topSearch => _p('TopBar, with search', 'الشريط العلوي، مع بحث');
  String get action => _p('ActionBar, price + primary + note', 'شريط الإجراء، السعر والزر الرئيسي وملاحظة');
  String get actionHotel => _p('ActionBar, hotel save bar (tab bar below)', 'شريط الإجراء، حفظ للفندق (فوق شريط التبويب)');
  String get sheet => _p('Sheet', 'الورقة');
  String get dialog => _p('Dialog', 'النافذة');
  String get dialogDestructive => _p('Dialog, destructive', 'النافذة، إجراء لا رجعة فيه');
  String get banners => _p('Banner: offline, info, warning', 'اللافتة: غير متصل، معلومة، تنبيه');
  String get empty => _p('EmptyState', 'حالة فارغة');
  String get error => _p('ErrorState', 'حالة خطأ');
  String get pull => _p('PullIndicator: pulling, released', 'مؤشر السحب: أثناء السحب وبعد الإفلات');
  String get pager => _p('Pager, peek (item width = frame - 2 x gutter - peek)', 'المنزلق مع إطلالة (عرض العنصر = الإطار - 2 × الهامش - الإطلالة)');
  String get hero => _p('ImageCarousel, hero', 'عرض الصور، رئيسي');
  String get tour => _p('ImageCarousel, tour 16:10', 'عرض الصور، جولة 16:10');
  String get viewer => _p('FullscreenGallery (tap a hero photograph)', 'عارض الصور بملء الشاشة (اضغطوا على صورة رئيسية)');
  String get accordion => _p('Accordion', 'الأكورديون');
  String get statusDark => _p('Status chrome, dark content', 'واجهة النظام، محتوى داكن');
  String get statusLight => _p('Status chrome, light content over imagery', 'واجهة النظام، محتوى فاتح فوق صورة');
  String get chromeNone => _p('Chrome none', 'بلا واجهة');
  String get bezel => _p('Thin bezel (player)', 'إطار رفيع (للمشغّل)');
  String get standardTitle => _p('Aurelia Gulf Hotel', 'فندق أوريليا الخليج');
  String get subtitle => _p('Sharq', 'شرق');
  String get largeTitle => _p('Saved', 'المفضلة');
  String get venueFacts => _p('Danah Ballroom seats up to 650. Ladies reception, evening session.', 'قاعة دانة تتسع حتى 650. حفل نسائي، الفترة المسائية.');
  String get discover => _p('Discover', 'استكشف');
  String get searchPlaceholder => _p('Search halls and hotels', 'ابحثوا عن قاعة أو فندق');
  String get briefBudget => _p('Budget', 'الميزانية');
  String get totalFor => _p('Total for 350 guests', 'الإجمالي لعدد 350 مدعوًا');
  String get requestThisDate => _p('Request this date', 'اطلبوا هذا التاريخ');
  String get noPayment => _p('No payment now. Nothing is charged until the hotel approves.', 'لا دفع الآن. لن يُخصم شيء حتى يوافق الفندق.');
  String get briefDone => _p('Done', 'تم');
  String get confirmCancel => _p('Not yet', 'ليس بعد');
  String get sheetTitle => _p('Your date', 'تاريخكم');
  String get briefDate => _p('Date', 'التاريخ');
  String get briefRow => _p('Thursday 14 January 2027', 'الخميس 14 يناير 2027');
  String get briefGuests => _p('Guests', 'عدد الضيوف');
  String get guestsValue => _p('350 guests', '350 ضيفًا');
  String get briefArea => _p('Area', 'المنطقة');
  String get areaValue => _p('Salmiya or Sharq', 'السالمية أو شرق');
  String get budgetValue => _p('KD 20,000 to 35,000', '20,000 إلى 35,000 د.ك');
  String get confirmTitle => _p('Send this request?', 'إرسال هذا الطلب؟');
  String get confirmBody => _p('The hotel replies within 24 hours. You pay nothing now.', 'يرد الفندق خلال 24 ساعة. لا شيء يُدفع الآن.');
  String get confirmCta => _p('Send request', 'إرسال الطلب');
  String get dTitle => _p('Cancel this request?', 'إلغاء هذا الطلب؟');
  String get dBody => _p('The hotel will be told. You have not paid anything, so nothing is refunded.', 'سيُبلَّغ الفندق. لم تدفعوا شيئًا، فلا مبلغ يُسترد.');
  String get dConfirm => _p('Cancel request', 'إلغاء الطلب');
  String get bOffline => _p('You are offline. Showing what was last loaded.', 'لا يوجد اتصال. نعرض آخر ما تم تحميله.');
  String get bInfo => _p('Prices include service charge.', 'الأسعار تشمل رسوم الخدمة.');
  String get bWarning => _p('This date is on hold for another couple.', 'هذا التاريخ محجوز مؤقتًا لحجز آخر.');
  String get bRetry => _p('Try again', 'إعادة المحاولة');
  String get emptyTitle => _p('No saved halls yet', 'لا قاعات محفوظة بعد');
  String get emptyBody => _p('Tap the heart on a hall and it waits here for you.', 'اضغطوا على القلب في أي قاعة لتنتظركم هنا.');
  String get emptyAction => _p('Browse halls', 'تصفح القاعات');
  String get galleryLabel => _p('Photos of Aurelia Gulf Hotel', 'صور فندق أوريليا الخليج');
  List<(String, String)> get faq => ar
      ? const [
          ('متى أدفع؟', 'بعد موافقة الفندق على طلبكم أمامكم 24 ساعة لدفع العربون. لا يُخصم شيء قبل ذلك.'),
          ('هل أستطيع تغيير التاريخ؟', 'اطلبوا من صفحة الحجز. يقترح الفندق تواريخ جديدة ويحفظ سعركم 72 ساعة.'),
          ('ماذا يغطي العربون؟', 'العربون جزء من إجماليكم وليس رسمًا إضافيًا. المتبقي يستحق قبل يومكم بـ 14 يومًا.'),
        ]
      : const [
          ('When do I pay?', 'After the hotel approves your request you have 24 hours to pay the deposit. Nothing is charged before.'),
          ('Can I change the date?', 'Ask from the booking page. The hotel proposes new dates and holds your price for 72 hours.'),
          ('What does the deposit cover?', 'The deposit is part of your total, never an extra. The balance is due 14 days before your day.'),
        ];
}

_Copy _c(BuildContext context) => _Copy(context.gz.isAr);

const String _first = 'ballrooms-08-ivory-arched-ballroom-parquet';

List<GzTabItem> _clientTabs(_Copy c, {GzTabBadge? weddingBadge, GzTabBadge? messagesBadge}) => [
      GzTabItem(id: 'discover', icon: GzIcons.search, label: c._p('Discover', 'استكشف')),
      GzTabItem(id: 'saved', icon: GzIcons.heart, label: c._p('Saved', 'المفضلة')),
      GzTabItem(id: 'my-wedding', icon: GzIcons.calendarCheck, label: c._p('My Wedding', 'زفافكم'), badge: weddingBadge),
      GzTabItem(id: 'messages', icon: GzIcons.chat, label: c._p('Messages', 'الرسائل'), badge: messagesBadge),
      GzTabItem(id: 'profile', icon: GzIcons.user, label: c._p('Profile', 'حسابكم')),
    ];

List<GzTabItem> _partnerTabs(_Copy c, {GzTabBadge? bookings, GzTabBadge? messages}) => [
      GzTabItem(id: 'today', icon: GzIcons.home, label: c._p('Today', 'اليوم')),
      GzTabItem(id: 'bookings', icon: GzIcons.clipboard, label: c._p('Bookings', 'الحجوزات'), badge: bookings),
      GzTabItem(id: 'calendar', icon: GzIcons.calendar, label: c._p('Calendar', 'التقويم')),
      GzTabItem(id: 'messages', icon: GzIcons.chat, label: c._p('Messages', 'الرسائل'), badge: messages),
      GzTabItem(id: 'more', icon: GzIcons.more, label: c._p('More', 'المزيد')),
    ];

Widget _fill() => const Expanded(child: SizedBox.shrink());

List<GzTopBarAction> _shareHeart(_Copy c) => [
      GzTopBarAction(icon: GzIcons.share, label: c.venueFacts),
      GzTopBarAction(icon: GzIcons.heart, label: c.discover),
    ];

// ------------------------------------------------------------------------------------------------------------------ 1 proto
Widget _proto(BuildContext context) {
  final c = _c(context);
  final t = context.gz.colors;
  return navSection(context, c.sectionTitle('proto'), [
    navSpecimenBare(context, c.live, const NavDevice(height: GzLayout.frameHeight, bezel: true, children: [Expanded(child: NavDemoApp())])),
    SizedBox(
      width: navFrameWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GzText(c.protoNote, role: GzTextRole.body, color: t.textPrimary),
          const SizedBox(height: GzSpace.s3),
          GzText(c.protoRoute, role: GzTextRole.caption, color: t.textSecondary),
        ],
      ),
    ),
  ]);
}

Widget navSpecimenBare(BuildContext context, String label, Widget frame) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [frame, const SizedBox(height: GzSpace.s3), SizedBox(width: navFrameWidth, child: GzText(label, role: GzTextRole.caption, color: context.gz.colors.textSecondary))],
    );

// ------------------------------------------------------------------------------------------------------------------ 2 bars
Widget _bars(BuildContext context) {
  final c = _c(context);
  return navSection(context, c.sectionTitle('bars'), [
    navSpecimen(
      context,
      c.tabClient,
      NavDevice(height: 168, children: [
        _fill(),
        GzTabBar(items: _clientTabs(c, weddingBadge: const GzTabBadge.dot(), messagesBadge: const GzTabBadge.count(3)), activeId: 'saved', ariaLabel: 'tabs'),
      ]),
    ),
    navSpecimen(
      context,
      c.tabHotel,
      NavDevice(height: 168, app: GzAppKind.partner, children: [
        _fill(),
        GzTabBar(items: _partnerTabs(c, bookings: const GzTabBadge.count(12, tone: GzCountTone.danger), messages: const GzTabBadge.count(2)), activeId: 'bookings', ariaLabel: 'tabs'),
      ]),
    ),
    navSpecimen(
      context,
      c.tabPressed,
      NavDevice(height: 168, children: [_fill(), GzTabBar(items: _clientTabs(c), activeId: 'discover', ariaLabel: 'tabs', previewPressed: 'messages')]),
    ),
    navSpecimen(
      context,
      c.topStandard,
      NavDevice(height: 200, children: [GzTopBar(back: GzTopBarBack.show, title: c.standardTitle, subtitle: c.subtitle, actions: _shareHeart(c))]),
    ),
    navSpecimen(
      context,
      c.topLarge,
      NavDevice(height: 220, children: [GzTopBar(variant: GzTopBarVariant.largeTitle, title: c.largeTitle, back: GzTopBarBack.hide, actions: [GzTopBarAction(icon: GzIcons.bell, label: c.discover, count: 3)])]),
    ),
    navSpecimen(
      context,
      '${c.topLarge} · scrolled',
      NavDevice(height: 200, children: [
        GzScreenScroll(
          offset: 48,
          child: GzTopBar(variant: GzTopBarVariant.largeTitle, title: c.largeTitle, back: GzTopBarBack.hide, actions: [GzTopBarAction(icon: GzIcons.bell, label: c.discover, count: 3)]),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.topTransparent,
      NavDevice(
        height: 300,
        chrome: NavChrome.light,
        underlays: const [NavPhoto(id: _first)],
        children: [GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.show, actions: _shareHeart(c))],
      ),
    ),
    navSpecimen(
      context,
      c.topSolid,
      NavDevice(height: 200, children: [
        GzScreenScroll(offset: 600, child: GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.show, title: c.standardTitle, actions: _shareHeart(c))),
      ]),
    ),
    navSpecimen(
      context,
      c.topSearch,
      NavDevice(height: 200, children: [
        GzTopBar(variant: GzTopBarVariant.search, back: GzTopBarBack.show, search: GzTopBarSearch(placeholder: c.searchPlaceholder), actions: [GzTopBarAction(icon: GzIcons.sliders, label: c.briefBudget)]),
      ]),
    ),
    navSpecimen(
      context,
      c.action,
      NavDevice(height: 260, children: [
        _fill(),
        GzActionBar(
          summaryLabel: c.totalFor,
          summaryValue: const GzPrice(fils: 18200000, size: GzPriceSize.display),
          action: GzActionBarAction(label: c.requestThisDate, onPressed: () {}),
          note: c.noPayment,
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.actionHotel,
      NavDevice(height: 260, app: GzAppKind.partner, children: [
        _fill(),
        GzBottomChrome(
          tabBar: true,
          child: GzActionBar(action: GzActionBarAction(label: c.briefDone, onPressed: () {}), secondary: GzActionBarAction(label: c.confirmCancel, onPressed: () {})),
        ),
        GzTabBar(items: _partnerTabs(c), activeId: 'more', ariaLabel: 'tabs'),
      ]),
    ),
  ]);
}

// ------------------------------------------------------------------------------------------------------------------ 3 overlays
Widget _sheetRows(_Copy c) => Column(
      children: [
        GzListRow(title: c.briefDate, subtitle: c.briefRow, flush: true),
        GzListRow(title: c.briefGuests, subtitle: c.guestsValue, flush: true),
        GzListRow(title: c.briefArea, subtitle: c.areaValue, flush: true),
        GzListRow(title: c.briefBudget, subtitle: c.budgetValue, flush: true, last: true),
      ],
    );

Widget _overlays(BuildContext context) {
  final c = _c(context);
  Widget dialogDevice({required Widget dialog}) => NavDevice(
        height: 440,
        underlays: const [NavPhoto(id: _first)],
        overlays: [
          const Positioned.fill(child: GzScrim()),
          Positioned.fill(child: Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: Center(child: dialog))),
        ],
      );
  return navSection(context, c.sectionTitle('overlays'), [
    navSpecimen(
      context,
      c.sheet,
      NavDevice(
        height: 520,
        underlays: const [NavPhoto(id: _first)],
        overlays: [
          const Positioned.fill(child: GzScrim()),
          Align(
            alignment: Alignment.bottomCenter,
            child: GzSheet(
              title: c.sheetTitle,
              onRequestClose: () {},
              footer: GzButton(label: c.briefDone, onPressed: () {}, fullWidth: true),
              child: _sheetRows(c),
            ),
          ),
        ],
      ),
    ),
    navSpecimen(
      context,
      c.dialog,
      dialogDevice(dialog: GzDialog(title: c.confirmTitle, body: c.confirmBody, icon: GzIcons.send, confirmLabel: c.confirmCta, cancelLabel: c.confirmCancel)),
    ),
    navSpecimen(
      context,
      c.dialogDestructive,
      dialogDevice(dialog: GzDialog(tone: GzDialogTone.destructive, title: c.dTitle, body: c.dBody, icon: GzIcons.warning, confirmLabel: c.dConfirm, cancelLabel: c.confirmCancel)),
    ),
    navSpecimen(
      context,
      c.banners,
      NavDevice(height: 440, children: [
        GzTopBar(back: GzTopBarBack.show, title: c.standardTitle),
        GzBanner(tone: GzBannerTone.offline, message: c.bOffline),
        const SizedBox(height: GzSpace.s3),
        GzBanner(message: c.bInfo, onDismiss: () {}),
        const SizedBox(height: GzSpace.s3),
        GzBanner(tone: GzBannerTone.warning, message: c.bWarning, actionLabel: c.bRetry, onAction: () {}),
        const SizedBox(height: GzSpace.s3),
        GzBanner(tone: GzBannerTone.danger, message: c.bOffline),
      ]),
    ),
    navSpecimen(
      context,
      c.empty,
      NavDevice(height: 520, children: [
        Expanded(
          child: GzScreen(
            top: GzTopBar(variant: GzTopBarVariant.largeTitle, title: c.largeTitle, back: GzTopBarBack.hide),
            child: GzEmptyState(icon: GzIcons.heart, title: c.emptyTitle, body: c.emptyBody, action: GzStateAction(label: c.emptyAction, onPressed: () {}, variant: GzButtonVariant.secondary)),
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.error,
      NavDevice(height: 520, children: [
        Expanded(
          child: GzScreen(top: GzTopBar(back: GzTopBarBack.show, title: c.standardTitle), child: GzErrorState(kind: GzErrorKind.network, onRetry: () {})),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.pull,
      NavDevice(height: 200, children: [
        GzTopBar(title: c.largeTitle, back: GzTopBarBack.hide),
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: GzSpace.s8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [GzPullIndicator(progress: 0.4), GzPullIndicator(progress: 1), GzPullIndicator(progress: 1, refreshing: true)],
          ),
        ),
      ]),
    ),
  ]);
}

// ------------------------------------------------------------------------------------------------------------------ 4 media
Widget _media(BuildContext context) {
  final c = _c(context);
  final images = navDemoImages(c.galleryLabel).take(5).toList();
  final all = navDemoImages(c.galleryLabel);
  return navSection(context, c.sectionTitle('media'), [
    navSpecimen(
      context,
      c.pager,
      NavDevice(height: 300, children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s24),
          child: GzPager(
            mode: GzPagerMode.peek,
            label: c.galleryLabel,
            children: [
              for (final img in images)
                SizedBox(
                  height: GzSpace.s24,
                  // The web demo page is a block box: the photograph keeps its natural ratio at the page width and the top 96 show.
                  child: ClipRRect(
                    borderRadius: GzRadius.mdAll,
                    child: OverflowBox(alignment: AlignmentDirectional.topStart, minHeight: 0, maxHeight: double.infinity, child: GzPhoto(src: img.src, aspectRatio: 1.5)),
                  ),
                ),
            ],
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.hero,
      NavDevice(height: 560, chrome: NavChrome.light, children: [
        Expanded(
          child: GzScreen(
            top: GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.show, actions: [GzTopBarAction(icon: GzIcons.share, label: c.venueFacts)]),
            topOverlay: true,
            child: GzImageCarousel(images: all, label: c.galleryLabel),
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.tour,
      NavDevice(height: 300, children: [
        Padding(padding: const EdgeInsetsDirectional.only(top: GzSpace.s24), child: GzImageCarousel(variant: GzCarouselVariant.tour, images: all, label: c.galleryLabel)),
      ]),
    ),
    navSpecimen(
      context,
      c.viewer,
      NavDevice(height: 560, chrome: NavChrome.light, children: [
        Expanded(
          child: GzScreen(
            top: const GzTopBar(variant: GzTopBarVariant.transparent, back: GzTopBarBack.show),
            topOverlay: true,
            child: GzImageCarousel(images: all, label: c.galleryLabel, onOpen: (_) {}),
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      c.accordion,
      NavDevice(height: 440, children: [
        GzTopBar(back: GzTopBarBack.show, title: c.standardTitle),
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: GzAccordion(
            initialOpenIds: const ['f1'],
            items: [
              for (var i = 0; i < c.faq.length; i++)
                GzAccordionItem(id: 'f$i', title: c.faq[i].$1, summary: c.faq[i].$2, content: GzText(c.faq[i].$2, role: GzTextRole.bodyS, color: context.gz.colors.textPrimary)),
            ],
          ),
        ),
      ]),
    ),
  ]);
}

// ------------------------------------------------------------------------------------------------------------------ 5 frames
Widget _frames(BuildContext context) {
  final c = _c(context);
  return navSection(context, c.sectionTitle('frames'), [
    navSpecimen(context, c.statusDark, NavDevice(height: 200, children: [GzTopBar(back: GzTopBarBack.hide, title: c.standardTitle)])),
    navSpecimen(context, c.statusLight, const NavDevice(height: 300, chrome: NavChrome.light, underlays: [NavPhoto(id: _first)])),
    navSpecimen(context, c.chromeNone, const NavDevice(height: 200, chrome: NavChrome.none, underlays: [NavPhoto(id: _first)])),
    navSpecimen(context, c.bezel, const NavDevice(height: 300, bezel: true, underlays: [NavPhoto(id: _first)])),
    navSpecimen(context, '360', NavDevice(width: 360, height: 300, children: [GzTopBar(variant: GzTopBarVariant.largeTitle, title: c.largeTitle, back: GzTopBarBack.hide)])),
    navSpecimen(context, '430', NavDevice(width: 430, height: 300, children: [GzTopBar(variant: GzTopBarVariant.largeTitle, title: c.largeTitle, back: GzTopBarBack.hide)])),
  ]);
}
