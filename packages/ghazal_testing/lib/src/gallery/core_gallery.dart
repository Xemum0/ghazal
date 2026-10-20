// The core + brand component gallery: the Flutter twin of design/src/gallery/core.tsx (#/gallery/core). Same 17 sections in the
// same order (titles equal the web section titles so the reference PNGs pair by file name), the same variants, states and sample
// text. Parity: `node tools/parity/parity.mjs --gallery core` after `flutter test test/gallery/core_gallery_test.dart`.
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/brand/brand.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'gz_gallery.dart';

/// The web section titles, English (file slugs) and Arabic (the Arabic reference file names).
const List<String> coreGalleryTitlesEn = [
  'Icon',
  'Button',
  'Icon button',
  'Chip and filter chip',
  'Badge and count badge',
  'Status pill',
  'Avatar',
  'Rating',
  'Price',
  'Divider and thread rule',
  'Switch, checkbox, radio',
  'Skeleton',
  'Toast and undo bar',
  'List row',
  'Section header',
  'Key fact and tag',
  'Brand',
];

const List<String> coreGalleryTitlesAr = [
  'الأيقونة',
  'الزر',
  'زر الأيقونة',
  'الشريحة وشريحة التصفية',
  'الشارة وشارة العدد',
  'شارة الحالة',
  'الصورة الرمزية',
  'التقييم',
  'السعر',
  'الفاصل وخط الخيط',
  'المفتاح ومربع الاختيار والزر الدائري',
  'هيكل التحميل',
  'التنبيه وشريط التراجع',
  'صف القائمة',
  'رأس القسم',
  'الحقيقة السريعة والوسم',
  'الهوية',
];

/// The sections of the core gallery page.
List<GzGallerySection> coreGallerySections() {
  final builders = <WidgetBuilder>[
    _iconSection,
    _buttonSection,
    _iconButtonSection,
    _chipSection,
    _badgeSection,
    _pillSection,
    _avatarSection,
    _ratingSection,
    _priceSection,
    _threadSection,
    _controlSection,
    _skeletonSection,
    _toastSection,
    _rowSection,
    _headerSection,
    _factSection,
    _brandSection,
  ];
  return [for (var i = 0; i < builders.length; i++) GzGallerySection(coreGalleryTitlesEn[i], builders[i])];
}

/// Copies every `NN-<english slug>.ar.png` to the Arabic reference name (`NN-<arabic slug>.ar.png`) so
/// `parity.mjs --gallery core` pairs the Arabic renders (the web reference files are named after the Arabic titles).
void coreGalleryAliasArabicFiles(String dir) {
  for (var i = 0; i < coreGalleryTitlesEn.length; i++) {
    final n = (i + 1).toString().padLeft(2, '0');
    final from = File('$dir/$n-${GzGallerySection(coreGalleryTitlesEn[i], (_) => const SizedBox()).slug}.ar.png');
    final to = File('$dir/$n-${GzGallerySection(coreGalleryTitlesAr[i], (_) => const SizedBox()).slug}.ar.png');
    if (from.existsSync()) from.copySync(to.path);
  }
}

// ---------------------------------------------------------------------------------------------------------------- layout kit
class _OnDark extends InheritedWidget {
  const _OnDark({required super.child});

  static bool of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OnDark>() != null;

  @override
  bool updateShouldNotify(_OnDark oldWidget) => false;
}

String _c(BuildContext context, String key) => (context.gz.isAr ? _ar : _en)[key]!;

Widget _vgap(double h) => SizedBox(height: h);

Widget _caption(BuildContext context, String text) {
  final c = context.gz.colors;
  return GzText(text, role: GzTextRole.caption, color: _OnDark.of(context) ? c.textOnDarkMuted : c.textSecondary);
}

/// A section: header, note, groups (gap 20), like `.cg-sec`.
Widget _sec(BuildContext context, String title, String? note, List<Widget> children) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzSectionHeader(title: title, draw: GzDraw.off),
      if (note != null) ...[_vgap(GzSpace.s5), GzText(note, role: GzTextRole.bodyS, color: c.textSecondary)],
      for (final w in children) ...[_vgap(GzSpace.s5), w],
    ],
  );
}

Widget _group(BuildContext context, String label, Widget child) {
  final c = context.gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      GzText(label, role: GzTextRole.label, color: _OnDark.of(context) ? c.textOnDarkMuted : c.textSecondary),
      _vgap(GzSpace.s3),
      child,
    ],
  );
}

Widget _cell(BuildContext context, Widget child, {String? cap}) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [child, if (cap != null) ...[_vgap(GzSpace.s2), _caption(context, cap)]],
    );

/// `.cg-row`: wrap, gap 16; [center] aligns items to the bottom (`align-items: flex-end`).
Widget _row(List<Widget> children, {bool center = false}) => Wrap(
      spacing: GzSpace.s4,
      runSpacing: GzSpace.s4,
      crossAxisAlignment: center ? WrapCrossAlignment.end : WrapCrossAlignment.start,
      children: children,
    );

enum _Stage { panel, ink, tint }

Widget _stage(BuildContext context, List<Widget> children, {_Stage kind = _Stage.panel}) {
  final c = context.gz.colors;
  final box = Container(
    padding: const EdgeInsets.all(GzSpace.s4),
    decoration: BoxDecoration(
      borderRadius: GzRadius.mdAll,
      color: switch (kind) {
        _Stage.panel => c.surfaceRaised,
        _Stage.ink => c.surfaceDark,
        _Stage.tint => c.surfaceTint,
      },
      border: kind == _Stage.panel ? Border.all(color: c.controlChipBorder, width: GzStroke.hair) : null,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[if (i > 0) _vgap(GzSpace.s4), children[i]],
      ],
    ),
  );
  if (kind != _Stage.ink) return box;
  return _OnDark(child: DefaultTextStyle.merge(style: TextStyle(color: c.textOnDark), child: box));
}

const String _photoFile = '../../design/public/images/halls/halls-02-ivory-draped-ballroom.jpg';

/// `.cg-photo`: a real photograph with the gallery scrim, controls above it (start child, end child).
Widget _photo(BuildContext context, {Widget? start, Widget? end}) {
  final c = context.gz.colors;
  return ClipRRect(
    borderRadius: GzRadius.mdAll,
    child: AspectRatio(
      aspectRatio: GzLayout.aspect16x10,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: c.surfacePlaceholder),
          if (!Platform.environment.containsKey('GZ_NO_PHOTO'))
            Image(image: MemoryImage(File(_photoFile).readAsBytesSync()), fit: BoxFit.cover, gaplessPlayback: true),
          const DecoratedBox(decoration: BoxDecoration(gradient: GzGradient.gallery)),
          Padding(
            padding: const EdgeInsets.all(GzSpace.s2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [start ?? const SizedBox.shrink(), end ?? const SizedBox.shrink()],
            ),
          ),
        ],
      ),
    ),
  );
}

void _noop() {}

/// The reference render is taken after the 8 s line has run out: the specimens deplete at once.
const Duration _depleted = Duration(milliseconds: 1);

