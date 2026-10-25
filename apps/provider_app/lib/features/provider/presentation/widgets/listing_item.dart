// ListingItem (web `ListingItem.tsx` + `ListingCard.tsx`): one advertisement as the shared provider card plus its next step under it. The card
// opens the editor, the review status or the performance by state; the step under it ("Plan", "Fix", "Renew") is the one thing to do next.
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart' show Listing, LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/provider_data.dart';
import 'prov_listing_card.dart';

String nextStepLabel(AppL10n l, NextStepId id) => switch (id) {
  NextStepId.finish => l.hotelProviderStepFinish,
  NextStepId.choosePlan => l.hotelProviderStepChoosePlan,
  NextStepId.fix => l.hotelProviderStepFix,
  NextStepId.renew => l.hotelProviderStepRenew,
  NextStepId.submit => l.hotelProviderStepSubmit,
};

class ListingItem extends StatelessWidget {
  const ListingItem({required this.listing, required this.exempt, required this.step, this.category, this.onOpen, this.onStep, this.readOnly = false, super.key});

  final Listing listing;
  final bool exempt;
  final NextStep? step;
  final LocalizedText? category;
  final VoidCallback? onOpen;
  final VoidCallback? onStep;

  /// The viewer's role may read but not change listings.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProvListingCard(listing: listing, category: category, exempt: exempt, onOpen: onOpen),
        if (step != null && !readOnly) ...[
          const SizedBox(height: GzSpace.s2),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: GzButton(label: nextStepLabel(l, step!.id), variant: GzButtonVariant.secondary, size: GzButtonSize.md, iconEnd: GzIcons.chevronRight, onPressed: onStep),
          ),
        ],
      ],
    );
  }
}
