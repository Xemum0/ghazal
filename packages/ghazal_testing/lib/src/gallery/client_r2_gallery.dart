// Client gallery, round 2 (ADR 0038): the sex choice of sign-up (CL-AUTH-03) and of Personal info (CL-PROF-03). The web has no gallery
// section for it (it lives inside the screens), so this one has no reference render: its numbers are proven by
// packages/ghazal_ui/test/client/round2_test.dart against `pnpm probe --screen CL-AUTH-03` and the section is read by eye in both
// languages. It takes the number after the last web section (26) so a web twin, if one is added, replaces it. The provider note
// shares the web `vendor-card` section (client_c_gallery.dart).
// ghazal_testing may hold string literals (tests and galleries are exempt from the no-text-literal rule).
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Sex;
import 'package:ghazal_ui/src/client/client_r2.dart';
import 'package:ghazal_ui/src/core/core.dart';
import 'package:ghazal_ui/src/foundation.dart';

import 'gz_gallery.dart';

List<GzGallerySection> clientR2GallerySections() => [GzGallerySection('sex-choice', _sexChoice, number: 26)];

String _t(BuildContext context, String en, String ar) => context.gz.isAr ? ar : en;

Widget _spec(BuildContext context, String state, List<Widget> children) {
  final gz = context.gz;
  final c = gz.colors;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Text(state, style: gz.text(GzTextRole.caption).copyWith(color: c.textSecondary, fontWeight: gz.text(GzTextRole.title).fontWeight, decoration: TextDecoration.none)),
      ),
      const SizedBox(height: GzSpace.s3),
      for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s6), children[i]],
    ],
  );
}

/// A controlled specimen that keeps its own choice, like the screen does.
class _Pick extends StatefulWidget {
  const _Pick({required this.initial, required this.builder});

  final Sex? initial;
  final Widget Function(Sex? value, ValueChanged<Sex> set) builder;

  @override
  State<_Pick> createState() => _PickState();
}

class _PickState extends State<_Pick> {
  late Sex? _value = widget.initial;

  @override
  Widget build(BuildContext context) => widget.builder(_value, (v) => setState(() => _value = v));
}

Widget _sexChoice(BuildContext context) {
  String t(String en, String ar) => _t(context, en, ar);
  final c = context.gz.colors;
  Widget tiles({Sex? value, String? error, bool disabled = false}) => _Pick(
    initial: value,
    builder: (v, set) => GzSexChoice(
      value: v,
      label: t('Sex', 'الجنس'),
      femaleLabel: t('Female', 'أنثى'),
      maleLabel: t('Male', 'ذكر'),
      onChanged: set,
      error: error,
      disabled: disabled,
    ),
  );
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Align(alignment: AlignmentDirectional.centerStart, child: GzThreadRule(draw: GzDraw.off)),
      const SizedBox(height: GzSpace.s2),
      GzText(t('Sex choice', 'اختيار الجنس'), role: GzTextRole.d2, color: c.textStrong, header: true),
      const SizedBox(height: GzSpace.s2),
      GzText(
        t(
          'Female or male as two large tiles with the registry’s abstract gender symbols; the chosen tile shows an ink check on its own disk, never colour alone. Required at sign-up, editable in Personal info as a glyph switch.',
          'أنثى أو ذكر في بلاطتين كبيرتين برمزين مجرّدين من السجل؛ تُظهر البلاطة المختارة علامة صح حبرية على قرصها، ولا يُكتفى باللون أبدًا. مطلوب عند التسجيل، ويُعدَّل في المعلومات الشخصية بمفتاح رموز.',
        ),
        role: GzTextRole.bodyS,
        color: c.textSecondary,
      ),
      const SizedBox(height: GzSpace.s5),
      _spec(context, t('Nothing chosen yet · female chosen · male chosen', 'لا اختيار بعد · أنثى مختارة · ذكر مختار'), [
        tiles(),
        tiles(value: Sex.female),
        tiles(value: Sex.male),
      ]),
      const SizedBox(height: GzSpace.s8),
      _spec(context, t('Required and empty: the error border and the message', 'مطلوب وفارغ: إطار الخطأ والرسالة'), [tiles(error: t('Required', 'مطلوب'))]),
      const SizedBox(height: GzSpace.s8),
      _spec(context, t('Disabled while the account is created', 'معطّل أثناء إنشاء الحساب'), [tiles(value: Sex.female, disabled: true)]),
      const SizedBox(height: GzSpace.s8),
      _spec(context, t('Personal info · the glyph switch', 'المعلومات الشخصية · مفتاح الرموز'), [
        _Pick(
          initial: Sex.female,
          builder: (v, set) => GzSexChoice.switcher(
            value: v,
            label: t('Sex', 'الجنس'),
            femaleLabel: t('Female', 'أنثى'),
            maleLabel: t('Male', 'ذكر'),
            onChanged: set,
          ),
        ),
      ]),
    ],
  );
}
