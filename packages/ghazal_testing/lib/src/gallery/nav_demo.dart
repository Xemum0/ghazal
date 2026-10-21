// The Flutter twin of the web "live prototype" (PrototypePlayer + DEMO_SCREENS): a small navigator demo that exercises push and pop
// (GzPageRoute), the tab bar, a sheet, a dialog, the toast and the undo bar, the photo carousel and the viewer. A pixel comparison
// with the web player does not apply (the web renders the product screens of the prototype inside a bezel; this demo is a mechanism
// check), so the gallery only proves it renders and the tests drive it.
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

/// Copy of the demo in both languages (gallery only).
class NavDemoCopy {
  const NavDemoCopy(this.isAr);

  final bool isAr;

  String get discover => isAr ? 'استكشف' : 'Discover';
  String get hallsOpen => isAr ? 'قاعات متاحة في تاريخكم' : 'Halls open on your date';
  String get hallName => isAr ? 'فندق أوريليا الخليج' : 'Aurelia Gulf Hotel';
  String get hallArea => isAr ? 'شرق' : 'Sharq';
  String get hall2 => isAr ? 'قاعة دانة' : 'Danah Ballroom';
  String get openSheet => isAr ? 'فتح ورقة' : 'Open a sheet';
  String get openDialog => isAr ? 'فتح نافذة' : 'Open a dialog';
  String get showToast => isAr ? 'عرض إشعار' : 'Show a toast';
  String get showUndo => isAr ? 'عرض شريط التراجع' : 'Show the undo bar';
  String get sheetTitle => isAr ? 'تاريخكم' : 'Your date';
  String get briefDate => isAr ? 'التاريخ' : 'Date';
  String get briefRow => isAr ? 'الخميس 14 يناير 2027' : 'Thursday 14 January 2027';
  String get briefDone => isAr ? 'تم' : 'Done';
  String get confirmTitle => isAr ? 'إرسال هذا الطلب؟' : 'Send this request?';
  String get confirmBody => isAr ? 'يرد الفندق خلال 24 ساعة. لا شيء يُدفع الآن.' : 'The hotel replies within 24 hours. You pay nothing now.';
  String get confirmCta => isAr ? 'إرسال الطلب' : 'Send request';
  String get confirmCancel => isAr ? 'ليس بعد' : 'Not yet';
  String get requestThisDate => isAr ? 'اطلبوا هذا التاريخ' : 'Request this date';
  String get totalFor => isAr ? 'الإجمالي لعدد 350 مدعوًا' : 'Total for 350 guests';
  String get noPayment => isAr ? 'لا دفع الآن. لن يُخصم شيء حتى يوافق الفندق.' : 'No payment now. Nothing is charged until the hotel approves.';
  String get sentToast => isAr ? 'تم إرسال الطلب إلى الفندق' : 'Request sent to the hotel';
  String get undoToast => isAr ? 'تم سحب الطلب' : 'Request withdrawn';
  String get undone => isAr ? 'تم التراجع' : 'Undone';
  String get galleryLabel => isAr ? 'صور فندق أوريليا الخليج' : 'Photos of Aurelia Gulf Hotel';
  String get tabBarLabel => isAr ? 'التنقل الرئيسي' : 'Main navigation';
  List<GzTabItem> tabs(String active) => [
        GzTabItem(id: 'discover', icon: GzIcons.search, label: discover),
        GzTabItem(id: 'saved', icon: GzIcons.heart, label: isAr ? 'المفضلة' : 'Saved'),
        GzTabItem(id: 'my-wedding', icon: GzIcons.calendarCheck, label: isAr ? 'زفافكم' : 'My Wedding'),
        GzTabItem(id: 'messages', icon: GzIcons.chat, label: isAr ? 'الرسائل' : 'Messages'),
        GzTabItem(id: 'profile', icon: GzIcons.user, label: isAr ? 'حسابكم' : 'Profile'),
      ];
}

const List<String> navDemoPhotoIds = [
  'ballrooms-08-ivory-arched-ballroom-parquet',
  'ballrooms-09-blush-marble-gilt-ballroom',
  'ballrooms-10-colonnade-hall-glass-ceiling',
  'ballrooms-26-checkered-marble-ballroom',
  'ballrooms-12-columned-hall-gold-chandelier-chairs',
  'ballrooms-29-gold-chandelier-textured-wall',
  'halls-08-grand-ballroom-crystal-chandelier',
  'halls-23-arched-niche-majlis-seating',
];

List<GzCarouselImage> navDemoImages(String alt) => [for (final id in navDemoPhotoIds) GzCarouselImage(src: 'asset://ghazal_mock_api/images/$id', alt: alt)];

/// The demo app: a nested [Navigator] (so the sheet, dialog and toast stay inside the frame it is drawn in) with a home screen on
/// the client tab bar and a venue screen pushed with the Ghazal transition.
class NavDemoApp extends StatefulWidget {
  const NavDemoApp({super.key});

  @override
  State<NavDemoApp> createState() => _NavDemoAppState();
}

class _NavDemoAppState extends State<NavDemoApp> {
  final GlobalKey<NavigatorState> _nav = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GzToastHost(
      child: Navigator(
        key: _nav,
        onGenerateRoute: (settings) => GzPageRoute<void>(settings: settings, builder: (_) => const _HomeScreen()),
      ),
    );
  }
}

