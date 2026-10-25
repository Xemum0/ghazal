// "The listing this is for" row of the plan screen (web `ForListing`): the title as typed, its category and an Edit link.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Listing, LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class ForListing extends StatelessWidget {
  const ForListing({required this.listing, this.category, required this.onEdit, super.key});

  final Listing listing;
  final LocalizedText? category;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final lang = context.gz.locale.languageCode;
    return Container(
      padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GzUserText(listing.title.of(lang), role: GzTextRole.title, color: c.textStrong),
                if (category != null) ...[const SizedBox(height: GzSpace.s1), GzText(category!.of(lang), role: GzTextRole.caption, color: c.textSecondary)],
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s3),
          GzButton(label: context.l10n.hotelProviderPlanEditListing, variant: GzButtonVariant.tertiary, onPressed: onEdit),
        ],
      ),
    );
  }
}