Widget _replay(BuildContext context) =>
    _row([GzButton(label: _c(context, 'replay'), variant: GzButtonVariant.tertiary, iconStart: GzIcons.refresh, onPressed: _noop)]);

// ---------------------------------------------------------------------------------------------------------------- copy
const Map<String, String> _en = {
  'eyebrow': 'Design system',
  'title': 'Core components',
  'lede': 'The primitives every screen is built from. Each one is shown in every variant and every state, in this language; switch language to check the mirror.',
  'switchTo': 'العربية',
  'icons': 'Icon',
  'iconsNote': 'One registry, four sizes (16, 20, 24, 32), one weight setting. Glyphs with an outline flip in Arabic; nothing else ever does.',
  'sizes': 'Sizes',
  'weights': 'Light and regular',
  'registry': 'Registry',
  'mirrors': 'Mirrors in Arabic (ADR 0014)',
  'tones': 'Tones',
  'buttons': 'Button',
  'buttonsNote': 'One primary per screen. Press is a tone step and a 0.985 scale; the tertiary underline shortens instead. Loading keeps the label and draws the thread once.',
  'variants': 'Variants',
  'states': 'States',
  'withIcons': 'With icons',
  'pair': 'Equal pair',
  'fullWidth': 'Full width',
  'heights': 'Heights',
  'primary': 'Primary 52',
  'secondary': 'Secondary 48',
  'tertiary': 'Tertiary 44',
  'destructive': 'Destructive 48',
  'def': 'Default',
  'pressed': 'Pressed',
  'focus': 'Focus',
  'disabled': 'Disabled',
  'loading': 'Loading',
  'selected': 'Selected',
  'reason': 'Pick a date to continue',
  'iconStart': 'Icon start',
  'iconEnd': 'Icon end',
  'iconButtons': 'Icon button',
  'iconButtonsNote': 'Always a 44 target. Over a photograph it is a canvas disk with the fab ring; a toggle keeps its ink and pops once.',
  'plain': 'Plain',
  'outline': 'Outline',
  'overImage': 'Over image 32',
  'overImageLg': 'Over image 44',
  'onScrim': 'On scrim',
  'toggle': 'Toggle off / on',
  'chips': 'Chip and filter chip',
  'chipsNote': 'Choice is ink and a bead, never a gold fill. The label keeps its width when selected.',
  'badges': 'Badge and count badge',
  'badgesNote': 'Badges are objective labels. The gold count is the only gold fill besides the one primary action.',
  'outlineB': 'Outline + bead',
  'photoB': 'On photo',
  'quietB': 'Quiet',
  'counts': 'Counts',
  'ring': 'Ring on a tab icon',
  'danger': 'SLA danger',
  'pills': 'Status pill',
  'pillsNote': 'Every request status of ADR 0033, every voucher, visit and listing state and every availability state: icon and label, never colour alone.',
  'client': 'Client wording',
  'hotel': 'Partner wording',
  'availability': 'Availability',
  'also': 'Beside a status',
  'vouchers': 'Voucher',
  'visits': 'Site visit',
  'listings': 'Listing',
  'avatars': 'Avatar',
  'avatarsNote': 'A monogram on rose-100, never a face. The hotel app uses the sans letter; the serif is for venue names and the greeting.',
  'serif': 'Serif (client)',
  'sans': 'Sans (hotel)',
  'ratings': 'Rating',
  'ratingsNote': 'Star, figure and count are separate items. The row fills from inline-start, so it mirrors.',
  'prices': 'Price',
  'pricesNote': 'Integer fils through the shared formatter. Browse shows dinars; exact shows three decimals with a quiet .000. The currency sits left of the number in both languages.',
  'browse': 'Browse',
  'exact': 'Exact',
  'sizesP': 'Sizes',
  'unitsP': 'Units and old price',
  'threads': 'Divider and thread rule',
  'threadsNote': 'The khayt marks a place, never decoration. It draws on once from inline-start; reduced motion keeps the finished line.',
  'hairline': 'Hairline',
  'strong': 'Strong',
  'khayt': 'Khayt 24',
  'full': 'Full',
  'knotV': 'With knot',
  'replay': 'Replay',
  'onInk': 'On ink',
  'controls': 'Switch, checkbox, radio',
  'controlsNote': 'Choice is ink-700, never gold. Every row is at least 44 high and tappable across its width.',
  'off': 'Off',
  'on': 'On',
  'indeterminate': 'Mixed',
  'error': 'Error',
  'skeleton': 'Skeleton',
  'skeletonNote': 'A static ink-100 shape. No shimmer, nothing loops; the image reveal is the only motion.',
  'toasts': 'Toast and undo bar',
  'toastsNote': 'Ink bar, canvas text, gold-400 action. The undo line depletes over eight seconds and also runs under reduced motion.',
  'toast': 'Toast',
  'undo': 'Undo bar',
  'region': 'Over a bar, 16 above',
  'rows': 'List row',
  'rowsNote': 'Minimum 64, queue 80. The chevron mirrors; names align by their own first letter.',
  'plainR': 'Title and sub-line',
  'withTrail': 'Leading, trailing, chevron',
  'queue': 'Queue row 80',
  'toggleRow': 'With a switch',
  'dangerRow': 'Danger',
  'sectionHeaders': 'Section header',
  'sectionHeadersNote': 'Khayt, optional eyebrow, title, See all. Client titles are serif; hotel titles are UI weight.',
  'facts': 'Key fact and tag',
  'stack': 'Stacked',
  'inline': 'Inline',
  'brand': 'Brand',
  'brandNote': 'The lockup never mirrors. The thread is always gold-500 and never above the letters.',
  'lockup': 'Master lockup',
  'single': 'Single script',
  'monograms': 'Monogram',
  'knots': 'Thread knots',
  'beads': 'Beads',
  'booking': 'Booking 20',
  'compactK': 'Compact 12',
  'ended': 'Ended',
  'open': 'Open',
  'now': 'Now',
  'tied': 'Tied',
  'pop': 'Pop',
  'guestsLbl': 'Guests',
  'sessionLbl': 'Session',
  'evening': 'Evening',
  'hallLbl': 'Hall',
  'vipLbl': 'VIP lounge',
  'nameSample': 'Noura Al-Sabah',
  'venueSample': 'Aurelia Gulf Hotel',
  'undoMsg': 'Request withdrawn',
  'toastMsg': 'Saved to your list',
  'fav': 'Save to favourites',
  'unfav': 'Remove from favourites',
  'compare': 'Add to compare',
  'areaSample': 'Salmiya',
};