class _HomeScreen extends StatefulWidget {
  const _HomeScreen();

  @override
  State<_HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<_HomeScreen> {
  String _tab = 'discover';

  @override
  Widget build(BuildContext context) {
    final copy = NavDemoCopy(context.gz.isAr);
    final c = context.gz.colors;
    return GzBottomChrome(
      tabBar: true,
      child: GzScreen(
        top: GzTopBar(variant: GzTopBarVariant.largeTitle, title: copy.discover, back: GzTopBarBack.hide, actions: [GzTopBarAction(icon: GzIcons.bell, label: copy.discover, count: 3)]),
        bottom: GzTabBar(items: copy.tabs(_tab), activeId: _tab, ariaLabel: copy.tabBarLabel, onSelect: (id) => setState(() => _tab = id)),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GzText(copy.hallsOpen, role: GzTextRole.title, color: c.textStrong),
              const SizedBox(height: GzSpace.s3),
              for (final name in [copy.hallName, copy.hall2])
                Padding(
                  padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s3),
                  child: GzPressable(
                    key: ValueKey('demo:hall:$name'),
                    onPressed: () => Navigator.of(context).push<void>(GzPageRoute<void>(builder: (_) => const _VenueScreen())),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GzPhoto(src: 'asset://ghazal_mock_api/images/${navDemoPhotoIds[name == copy.hallName ? 0 : 1]}', aspectRatio: GzLayout.aspect16x10, borderRadius: GzRadius.mdAll),
                          const SizedBox(height: GzSpace.s2),
                          GzText(name, role: GzTextRole.title, color: c.textStrong),
                          GzText(copy.hallArea, role: GzTextRole.caption, color: c.textSecondary),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: GzSpace.s3),
              Wrap(
                spacing: GzSpace.s3,
                runSpacing: GzSpace.s3,
                children: [
                  GzButton(
                    key: const ValueKey('demo:sheet'),
                    label: copy.openSheet,
                    variant: GzButtonVariant.secondary,
                    onPressed: () => showGzSheet<void>(
                      context,
                      useRootNavigator: false,
                      title: copy.sheetTitle,
                      footer: Builder(builder: (ctx) => GzButton(label: copy.briefDone, fullWidth: true, onPressed: () => Navigator.of(ctx).pop())),
                      builder: (_) => GzListRow(title: copy.briefDate, subtitle: copy.briefRow, flush: true, last: true),
                    ),
                  ),
                  GzButton(
                    key: const ValueKey('demo:dialog'),
                    label: copy.openDialog,
                    variant: GzButtonVariant.secondary,
                    onPressed: () => showGzDialog(
                      context,
                      GzDialogSpec(title: copy.confirmTitle, body: copy.confirmBody, icon: GzIcons.send, confirmLabel: copy.confirmCta, cancelLabel: copy.confirmCancel),
                      useRootNavigator: false,
                    ),
                  ),
                  GzButton(
                    key: const ValueKey('demo:toast'),
                    label: copy.showToast,
                    variant: GzButtonVariant.secondary,
                    onPressed: () => GzToasts.show(context, message: copy.sentToast, tone: GzToastTone.success),
                  ),
                  GzButton(
                    key: const ValueKey('demo:undo'),
                    label: copy.showUndo,
                    variant: GzButtonVariant.secondary,
                    onPressed: () => GzToasts.show(context, message: copy.undoToast, undo: true, action: GzToastAction(label: copy.undone, onPressed: () {})),
                  ),
                ],
              ),
              const SizedBox(height: GzSpace.s6),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueScreen extends StatefulWidget {
  const _VenueScreen();

  @override
  State<_VenueScreen> createState() => _VenueScreenState();
}

class _VenueScreenState extends State<_VenueScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final copy = NavDemoCopy(context.gz.isAr);
    final c = context.gz.colors;
    final images = navDemoImages(copy.galleryLabel);
    return GzScreen(
      top: GzTopBar(variant: GzTopBarVariant.transparent, actions: [GzTopBarAction(icon: GzIcons.share, label: copy.hallName)]),
      topOverlay: true,
      bottom: GzActionBar(
        summaryLabel: copy.totalFor,
        summaryValue: const GzPrice(fils: 18200000, size: GzPriceSize.display),
        action: GzActionBarAction(
          label: copy.requestThisDate,
          onPressed: () async {
            final r = await showGzDialog(
              context,
              GzDialogSpec(title: copy.confirmTitle, body: copy.confirmBody, icon: GzIcons.send, confirmLabel: copy.confirmCta, cancelLabel: copy.confirmCancel),
              useRootNavigator: false,
            );
            if (r == GzDialogResult.confirm && context.mounted) GzToasts.show(context, message: copy.sentToast, tone: GzToastTone.success);
          },
        ),
        note: copy.noPayment,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzImageCarousel(
            images: images,
            label: copy.galleryLabel,
            index: _index,
            onIndexChanged: (i) => setState(() => _index = i),
            heroGroup: 'demo',
            onOpen: (i) => showGzGalleryViewer(context, images: images, label: copy.galleryLabel, initialIndex: i, heroGroup: 'demo', onIndexChanged: (v) => setState(() => _index = v), useRootNavigator: false),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.all(GzSpace.gutter),
            child: GzText(copy.hallName, role: GzTextRole.title, color: c.textStrong),
          ),
        ],
      ),
    );
  }
}
