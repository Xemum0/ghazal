// WhatCouplesSee (web `WhatCouplesSee.tsx`): the live preview of the listing as a registered client sees it: the title in the client's language,
// the category and the first package with its two prices (the voucher price leads when one is offered). It reads the editor's draft, so every
// keystroke shows. A package without a valid voucher price shows the standard price only, as a client would see it.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/listing_draft.dart';

class WhatCouplesSee extends StatelessWidget {
  const WhatCouplesSee({required this.draft, required this.feeFils, this.category, super.key});

  final ListingDraft draft;
  final int feeFils;
  final LocalizedText? category;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    final title = draft.titleIn(lang);
    final first = draft.packages.where((p) => p.standardFils != null && p.standardFils! > 0).firstOrNull;
    return Semantics(
      container: true,
      label: l.hotelProviderPreviewTitle,
      child: Container(
        padding: GzSpace.panel,
        decoration: BoxDecoration(color: c.surfaceTint, borderRadius: GzRadius.mdAll),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              GzIcon(GzIcons.eye, size: GzIconSize.sm, color: c.iconSecondary),
              const SizedBox(width: GzSpace.s2),
              GzText(l.hotelProviderPreviewTitle, role: GzTextRole.label, color: c.textSecondary),
            ]),
            const SizedBox(height: GzSpace.s2),
            if (title.isNotEmpty) GzUserText(title, role: GzTextRole.title, color: c.textStrong) else GzText(l.hotelProviderPreviewNoTitle, role: GzTextRole.bodyS, color: c.textSecondary),
            if (category != null) ...[const SizedBox(height: GzSpace.s2), GzText(category!.of(lang), role: GzTextRole.caption, color: c.textSecondary)],
            const SizedBox(height: GzSpace.s2),
            if (first != null)
              Container(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzUserText(first.nameIn(lang), role: GzTextRole.bodyS),
                    const SizedBox(height: GzSpace.s1),
                    GzPriceCompare(
                      standard: first.standardFils!,
                      voucher: first.voucherOffered(feeFils) ? first.voucherFils : null,
                      structure: first.structure,
                      variant: GzPriceCompareVariant.inline,
                      showNet: false,
                      size: GzPriceCompareSize.strong,
                      fee: feeFils,
                    ),
                  ],
                ),
              )
            else
              GzText(l.hotelProviderPreviewNoPackage, role: GzTextRole.bodyS, color: c.textSecondary),
          ],
        ),
      ),
    );
  }
}