const Map<String, String> _ar = {
  'eyebrow': 'نظام التصميم',
  'title': 'المكوّنات الأساسية',
  'lede': 'الوحدات التي تُبنى منها كل شاشة. يُعرض كل مكوّن بكل أشكاله وحالاته بهذه اللغة؛ بدّلوا اللغة للتأكد من الانعكاس.',
  'switchTo': 'English',
  'icons': 'الأيقونة',
  'iconsNote': 'سجلّ واحد وأربعة أحجام (16 و20 و24 و32) وإعداد واحد للسُّمك. الرموز ذات الإطار تنعكس بالعربية، ولا شيء غيرها.',
  'sizes': 'الأحجام',
  'weights': 'خفيف وعادي',
  'registry': 'السجلّ',
  'mirrors': 'ما ينعكس بالعربية (ADR 0014)',
  'tones': 'الألوان',
  'buttons': 'الزر',
  'buttonsNote': 'زر أساسي واحد في كل شاشة. الضغط تدرّج لوني وتصغير إلى 0.985؛ ويقصر خط الزر النصي بدلاً من ذلك. التحميل يُبقي النص ويرسم الخيط مرة واحدة.',
  'variants': 'الأشكال',
  'states': 'الحالات',
  'withIcons': 'مع أيقونات',
  'pair': 'زوجان متساويان',
  'fullWidth': 'بعرض كامل',
  'heights': 'الارتفاعات',
  'primary': 'أساسي 52',
  'secondary': 'ثانوي 48',
  'tertiary': 'نصي 44',
  'destructive': 'حذف 48',
  'def': 'افتراضي',
  'pressed': 'مضغوط',
  'focus': 'تركيز',
  'disabled': 'معطّل',
  'loading': 'تحميل',
  'selected': 'محدد',
  'reason': 'اختاروا تاريخاً للمتابعة',
  'iconStart': 'أيقونة في البداية',
  'iconEnd': 'أيقونة في النهاية',
  'iconButtons': 'زر الأيقونة',
  'iconButtonsNote': 'هدف لمس بحجم 44 دائماً. فوق الصورة هو قرص بلون الخلفية مع حلقة خفيفة؛ والمفتاح يبقى بالحبر ويقفز مرة واحدة.',
  'plain': 'عادي',
  'outline': 'بإطار',
  'overImage': 'فوق الصورة 32',
  'overImageLg': 'فوق الصورة 44',
  'onScrim': 'فوق التعتيم',
  'toggle': 'مفتاح: إيقاف / تشغيل',
  'chips': 'الشريحة وشريحة التصفية',
  'chipsNote': 'الاختيار بالحبر وخرزة، وليس بتعبئة ذهبية. يحافظ النص على عرضه عند الاختيار.',
  'badges': 'الشارة وشارة العدد',
  'badgesNote': 'الشارات تسميات موضوعية. العدد الذهبي هو التعبئة الذهبية الوحيدة إلى جانب الزر الأساسي.',
  'outlineB': 'إطار وخرزة',
  'photoB': 'فوق الصورة',
  'quietB': 'هادئة',
  'counts': 'الأعداد',
  'ring': 'حلقة فوق أيقونة تبويب',
  'danger': 'خطر المهلة',
  'pills': 'شارة الحالة',
  'pillsNote': 'كل حالات الطلب في ADR 0033 وحالات الكوبون والزيارة والإعلان وحالات التوفر: أيقونة ونص، وليس اللون وحده.',
  'client': 'صياغة العميل',
  'hotel': 'صياغة الشريك',
  'availability': 'التوفر',
  'also': 'بجانب الحالة',
  'vouchers': 'الكوبون',
  'visits': 'زيارة القاعة',
  'listings': 'الإعلان',
  'avatars': 'الصورة الرمزية',
  'avatarsNote': 'حرف أول على الوردي، وليس وجهاً. يستخدم تطبيق الفندق الحرف بالخط العادي؛ فالسيريف لأسماء القاعات والتحية.',
  'serif': 'سيريف (العميل)',
  'sans': 'عادي (الفندق)',
  'ratings': 'التقييم',
  'ratingsNote': 'النجمة والرقم والعدد عناصر منفصلة. يمتلئ الصف من بداية الاتجاه، لذلك ينعكس.',
  'prices': 'السعر',
  'pricesNote': 'فلوس صحيحة عبر المنسّق المشترك. التصفح يعرض الدنانير؛ والدقيق يعرض ثلاث خانات مع .000 هادئة. العملة على يسار الرقم باللغتين.',
  'browse': 'تصفح',
  'exact': 'دقيق',
  'sizesP': 'الأحجام',
  'unitsP': 'الوحدات والسعر القديم',
  'threads': 'الفاصل وخط الخيط',
  'threadsNote': 'الخيط الدقيق يحدّد مكاناً وليس زينة. يُرسم مرة واحدة من بداية الاتجاه؛ وتقليل الحركة يُبقي الخط مكتملاً.',
  'hairline': 'دقيق',
  'strong': 'قوي',
  'khayt': 'خيط 24',
  'full': 'كامل',
  'knotV': 'مع عقدة',
  'replay': 'أعد التشغيل',
  'onInk': 'على الحبر',
  'controls': 'المفتاح ومربع الاختيار والزر الدائري',
  'controlsNote': 'الاختيار بالحبر 700 وليس بالذهبي. كل صف بارتفاع 44 على الأقل وقابل للضغط بعرضه كاملاً.',
  'off': 'إيقاف',
  'on': 'تشغيل',
  'indeterminate': 'مختلط',
  'error': 'خطأ',
  'skeleton': 'هيكل التحميل',
  'skeletonNote': 'شكل ثابت بالحبر 100. لا لمعان ولا تكرار؛ وكشف الصورة هو الحركة الوحيدة.',
  'toasts': 'التنبيه وشريط التراجع',
  'toastsNote': 'شريط حبري ونص بلون الخلفية وإجراء بالذهبي 400. يتناقص خط التراجع خلال ثماني ثوانٍ ويعمل أيضاً مع تقليل الحركة.',
  'toast': 'تنبيه',
  'undo': 'شريط التراجع',
  'region': 'فوق شريط، بفارق 16',
  'rows': 'صف القائمة',
  'rowsNote': 'الحد الأدنى 64 وصف الطابور 80. السهم ينعكس؛ والأسماء تصطف بحرفها الأول.',
  'plainR': 'عنوان وسطر فرعي',
  'withTrail': 'بداية ونهاية وسهم',
  'queue': 'صف الطابور 80',
  'toggleRow': 'مع مفتاح',
  'dangerRow': 'خطر',
  'sectionHeaders': 'رأس القسم',
  'sectionHeadersNote': 'خيط ثم عنوان فرعي اختياري ثم العنوان ثم عرض الكل. عناوين العميل بالسيريف وعناوين الفندق بخط الواجهة.',
  'facts': 'الحقيقة السريعة والوسم',
  'stack': 'متراص',
  'inline': 'في سطر',
  'brand': 'الهوية',
  'brandNote': 'الشعار لا ينعكس أبداً. الخيط ذهبي 500 دائماً ولا يعلو الحروف.',
  'lockup': 'الشعار الكامل',
  'single': 'كتابة واحدة',
  'monograms': 'الحرف المميّز',
  'knots': 'عقد الخيط',
  'beads': 'الخرز',
  'booking': 'حجز 20',
  'compactK': 'مضغوط 12',
  'ended': 'منتهٍ',
  'open': 'مفتوح',
  'now': 'الآن',
  'tied': 'معقود',
  'pop': 'قفزة',
  'guestsLbl': 'المدعوون',
  'sessionLbl': 'الفترة',
  'evening': 'مسائية',
  'hallLbl': 'القاعة',
  'vipLbl': 'صالة كبار الضيوف',
  'nameSample': 'نورة الصباح',
  'venueSample': 'فندق أوريليا الخليج',
  'undoMsg': 'تم سحب الطلب',
  'toastMsg': 'تم الحفظ في قائمتكم',
  'fav': 'إضافة إلى المفضلة',
  'unfav': 'إزالة من المفضلة',
  'compare': 'إضافة إلى المقارنة',
  'areaSample': 'السالمية',
};
// ---------------------------------------------------------------------------------------------------------------- icons
const List<String> _specimenIcons = ['search', 'heart', 'calendar', 'guests', 'pin', 'wallet', 'bell', 'compare'];

