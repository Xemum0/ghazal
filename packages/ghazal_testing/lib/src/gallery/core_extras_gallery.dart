// Sections the web core gallery does not have: the options added in the F3 component wave (KIT-U2). Numbers from 51: never paired with a
// web reference. Measured by packages/ghazal_ui/test/core/rows_test.dart. Literals are allowed here (galleries are exempt).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'gz_gallery.dart';

/// The extra sections of the core gallery (appended to `coreGallerySections`).
List<GzGallerySection> coreExtrasGallerySections() => [
      GzGallerySection('rows-flush', _rows, number: 51),
      GzGallerySection('struck-money', _struck, number: 52),
    ];

String _p(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _label(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(top: GzSpace.s6, bottom: GzSpace.s2),
      child: GzText(text, role: GzTextRole.caption, color: context.gz.colors.textSecondary),
    );

Widget _rows(BuildContext context) {
  String p(String en, String ar) => _p(context, en, ar);
  final c = context.gz.colors;
  Widget panel(List<Widget> rows) => DecoratedBox(
        decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.mdAll, border: Border.all(color: c.borderHairline, width: GzStroke.hair)),
        child: Padding(padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s4), child: Column(children: rows)),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _label(context, 'GzListRow flush, interactive: square, the hairline runs straight to both ends'),
      panel([
        GzListRow(flush: true, title: p('Date', 'التاريخ'), subtitle: p('Thursday 14 January', 'الخميس 14 يناير'), onPressed: () {}),
        GzListRow(flush: true, last: true, title: p('Guests', 'عدد الضيوف'), trailing: GzText('350', role: GzTextRole.bodyS), onPressed: () {}, chevron: true),
      ]),
      _label(context, 'GzIconListRow flush'),
      panel([
        GzIconListRow(flush: true, icon: GzIcons.calendar, title: p('Request a date', 'اطلبوا تاريخًا'), onPressed: () {}),
        GzIconListRow(flush: true, last: true, icon: GzIcons.user, title: p('Your details', 'بياناتكم'), onPressed: () {}),
      ]),
    ],
  );
}

Widget _struck(BuildContext context) {
  final c = context.gz.colors;
  Widget row(String label, Widget money) => Padding(
        padding: const EdgeInsets.only(bottom: GzSpace.s3),
        child: Row(children: [Expanded(child: GzText(label, role: GzTextRole.caption, color: c.textSecondary)), money]),
      );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      row('browse, figBodyS', const GzStruckMoney(fils: 18200000)),
      row('browse, figCaption', const GzStruckMoney(fils: 18200000, role: GzTextRole.figCaption)),
      row('exact (Review)', const GzStruckMoney(fils: 18200000, mode: GzMoneyMode.exact, arabicFigureFirst: true)),
      row('exact, Money order', const GzStruckMoney(fils: 5460500, mode: GzMoneyMode.exact)),
    ],
  );
}
