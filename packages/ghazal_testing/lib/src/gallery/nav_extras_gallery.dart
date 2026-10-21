// Sections the web nav gallery does not have: the options added in the F3 component wave (KIT-U2). They carry numbers from 51 so they
// never pair with a web reference (the parity board scores only the five web sections); each is read in Arabic by eye and measured by
// the widget tests (packages/ghazal_ui/test/nav/bars_extras_test.dart, overlays/sheet_slots_test.dart, overlays/info_test.dart).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';
import 'package:ghazal_ui/src/nav/nav.dart';
import 'package:ghazal_ui/src/overlays/overlays.dart';

import 'gz_gallery.dart';
import 'nav_gallery_kit.dart';

/// The extra sections of the nav and overlays galleries (appended to `navGallerySections`).
List<GzGallerySection> navExtrasGallerySections() => [
      GzGallerySection('bars-extras', _bars, width: 310, number: 51),
      GzGallerySection('sheet-slots', _sheets, width: 310, number: 52),
      GzGallerySection('info', _info, width: 310, number: 53),
    ];

String _p(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _fill() => const Expanded(child: SizedBox.shrink());

Widget _bars(BuildContext context) {
  final c = context.gz.colors;
  String p(String en, String ar) => _p(context, en, ar);
  return navSection(context, 'bars-extras', [
    navSpecimen(
      context,
      p('ActionBar, note as a widget (a quiet link)', 'شريط الإجراء، الملاحظة عنصر (رابط هادئ)'),
      NavDevice(height: 200, children: [
        _fill(),
        GzActionBar(
          action: GzActionBarAction(label: p('Continue', 'متابعة'), onPressed: () {}),
          noteWidget: Center(child: GzButton(label: p('Sign in', 'تسجيل الدخول'), variant: GzButtonVariant.tertiary, iconStart: GzIcons.signIn, onPressed: () {})),
        ),
      ]),
    ),
    navSpecimen(
      context,
      p('ActionBar, note as a widget (two quiet buttons)', 'شريط الإجراء، زران هادئان'),
      NavDevice(height: 220, app: GzAppKind.partner, children: [
        _fill(),
        GzActionBar(
          action: GzActionBarAction(label: p('Go to Today', 'إلى اليوم'), onPressed: () {}),
          noteWidget: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GzButton(label: p('Switch venue', 'تبديل المكان'), variant: GzButtonVariant.tertiary, onPressed: () {}),
              GzButton(label: p('Sign out', 'تسجيل الخروج'), variant: GzButtonVariant.tertiary, onPressed: () {}),
            ],
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      p('TopBar, title widget (monogram and name)', 'الشريط العلوي، عنوان عنصر (حرف واسم)'),
      NavDevice(height: 200, children: [
        GzTopBar(
          back: GzTopBarBack.show,
          titleWidget: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GzAvatar(name: 'Najla Al-Bader', size: GzAvatarSize.xs),
              const SizedBox(width: GzSpace.s2),
              GzText(p('Najla Al-Bader', 'نجلاء البدر'), role: GzTextRole.title, color: c.textStrong, maxLines: 1, header: true),
            ],
          ),
          actions: [GzTopBarAction(icon: GzIcons.phone, label: p('Call', 'اتصال'), onPressed: () {})],
        ),
      ]),
    ),
    navSpecimen(
      context,
      p('TopBar, step bar: title widget, info glyph, a word at the end', 'الشريط العلوي، شريط الخطوات وكلمة في النهاية'),
      NavDevice(height: 200, children: [
        GzTopBar(
          back: GzTopBarBack.show,
          titleWidget: SizedBox(height: 8, child: ColoredBox(color: c.borderHairline)),
          actions: [GzTopBarAction(icon: GzIcons.info, label: p('More info', 'مزيد من المعلومات'), onPressed: () {})],
          textAction: GzTopBarTextAction(label: p('Skip', 'تخطي'), onPressed: () {}),
        ),
      ]),
    ),
  ]);
}

Widget _sheets(BuildContext context) {
  String p(String en, String ar) => _p(context, en, ar);
  final c = context.gz.colors;
  Widget header() => Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.s2),
        child: SizedBox(
          height: GzSize.controlMd,
          child: Row(children: [Expanded(child: GzText(p('Filters', 'التصفية'), role: GzTextRole.d1, color: c.textStrong, header: true)), GzBarButton(icon: GzIcons.close, label: p('Close', 'إغلاق'), onPressed: () {})]),
        ),
      );
  return navSection(context, 'sheet-slots', [
    navSpecimen(
      context,
      p('Sheet, fill (90 %): pinned header, scrolling body, pinned footer', 'الورقة، ملء 90%: رأس ثابت وجسم يتمرر وتذييل ثابت'),
      NavDevice(
        height: 640,
        underlays: [ColoredBox(color: c.surfaceQuiet)],
        overlays: [
          const Positioned.fill(child: GzScrim()),
          Align(
            alignment: Alignment.bottomCenter,
            child: GzSheet(
              fill: true,
              header: header(),
              footer: GzButton(label: p('Show 24 halls', 'عرض 24 قاعة'), onPressed: () {}, fullWidth: true),
              onRequestClose: () {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < 4; i++) GzListRow(title: p('Row ${i + 1}', 'صف ${i + 1}'), subtitle: p('Quiet caption', 'سطر هادئ'), flush: true, chevron: true),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ]);
}

Widget _info(BuildContext context) {
  String p(String en, String ar) => _p(context, en, ar);
  final c = context.gz.colors;
  return navSection(context, 'info', [
    navSpecimen(
      context,
      p('InfoButton beside a checkbox, AsideInfo row', 'زر المعلومات بجانب خانة اختيار، وصف الملاحظة'),
      NavDevice(height: 200, chrome: NavChrome.none, children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter, vertical: GzSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: GzCheckbox(label: p('I agree to the terms', 'أوافق على الشروط'), checked: true, onChanged: (_) {})),
                  GzInfoButton(title: p('The terms', 'الشروط'), paragraphs: [p('One short paragraph.', 'فقرة قصيرة واحدة.')], bleed: true),
                ],
              ),
              const SizedBox(height: GzSpace.s4),
              GzAsideInfo(icon: GzIcons.lock, word: p('Private', 'خاص'), title: p('Your privacy', 'خصوصيتكم'), paragraphs: [p('Only the venue sees this.', 'يراها المكان وحده.')]),
              const SizedBox(height: GzSpace.s4),
              GzText(p('The sheet they open', 'الورقة التي يفتحانها'), role: GzTextRole.caption, color: c.textSecondary),
            ],
          ),
        ),
      ]),
    ),
    navSpecimen(
      context,
      p('InfoSheet: title, paragraphs, Done', 'ورقة المعلومات: العنوان والفقرات وتم'),
      NavDevice(
        height: 360,
        underlays: [ColoredBox(color: c.surfaceQuiet)],
        overlays: [
          const Positioned.fill(child: GzScrim()),
          Align(
            alignment: Alignment.bottomCenter,
            child: GzSheet(
              title: p('The terms', 'الشروط'),
              onRequestClose: () {},
              footer: GzButton(label: p('Done', 'تم'), variant: GzButtonVariant.secondary, fullWidth: true, onPressed: () {}),
              child: GzInfoBody(children: [
                GzText(p('The coupon is valid for 60 days and tied to one venue.', 'الكوبون صالح 60 يومًا ومرتبط بمكان واحد.'), role: GzTextRole.body, color: c.textPrimary, figures: true),
                GzText(p('Everything else is agreed with the venue.', 'وكل ما عدا ذلك يُتفق عليه مع المكان.'), role: GzTextRole.body, color: c.textPrimary),
              ]),
            ),
          ),
        ],
      ),
    ),
  ]);
}
