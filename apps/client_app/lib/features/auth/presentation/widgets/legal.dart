import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/widgets.dart';
import 'package:ghazal_core/ghazal_core.dart' show parseRichTags;
import 'package:ghazal_ui/ghazal_ui.dart';

enum LegalKind { terms, privacy }

/// The legal pages open in-app (CA-AUTH-11). The texts come from the Super Admin CMS; until then the sections are headings as icon rows.
/// The terms carry the voucher section (ADR 0033), so one reader holds both.
void openLegal(BuildContext context, LegalKind kind) {
  final l10n = context.l10n;
  final c = context.gz.colors;
  final rows = kind == LegalKind.terms
      ? <(IconData, String)>[
          (GzIcons.document, l10n.clientAuthSharedTermsSection1),
          (GzIcons.ticket, l10n.clientAuthSharedTermsSection2),
          (GzIcons.receipt, l10n.clientAuthSharedTermsSection3),
          (GzIcons.shieldCheck, l10n.clientAuthSharedTermsSection4),
        ]
      : <(IconData, String)>[
          (GzIcons.clipboard, l10n.clientAuthSharedPrivacySection1),
          (GzIcons.sliders, l10n.clientAuthSharedPrivacySection2),
          (GzIcons.eye, l10n.clientAuthSharedPrivacySection3),
          (GzIcons.settings, l10n.clientAuthSharedPrivacySection4),
        ];
  showGzSheet<void>(
    context,
    title: kind == LegalKind.terms ? l10n.clientAuthSharedLegalTerms : l10n.clientAuthSharedLegalPrivacy,
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) GzIconListRow(flush: true, icon: rows[i].$1, title: rows[i].$2, last: i == rows.length - 1),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s4),
          child: GzText(l10n.clientAuthSharedLegalNote, role: GzTextRole.caption, color: c.textSecondary),
        ),
      ],
    ),
  );
}

/// The info glyph and its sheet (web `LegalInfo`): optional [body] paragraphs, then (unless [rows] is off) Terms of Use and Privacy Policy
/// as two rows that open the legal reader. Legal consent never sits on the screen as a paragraph.
class AuthLegalInfo extends StatelessWidget {
  const AuthLegalInfo({required this.title, this.body, this.rows = true, super.key});

  final String title;
  final WidgetBuilder? body;
  final bool rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return GzIconButton(
      icon: GzIcons.info,
      iconSize: GzIconSize.sm,
      label: l10n.commonA11yInfo,
      onPressed: () => showGzSheet<void>(
        context,
        title: title,
        builder: (sheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (body != null) body!(sheet),
            if (rows) ...[
              GzIconListRow(flush: true, icon: GzIcons.document, title: l10n.clientAuthSharedLegalTerms, onPressed: () => _read(context, sheet, LegalKind.terms)),
              GzIconListRow(flush: true, icon: GzIcons.shieldCheck, title: l10n.clientAuthSharedLegalPrivacy, last: true, onPressed: () => _read(context, sheet, LegalKind.privacy)),
            ],
          ],
        ),
      ),
    );
  }

  void _read(BuildContext root, BuildContext sheet, LegalKind kind) {
    Navigator.of(sheet).pop();
    openLegal(root, kind);
  }
}

/// The small print with its two links: `Our <terms>Terms of Use</terms> and <privacy>Privacy Policy</privacy> apply.` Each link closes the
/// sheet it sits in and opens the legal reader.
class AuthSmallPrint extends StatefulWidget {
  const AuthSmallPrint({required this.sheetContext, required this.parentContext, super.key});

  final BuildContext sheetContext;
  final BuildContext parentContext;

  @override
  State<AuthSmallPrint> createState() => _AuthSmallPrintState();
}

class _AuthSmallPrintState extends State<AuthSmallPrint> {
  final List<TapGestureRecognizer> _taps = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final t in _taps) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final base = context.gz.text(GzTextRole.body).copyWith(color: c.textPrimary);
    for (final t in _taps) {
      t.dispose();
    }
    _taps.clear();
    final spans = <InlineSpan>[];
    for (final part in parseRichTags(context.l10n.clientAuthSharedSmallPrint)) {
      final kind = part.tag == 'terms' ? LegalKind.terms : (part.tag == 'privacy' ? LegalKind.privacy : null);
      if (kind == null) {
        spans.add(TextSpan(text: part.text));
        continue;
      }
      final tap = TapGestureRecognizer()
        ..onTap = () {
          Navigator.of(widget.sheetContext).pop();
          openLegal(widget.parentContext, kind);
        };
      _taps.add(tap);
      spans.add(TextSpan(text: part.text, recognizer: tap, style: base.copyWith(color: c.textGoldInk, decoration: TextDecoration.underline)));
    }
    return GzText.rich(TextSpan(children: spans), role: GzTextRole.body, color: c.textPrimary);
  }
}