Widget _iconTile(BuildContext context, String name, {required bool mirror}) {
  final c = context.gz.colors;
  return Container(
    width: GzSize.touchMin,
    height: GzSize.touchMin,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: c.surfaceQuiet,
      borderRadius: GzRadius.smAll,
      border: Border.all(color: mirror ? c.controlChipBorderSelected : c.scrimClear, width: GzStroke.hair),
    ),
    child: GzIcon.named(name, color: c.iconPrimary),
  );
}

Widget _iconSection(BuildContext context) {
  final c = context.gz.colors;
  final names = GzIcons.byName.keys.where((n) => !n.startsWith('brand-')).toList();
  return _sec(context, _c(context, 'icons'), _c(context, 'iconsNote'), [
    _group(
      context,
      _c(context, 'sizes'),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final size in GzIconSize.values) ...[
            if (size != GzIconSize.xs) const SizedBox(width: GzSpace.s6),
            _cell(context, GzIcon(GzIcons.calendarCheck, size: size, color: c.iconPrimary), cap: size.name),
          ],
        ],
      ),
    ),
    _group(
      context,
      _c(context, 'weights'),
      _row([
        for (final w in ['light', 'regular'])
          _stage(context, [
            _row([for (final n in _specimenIcons) GzIcon.named(n, color: c.iconPrimary)], center: true),
            _caption(context, w),
          ]),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'tones'),
      _row([
        for (final t in GzIconTone.values.where((t) => t != GzIconTone.inherit && t != GzIconTone.onDark))
          _cell(context, GzIcon(GzIcons.checkCircle, tone: t), cap: t.name),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'mirrors'),
      Wrap(spacing: GzSpace.s1, runSpacing: GzSpace.s1, children: [for (final n in GzIcons.mirrorInRtl) _iconTile(context, n, mirror: true)]),
    ),
    _group(
      context,
      _c(context, 'registry'),
      Wrap(spacing: GzSpace.s1, runSpacing: GzSpace.s1, children: [for (final n in names) _iconTile(context, n, mirror: GzIcons.mirrorInRtl.contains(n))]),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- button
Widget _buttonSection(BuildContext context) {
  final l = context.gzL10n;
  final variants = <(GzButtonVariant, String, String)>[
    (GzButtonVariant.primary, _c(context, 'primary'), l.commonActionAccept),
    (GzButtonVariant.secondary, _c(context, 'secondary'), l.commonActionReschedule),
    (GzButtonVariant.tertiary, _c(context, 'tertiary'), l.commonActionSeeAll),
    (GzButtonVariant.destructive, _c(context, 'destructive'), l.commonActionDecline),
  ];
  return _sec(context, _c(context, 'buttons'), _c(context, 'buttonsNote'), [
    _group(
      context,
      _c(context, 'variants'),
      _row([
        for (final (v, cap, label) in variants)
          _cell(context, GzButton(label: label, variant: v, iconStart: v == GzButtonVariant.destructive ? GzIcons.close : null, onPressed: _noop), cap: cap),
      ], center: true),
    ),
    for (final (v, cap, label) in variants)
      _group(
        context,
        '$cap · ${_c(context, 'states')}',
        _row([
          _cell(context, GzButton(label: label, variant: v, onPressed: _noop), cap: _c(context, 'def')),
          _cell(context, GzButton(label: label, variant: v, onPressed: _noop, previewState: GzPreviewState.pressed), cap: _c(context, 'pressed')),
          _cell(context, GzButton(label: label, variant: v, onPressed: _noop, previewState: GzPreviewState.focus), cap: _c(context, 'focus')),
          _cell(context, GzButton(label: label, variant: v), cap: _c(context, 'disabled')),
          _cell(context, GzButton(label: label, variant: v, loading: true), cap: _c(context, 'loading')),
        ], center: true),
      ),
    _group(context, _c(context, 'disabled'), GzButton(label: l.commonActionContinue, fullWidth: true, reason: _c(context, 'reason'))),
    _group(
      context,
      _c(context, 'withIcons'),
      _row([
        _cell(context, GzButton(label: l.commonCalendarAvailability, variant: GzButtonVariant.secondary, iconStart: GzIcons.calendar, onPressed: _noop), cap: _c(context, 'iconStart')),
        _cell(context, GzButton(label: l.commonActionNext, iconEnd: GzIcons.arrowRight, onPressed: _noop), cap: _c(context, 'iconEnd')),
        _cell(context, GzButton(label: l.commonActionSeeAll, variant: GzButtonVariant.tertiary, iconEnd: GzIcons.chevronRight, onPressed: _noop), cap: _c(context, 'iconEnd')),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'heights'),
      _row([
        for (final s in GzButtonSize.values)
          _cell(context, GzButton(label: l.commonActionSave, variant: GzButtonVariant.secondary, size: s, onPressed: _noop), cap: s.name),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'pair'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: GzButton(label: l.commonActionReschedule, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: _noop)),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzButton(label: l.commonActionDecline, variant: GzButtonVariant.secondary, fullWidth: true, onPressed: _noop)),
            ],
          ),
          _vgap(GzSpace.s3),
          GzButton(label: l.commonActionAccept, fullWidth: true, onPressed: _noop),
        ],
      ),
    ),
    _group(context, _c(context, 'loading'), GzButton(label: l.commonActionConfirm, fullWidth: true, onPressed: _noop)),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- icon button
Widget _iconButtonSection(BuildContext context) {
  final l = context.gzL10n;
  return _sec(context, _c(context, 'iconButtons'), _c(context, 'iconButtonsNote'), [
    _group(
      context,
      _c(context, 'variants'),
      _row([
        _cell(context, GzIconButton(icon: GzIcons.share, label: l.commonActionShare, onPressed: _noop), cap: _c(context, 'plain')),
        _cell(context, GzIconButton(icon: GzIcons.back, label: l.commonActionBack, variant: GzIconButtonVariant.outline, onPressed: _noop), cap: _c(context, 'outline')),
        _cell(context, GzIconButton(icon: GzIcons.share, label: l.commonActionShare, onPressed: _noop, previewState: GzPreviewState.pressed), cap: _c(context, 'pressed')),
        _cell(context, GzIconButton(icon: GzIcons.share, label: l.commonActionShare, onPressed: _noop, previewState: GzPreviewState.focus), cap: _c(context, 'focus')),
      ], center: true),
    ),
    _group(
      context,
      '${_c(context, 'overImage')} / ${_c(context, 'overImageLg')} / ${_c(context, 'onScrim')}',
      _photo(
        context,
        start: GzIconButton(icon: GzIcons.compare, label: l.commonA11yCompareRemove, variant: GzIconButtonVariant.overImage, active: true, onPressed: _noop),
        end: Row(
          children: [
            GzIconButton(icon: GzIcons.share, label: l.commonActionShare, variant: GzIconButtonVariant.onScrim, onPressed: _noop),
            const SizedBox(width: GzSpace.s1),
            GzIconButton(
              icon: GzIcons.heart,
              iconActive: GzIcons.heartFill,
              label: l.commonA11yFavouriteAdd,
              variant: GzIconButtonVariant.overImage,
              disk: GzIconButtonDisk.lg,
              active: false,
              onPressed: _noop,
            ),
          ],
        ),
      ),
    ),
    _group(
      context,
      '${_c(context, 'toggle')} · ${_c(context, 'pressed')} · ${_c(context, 'focus')}',
      _photo(
        context,
        start: GzIconButton(icon: GzIcons.heart, iconActive: GzIcons.heartFill, label: l.commonA11yFavouriteAdd, variant: GzIconButtonVariant.overImage, active: false, onPressed: _noop),
        end: Row(
          children: [
            GzIconButton(
              icon: GzIcons.heart,
              iconActive: GzIcons.heartFill,
              label: l.commonA11yFavouriteRemove,
              variant: GzIconButtonVariant.overImage,
              active: true,
              onPressed: _noop,
              previewState: GzPreviewState.pressed,
            ),
            const SizedBox(width: GzSpace.s1),
            GzIconButton(
              icon: GzIcons.heart,
              iconActive: GzIcons.heartFill,
              label: l.commonA11yFavouriteRemove,
              variant: GzIconButtonVariant.overImage,
              active: true,
              onPressed: _noop,
              previewState: GzPreviewState.focus,
            ),
          ],
        ),
      ),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- chips
Widget _chipSection(BuildContext context) {
  final l = context.gzL10n;
  return _sec(context, _c(context, 'chips'), _c(context, 'chipsNote'), [
    _group(
      context,
      _c(context, 'states'),
      _row([
        _cell(context, GzChip(label: l.commonTierWeekday, onPressed: _noop), cap: _c(context, 'def')),
        _cell(context, GzChip(label: l.commonTierWeekend, selected: true), cap: _c(context, 'selected')),
        _cell(context, GzChip(label: l.commonTierHoliday, onPressed: _noop, previewState: GzPreviewState.pressed), cap: _c(context, 'pressed')),
        _cell(context, GzChip(label: l.commonTierSeason, onPressed: _noop, previewState: GzPreviewState.focus), cap: _c(context, 'focus')),
        _cell(context, GzChip(label: l.commonTierSpecialDate, onPressed: _noop, disabled: true), cap: _c(context, 'disabled')),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'variants'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _row([
            GzFilterChip(label: l.commonTierWeekday, selected: false, onToggle: (_) {}),
            GzFilterChip(label: l.commonTierWeekend, selected: true, onToggle: (_) {}),
            GzFilterChip(label: l.commonTierHoliday, selected: false, onToggle: (_) {}),
          ], center: true),
          _vgap(GzSpace.s3),
          _row([
            GzFilterChip(label: l.commonCalendarAvailability, selected: false, menu: true, onToggle: (_) {}),
            GzFilterChip(label: l.commonLabelSettings, selected: true, menu: true, count: 2, onToggle: (_) {}),
            GzChip(label: _c(context, 'areaSample'), iconStart: GzIcons.pin),
          ], center: true),
        ],
      ),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- badges
Widget _badgeSection(BuildContext context) {
  final l = context.gzL10n;
  return _sec(context, _c(context, 'badges'), _c(context, 'badgesNote'), [
    _group(
      context,
      _c(context, 'variants'),
      _row([
        _cell(context, GzBadge(label: l.commonLabelNew), cap: _c(context, 'outlineB')),
        _cell(context, GzBadge(label: l.commonLabelSponsored, variant: GzBadgeVariant.quiet), cap: _c(context, 'quietB')),
      ], center: true),
    ),
    _group(context, _c(context, 'photoB'), _photo(context, start: GzBadge(label: l.commonLabelNew, variant: GzBadgeVariant.photo))),
    _group(
      context,
      _c(context, 'counts'),
      _row([
        _cell(context, const GzCountBadge(count: 1), cap: '1'),
        _cell(context, const GzCountBadge(count: 12), cap: '12'),
        _cell(context, const GzCountBadge(count: 140), cap: '99+'),
        _cell(context, const GzCountBadge(count: 3, tone: GzCountTone.danger), cap: _c(context, 'danger')),
        _cell(
          context,
          SizedBox.square(
            dimension: GzSize.iconLg,
            child: Stack(
              alignment: Alignment.center,
              children: [
                GzIcon(GzIcons.chat, color: context.gz.colors.iconPrimary),
                const PositionedDirectional(top: 0, end: 0, child: GzCountBadge(count: 2, ring: true)),
              ],
            ),
          ),
          cap: _c(context, 'ring'),
        ),
      ], center: true),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- status pills
const List<(GzStatus, String)> _booking = [
  (GzStatus.pending, 'pending'),
  (GzStatus.approved, 'approved'),
  (GzStatus.confirmed, 'confirmed'),
  (GzStatus.redeemed, 'redeemed'),
  (GzStatus.completed, 'completed'),
  (GzStatus.declined, 'declined'),
  (GzStatus.expired, 'expired'),
  (GzStatus.cancelled, 'cancelled'),
];
const List<(GzStatus, String)> _partner = [
  (GzStatus.pending, 'pending'),
  (GzStatus.approved, 'approved'),
  (GzStatus.redeemed, 'redeemed'),
  (GzStatus.declined, 'declined'),
  (GzStatus.expired, 'expired'),
];
const List<(GzStatus, String)> _beside = [
  (GzStatus.dateProposed, 'date_proposed'),
  (GzStatus.missed, 'missed'),
  (GzStatus.lapsed, 'lapsed'),
  (GzStatus.urgent, 'urgent'),
];
const List<(GzStatus, String)> _voucher = [
  (GzStatus.voucherUnpaid, 'voucher_unpaid'),
  (GzStatus.voucherActive, 'voucher_active'),
  (GzStatus.voucherBound, 'voucher_bound'),
  (GzStatus.voucherUsed, 'voucher_used'),
  (GzStatus.voucherExpired, 'voucher_expired'),
  (GzStatus.voucherForfeited, 'voucher_forfeited'),
  (GzStatus.voucherCreditIssued, 'voucher_credit_issued'),
  (GzStatus.voucherCredit, 'voucher_credit'),
];
const List<(GzStatus, String)> _visit = [
  (GzStatus.visitRequested, 'visit_requested'),
  (GzStatus.visitConfirmed, 'visit_confirmed'),
  (GzStatus.visitReschedule, 'visit_reschedule'),
  (GzStatus.visitArrived, 'visit_arrived'),
  (GzStatus.visitCompleted, 'visit_completed'),
  (GzStatus.visitDeclined, 'visit_declined'),
  (GzStatus.visitCancelled, 'visit_cancelled'),
  (GzStatus.visitMissed, 'visit_missed'),
];
const List<(GzStatus, String)> _listing = [
  (GzStatus.listingDraft, 'listing_draft'),
  (GzStatus.listingPayment, 'listing_payment'),
  (GzStatus.listingReview, 'listing_review'),
  (GzStatus.listingApproved, 'listing_approved'),
  (GzStatus.listingRejected, 'listing_rejected'),
  (GzStatus.listingActive, 'listing_active'),
  (GzStatus.listingExpired, 'listing_expired'),
  (GzStatus.listingPaused, 'listing_paused'),
];
const List<(GzStatus, String)> _avail = [
  (GzStatus.available, 'available'),
  (GzStatus.held, 'held'),
  (GzStatus.booked, 'booked'),
  (GzStatus.blocked, 'blocked'),
  (GzStatus.unavailable, 'unavailable'),
  (GzStatus.past, 'past'),
];

Widget _pillSection(BuildContext context) {
  Widget list(List<(GzStatus, String)> items, {GzStatusAudience audience = GzStatusAudience.client}) =>
      _row([for (final (s, cap) in items) _cell(context, GzStatusPill(status: s, audience: audience), cap: cap)]);
  return _sec(context, _c(context, 'pills'), _c(context, 'pillsNote'), [
    _group(context, _c(context, 'client'), list(_booking)),
    _group(context, _c(context, 'hotel'), list(_partner, audience: GzStatusAudience.hotel)),
    _group(context, _c(context, 'also'), list(_beside, audience: GzStatusAudience.hotel)),
    _group(context, _c(context, 'vouchers'), list(_voucher)),
    _group(context, _c(context, 'visits'), list(_visit)),
    _group(context, _c(context, 'listings'), list(_listing, audience: GzStatusAudience.hotel)),
    _group(context, _c(context, 'availability'), list(_avail)),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- avatar
Widget _avatarSection(BuildContext context) {
  return _sec(context, _c(context, 'avatars'), _c(context, 'avatarsNote'), [
    _group(
      context,
      _c(context, 'serif'),
      _row([
        for (final s in GzAvatarSize.values) _cell(context, GzAvatar(name: _c(context, 'nameSample'), size: s), cap: s.name),
        _cell(context, const GzAvatar(name: 'غادة'), cap: 'غ'),
      ], center: true),
    ),
    _group(
      context,
      _c(context, 'sans'),
      _row([
        for (final s in GzAvatarSize.values) _cell(context, GzAvatar(name: _c(context, 'venueSample'), size: s, voice: GzAvatarVoice.sans), cap: s.name),
      ], center: true),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- rating
Widget _ratingSection(BuildContext context) {
  return _sec(context, _c(context, 'ratings'), _c(context, 'ratingsNote'), [
    _row([
      _cell(context, const GzRating(value: 4.8), cap: 'compact'),
      _cell(context, const GzRating(value: 4.8, count: 212), cap: '+ count'),
      _cell(context, const GzRating(variant: GzRatingVariant.stars, value: 4.3, count: 86), cap: 'stars'),
      _cell(context, const GzRating(variant: GzRatingVariant.stars, value: 3.5), cap: 'stars'),
    ], center: true),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- price
Widget _priceSection(BuildContext context) {
  final l = context.gzL10n;
  return _sec(context, _c(context, 'prices'), _c(context, 'pricesNote'), [
    _group(
      context,
      '${_c(context, 'browse')} · ${_c(context, 'exact')}',
      _stage(context, [
        _row([
          _cell(context, const GzPrice(fils: 18200000), cap: _c(context, 'browse')),
          _cell(context, const GzPrice(fils: 18500), cap: '${_c(context, 'browse')} · fils'),
          _cell(context, const GzPrice(fils: 5460000, mode: GzMoneyMode.exact), cap: _c(context, 'exact')),
          _cell(context, const GzPrice(fils: 5460500, mode: GzMoneyMode.exact), cap: _c(context, 'exact')),
        ], center: true),
      ]),
    ),
    _group(
      context,
      _c(context, 'sizesP'),
      _stage(context, [
        _cell(context, const GzPrice(fils: 18200000), cap: 'card 17 / 500'),
        _cell(context, const GzPrice(fils: 18200000, size: GzPriceSize.strong), cap: 'strong 17 / 600'),
        _cell(context, const GzPrice(fils: 5460000, size: GzPriceSize.total, mode: GzMoneyMode.exact), cap: 'total 22 / 600 · exact'),
        _cell(context, const GzPrice(fils: 18200000, size: GzPriceSize.kpi), cap: 'kpi 32 / 600'),
        _cell(context, const GzPrice(fils: 46000, size: GzPriceSize.display), cap: 'display d1'),
        _cell(context, const GzPrice(fils: 16100000, size: GzPriceSize.hero), cap: 'hero d3'),
      ]),
    ),
    _group(
      context,
      _c(context, 'unitsP'),
      _stage(context, [
        _cell(context, const GzPrice(fils: 46000, unit: GzPriceUnit.perGuest), cap: l.commonUnitPerGuest),
        _cell(context, const GzPrice(fils: 2800000, unit: GzPriceUnit.perNight, size: GzPriceSize.strong), cap: l.commonUnitPerNight),
        _cell(context, const GzPrice(fils: 42000, was: 46000, unit: GzPriceUnit.perGuest), cap: 'was'),
      ]),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- dividers and thread rules
Widget _threadSection(BuildContext context) {
  return _sec(context, _c(context, 'threads'), _c(context, 'threadsNote'), [
    _group(
      context,
      '${_c(context, 'hairline')} / ${_c(context, 'strong')}',
      _stage(context, [const GzDivider(), const GzDivider(tone: GzDividerTone.strong)]),
    ),
    _group(
      context,
      '${_c(context, 'khayt')} / ${_c(context, 'full')} / ${_c(context, 'knotV')}',
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stage(context, [
            const Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
            const GzThreadRule(variant: GzThreadRuleVariant.full, draw: GzDraw.off),
            const GzThreadRule(variant: GzThreadRuleVariant.knot, draw: GzDraw.off),
          ]),
          _vgap(GzSpace.s3),
          _replay(context),
        ],
      ),
    ),
    _group(
      context,
      _c(context, 'onInk'),
      _stage(context, [const GzDivider(tone: GzDividerTone.onDark), const GzThreadRule(variant: GzThreadRuleVariant.knot, draw: GzDraw.off)], kind: _Stage.ink),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- switch, checkbox, radio
Widget _controlSection(BuildContext context) {
  final l = context.gzL10n;
  final name = l.commonA11yFavouriteAdd;
  return _sec(context, _c(context, 'controls'), _c(context, 'controlsNote'), [
    _group(
      context,
      'Switch · ${_c(context, 'off')} / ${_c(context, 'on')} / ${_c(context, 'pressed')} / ${_c(context, 'focus')} / ${_c(context, 'disabled')}',
      _row([
        _cell(context, GzSwitch(label: name), cap: _c(context, 'off')),
        _cell(context, GzSwitch(label: name, defaultChecked: true), cap: _c(context, 'on')),
        _cell(context, GzSwitch(label: name, previewState: GzPreviewState.pressed), cap: _c(context, 'pressed')),
        _cell(context, GzSwitch(label: name, defaultChecked: true, previewState: GzPreviewState.focus), cap: _c(context, 'focus')),
        _cell(context, GzSwitch(label: name, disabled: true), cap: _c(context, 'disabled')),
        _cell(context, GzSwitch(label: name, disabled: true, defaultChecked: true), cap: '${_c(context, 'disabled')} · ${_c(context, 'on')}'),
      ], center: true),
    ),
    _group(
      context,
      'Checkbox',
      _stage(context, [
        GzCheckbox(label: l.commonAvailabilityFree),
        GzCheckbox(label: l.commonAvailabilityHeld, defaultChecked: true),
        GzCheckbox(label: _c(context, 'indeterminate'), indeterminate: true),
        GzCheckbox(label: _c(context, 'pressed'), previewState: GzPreviewState.pressed),
        GzCheckbox(label: _c(context, 'focus'), defaultChecked: true, previewState: GzPreviewState.focus),
        GzCheckbox(label: l.commonAvailabilityUnavailable, disabled: true),
        GzCheckbox(label: l.commonAvailabilityBooked, disabled: true, defaultChecked: true),
        GzCheckbox(label: l.commonLabelRequired, error: l.commonFieldRequired),
      ]),
    ),
    _group(
      context,
      'Radio',
      _stage(context, [
        GzRadioGroup<String>(
          label: l.commonMoneyDeposit,
          defaultValue: 'deposit',
          children: [
            GzRadio<String>(value: 'deposit', label: l.commonMoneyDeposit),
            GzRadio<String>(value: 'balance', label: l.commonMoneyBalance),
            GzRadio<String>(value: 'total', label: l.commonMoneyTotal),
            GzRadio<String>(value: 'never', label: l.commonAvailabilityUnavailable, disabled: true),
          ],
        ),
        GzRadio<String>(value: 'x', label: _c(context, 'focus'), checked: true, previewState: GzPreviewState.focus),
        GzRadio<String>(value: 'y', label: _c(context, 'pressed'), previewState: GzPreviewState.pressed),
      ]),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- skeleton
Widget _skeletonSection(BuildContext context) {
  return _sec(context, _c(context, 'skeleton'), _c(context, 'skeletonNote'), [
    _stage(context, [
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 160),
          _vgap(GzSpace.s3),
          const Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.circle, inlineSize: 40),
              SizedBox(width: GzSpace.s3),
              GzSkeleton(blockSize: 20, grow: true),
            ],
          ),
          _vgap(GzSpace.s3),
          const GzSkeletonText(lines: 3, lastLine: 160),
        ],
      ),
    ]),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- toast and undo
Widget _toastSection(BuildContext context) {
  final l = context.gzL10n;
  Widget stack(List<Widget> items) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) _vgap(GzSpace.s3), items[i]],
        ],
      );
  return _sec(context, _c(context, 'toasts'), _c(context, 'toastsNote'), [
    _group(
      context,
      _c(context, 'toast'),
      stack([
        GzToast(message: _c(context, 'toastMsg'), icon: GzIcons.checkCircle, actionLabel: l.commonActionUndo, onAction: _noop),
        GzToast(message: l.commonStateOffline, icon: GzIcons.offline),
        GzToast(message: _c(context, 'toastMsg'), actionLabel: l.commonActionUndo, onAction: _noop, previewState: GzPreviewState.pressed),
      ]),
    ),
    _group(
      context,
      _c(context, 'undo'),
      stack([
        GzUndoBar(message: _c(context, 'undoMsg'), duration: _depleted),
        // The web UndoBar's focus preview draws no ring (its button has no data-gz anchor), so none is previewed here either.
        GzUndoBar(message: _c(context, 'undoMsg'), duration: _depleted),
        _replay(context),
      ]),
    ),
    _group(
      context,
      _c(context, 'region'),
      Container(
        height: GzSpace.s24,
        decoration: BoxDecoration(color: context.gz.colors.surfaceQuiet, borderRadius: GzRadius.mdAll),
        child: Stack(children: [GzToastRegion(child: GzUndoBar(message: _c(context, 'undoMsg'), duration: _depleted))]),
      ),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- list row
Widget _rowSection(BuildContext context) {
  final l = context.gzL10n;
  final c = context.gz.colors;
  final f = context.gzFormat;
  final sub = '${_c(context, 'areaSample')} · ${l.commonCountGuests(350)}';
  return _sec(context, _c(context, 'rows'), _c(context, 'rowsNote'), [
    _stage(context, [
      _group(context, _c(context, 'plainR'), GzListRow(flush: true, title: l.commonLabelLanguage, subtitle: l.commonLabelKuwaitTime)),
      _group(
        context,
        _c(context, 'withTrail'),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzListRow(
              flush: true,
              chevron: true,
              onPressed: _noop,
              leading: GzIcon(GzIcons.globe, color: c.iconSecondary),
              title: l.commonLabelLanguage,
              trailing: GzText(l.commonLanguageEnglish, role: GzTextRole.bodyS, color: c.textSecondary),
            ),
            _vgap(GzSpace.s3),
            GzListRow(
              flush: true,
              chevron: true,
              onPressed: _noop,
              leading: GzIcon(GzIcons.wallet, color: c.iconSecondary),
              title: l.commonMoneyDeposit,
              subtitle: l.commonStatusAwaitingDeposit,
              trailing: const GzPrice(fils: 5460000, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
            ),
          ],
        ),
      ),
      _group(
        context,
        _c(context, 'queue'),
        GzListRow(
          flush: true,
          size: GzListRowSize.queue,
          chevron: true,
          onPressed: _noop,
          autoDir: true,
          leading: GzAvatar(name: _c(context, 'nameSample'), size: GzAvatarSize.sm, voice: GzAvatarVoice.sans),
          title: _c(context, 'nameSample'),
          subtitle: sub,
          trailing: const GzPrice(fils: 16100000, size: GzPriceSize.strong),
        ),
      ),
      _group(
        context,
        '${_c(context, 'pressed')} / ${_c(context, 'selected')} / ${_c(context, 'focus')}',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzListRow(flush: true, chevron: true, onPressed: _noop, previewState: GzPreviewState.pressed, title: l.commonActionEdit),
            _vgap(GzSpace.s3),
            GzListRow(flush: true, chevron: true, onPressed: _noop, selected: true, title: l.commonActionShare),
            _vgap(GzSpace.s3),
            GzListRow(flush: true, chevron: true, onPressed: _noop, previewState: GzPreviewState.focus, title: l.commonActionMessage),
          ],
        ),
      ),
      _group(
        context,
        _c(context, 'toggleRow'),
        GzListRow(flush: true, title: l.commonCalendarPeak, subtitle: f.number(3), trailing: GzSwitch(label: l.commonCalendarPeak, checked: true, onChanged: (_) {})),
      ),
      _group(
        context,
        _c(context, 'dangerRow'),
        GzListRow(flush: true, last: true, tone: GzListRowTone.danger, onPressed: _noop, leading: GzIcon(GzIcons.trash, color: c.iconDanger), title: l.commonActionRemove),
      ),
    ]),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- section header
Widget _headerSection(BuildContext context) {
  final l = context.gzL10n;
  final f = context.gzFormat;
  return _sec(context, _c(context, 'sectionHeaders'), _c(context, 'sectionHeadersNote'), [
    _group(
      context,
      _c(context, 'variants'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GzSectionHeader(title: l.commonCountHalls(38), draw: GzDraw.off, onSeeAll: _noop),
          _vgap(GzSpace.s3),
          GzSectionHeader(title: _c(context, 'venueSample'), eyebrow: _c(context, 'areaSample'), draw: GzDraw.off),
          _vgap(GzSpace.s3),
          GzSectionHeader(
            voice: GzHeaderVoice.partner,
            title: l.commonCountRequests(3),
            draw: GzDraw.off,
            onSeeAll: _noop,
            seeAllLabel: '${l.commonActionSeeAll} ${f.integer(3)}',
          ),
        ],
      ),
    ),
    _replay(context),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- key fact and tag
Widget _factSection(BuildContext context) {
  final l = context.gzL10n;
  final f = context.gzFormat;
  return _sec(context, _c(context, 'facts'), null, [
    _group(
      context,
      _c(context, 'stack'),
      _stage(context, [
        _row([
          GzKeyFact(icon: GzIcons.guests, label: _c(context, 'guestsLbl'), value: f.integer(350)),
          GzKeyFact(icon: GzIcons.clock, label: _c(context, 'sessionLbl'), value: _c(context, 'evening')),
          GzKeyFact(icon: GzIcons.hall, label: _c(context, 'hallLbl'), value: _c(context, 'venueSample')),
        ]),
      ]),
    ),
    _group(
      context,
      _c(context, 'inline'),
      _stage(context, [
        GzKeyFact(
          layout: GzFactLayout.inline,
          icon: GzIcons.wallet,
          label: l.commonMoneyDeposit,
          valueWidget: const GzPrice(fils: 5460000, mode: GzMoneyMode.exact, size: GzPriceSize.strong),
        ),
      ]),
    ),
    _group(
      context,
      'Tag',
      _row([
        GzTag(icon: GzIcons.valet, label: l.commonLabelOptional),
        GzTag(icon: GzIcons.sound, label: _c(context, 'vipLbl')),
        GzTag(icon: GzIcons.staff, label: l.commonLabelNew),
        GzTag(label: _c(context, 'areaSample')),
      ]),
    ),
  ]);
}

// ---------------------------------------------------------------------------------------------------------------- brand
Widget _brandSection(BuildContext context) {
  Widget knots(List<(Widget, String)> items) => Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[if (i > 0) const SizedBox(width: GzSpace.s3), _cell(context, items[i].$1, cap: items[i].$2)],
        ],
      );
  return _sec(context, _c(context, 'brand'), _c(context, 'brandNote'), [
    _group(
      context,
      _c(context, 'lockup'),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final s in GzWordmarkSize.values) ...[
            if (s != GzWordmarkSize.sm) _vgap(GzSpace.s6),
            _cell(context, GzWordmark(size: s), cap: s.name),
          ],
          _vgap(GzSpace.s3),
          _replay(context),
        ],
      ),
    ),
    _group(
      context,
      _c(context, 'single'),
      _row([
        _cell(context, const GzWordmark(size: GzWordmarkSize.lg, script: GzWordmarkScript.latin), cap: 'latin'),
        _cell(context, const GzWordmark(size: GzWordmarkSize.lg, script: GzWordmarkScript.arabic), cap: 'arabic'),
      ], center: true),
    ),
    _group(context, _c(context, 'onInk'), _stage(context, [const GzWordmark(size: GzWordmarkSize.lg, onDark: true)], kind: _Stage.ink)),
    _group(
      context,
      _c(context, 'monograms'),
      _row([
        for (final s in GzMonogramSize.values) _cell(context, GzMonogram(size: s), cap: s.name),
        _cell(context, const GzMonogram(size: GzMonogramSize.lg, form: GzMonogramForm.tile), cap: 'tile'),
        _cell(context, const GzMonogram(size: GzMonogramSize.lg, form: GzMonogramForm.tile, script: GzMonogramScript.arabic), cap: 'arabic'),
        _cell(context, const GzMonogram(size: GzMonogramSize.lg, form: GzMonogramForm.tile, script: GzMonogramScript.latin), cap: 'latin'),
      ], center: true),
    ),
    _group(
      context,
      '${_c(context, 'knots')} · ${_c(context, 'booking')}',
      _stage(context, [
        knots([
          (const GzThreadKnot(state: GzKnotState.open), _c(context, 'open')),
          (const GzThreadKnot(state: GzKnotState.now), _c(context, 'now')),
          (const GzThreadKnot(state: GzKnotState.tied), _c(context, 'tied')),
          (const GzThreadKnot(state: GzKnotState.ended, endedIcon: GzIcons.close, endedTone: GzKnotEndedTone.danger), 'x'),
          (const GzThreadKnot(state: GzKnotState.ended, endedIcon: GzIcons.clock, endedTone: GzKnotEndedTone.neutral), 'clock'),
          (const GzThreadKnot(state: GzKnotState.ended, endedIcon: GzIcons.undo, endedTone: GzKnotEndedTone.rose), 'undo'),
          (const GzThreadKnot(state: GzKnotState.ended, endedIcon: GzIcons.userMinus, endedTone: GzKnotEndedTone.dangerOutline), 'user'),
        ]),
      ]),
    ),
    _group(
      context,
      '${_c(context, 'knots')} · ${_c(context, 'compactK')}',
      _stage(context, [
        knots([
          (const GzThreadKnot(size: GzKnotSize.compact, state: GzKnotState.open), _c(context, 'open')),
          (const GzThreadKnot(size: GzKnotSize.compact, state: GzKnotState.now), _c(context, 'now')),
          (const GzThreadKnot(size: GzKnotSize.compact, state: GzKnotState.tied), _c(context, 'tied')),
          (const GzThreadKnot(state: GzKnotState.tied, pop: true), _c(context, 'pop')),
        ]),
      ]),
    ),
    _group(
      context,
      '${_c(context, 'knots')} · ${_c(context, 'onInk')}',
      _stage(context, [
        knots([
          (const GzThreadKnot(onDark: true, state: GzKnotState.open), _c(context, 'open')),
          (const GzThreadKnot(onDark: true, state: GzKnotState.now), _c(context, 'now')),
          (const GzThreadKnot(onDark: true, state: GzKnotState.tied), _c(context, 'tied')),
          (const GzThreadKnot(onDark: true, state: GzKnotState.ended, endedTone: GzKnotEndedTone.danger), 'x'),
        ]),
      ], kind: _Stage.ink),
    ),
    _group(
      context,
      _c(context, 'beads'),
      _row([
        _cell(context, const GzThreadBead(), cap: 'gold'),
        _cell(context, const GzThreadBead(tone: GzBeadTone.ink), cap: 'ink'),
        _cell(context, const GzThreadBead(tone: GzBeadTone.hollow), cap: 'hollow'),
      ], center: true),
    ),
  ]);
}
