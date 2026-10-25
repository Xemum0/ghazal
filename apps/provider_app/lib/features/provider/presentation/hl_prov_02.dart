// HL-PROV-02 My listings (web `HL-PROV-02.tsx`): the provider's home for listings. Every listing with its lifecycle pill, plan line and the one
// next step (Plan, Fix, Renew). A listing is never live because it was paid for: In review and Approved are their own cards. Major hotels see
// "No listing fees" and no payment steps. Requirements: PA-LST-01, PA-LST-03, PA-LST-04, PA-ADS-05, PA-REV-02.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_core/ghazal_core.dart' show DateStyle, clockProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Listing, LocalDate, LocalizedText;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/provider_data.dart';
import 'widgets/listing_item.dart';
import 'widgets/prov_bits.dart';

class HlProv02Screen extends ConsumerWidget {
  const HlProv02Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final f = context.gzFormat;
    final nav = GzNavigatorScope.of(context);
    final listings = ref.watch(partnerListingsProvider);
    final billing = ref.watch(partnerBillingProvider).value;
    final cats = ref.watch(serviceCategoriesProvider).value ?? const [];
    final exempt = billing?.feeExempt ?? ref.watch(partnerContextProvider)?.feeExempt ?? false;
    final today = dayOf(f, ref.watch(clockProvider)());

    LocalizedText? categoryOf(Listing k) => cats.where((c) => c.id == k.categoryId).firstOrNull?.name;
    void go(String to, Map<String, Object?> params) => nav.push(to, params: params);

    Widget body(List<Listing> all) {
      final list = sortListings(all, today);
      final expiring = list.where((k) => isExpiring(k, today)).firstOrNull;
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (exempt) ...[const Align(alignment: AlignmentDirectional.centerStart, child: GzMajorHotelBadge()), const SizedBox(height: GzSpace.s5)],
            if (list.isEmpty) GzEmptyState(illustration: GzIllustrationName.emptyListings, title: l.hotelProviderListEmptyTitle, fill: false),
            if (expiring != null && !exempt) ...[
              ProvNote(
                icon: GzIcons.clock,
                figures: true,
                text: l.hotelProviderListExpiryBanner(f.date(expiring.endsOn!.toJson(), DateStyle.short)),
                actionLabel: l.hotelProviderStepRenew,
                onAction: () => go('HL-PROV-04', {'listingId': expiring.id, 'renewal': true}),
              ),
              const SizedBox(height: GzSpace.s5),
            ],
            for (final g in ListingGroup.values) ...[
              if (list.any((k) => groupOf(k, today) == g)) ..._group(context, g, list.where((k) => groupOf(k, today) == g).toList(), today, exempt, categoryOf, go),
            ],
          ],
        ),
      );
    }

    return GzPullToRefresh(
      onRefresh: () async => ref.read(partnerDataRevisionProvider.notifier).bump(),
      child: GzScreen(
        top: GzTopBar(variant: GzTopBarVariant.largeTitle, title: l.hotelProviderListTitle),
        bottom: listings.isLoading || listings.hasError
            ? null
            : GzActionBar(action: GzActionBarAction(label: l.hotelProviderListNew, iconEnd: GzIcons.plus, onPressed: () => go('HL-PROV-03', {'new': true}))),
        child: GzAsyncView<List<Listing>>(
          value: listings,
          loading: const _ListSkeleton(),
          onRetry: () => ref.invalidate(partnerListingsProvider),
          data: body,
        ),
      ),
    );
  }

  List<Widget> _group(
    BuildContext context,
    ListingGroup g,
    List<Listing> items,
    LocalDate today,
    bool exempt,
    LocalizedText? Function(Listing) categoryOf,
    void Function(String, Map<String, Object?>) go,
  ) {
    final l = context.l10n;
    final title = switch (g) {
      ListingGroup.attention => l.hotelProviderListGroupAttention(items.length),
      ListingGroup.running => l.hotelProviderListGroupRunning(items.length),
      ListingGroup.ended => l.hotelProviderListGroupEnded(items.length),
    };
    return [
      GzSectionHeader(title: title, voice: GzHeaderVoice.partner),
      const SizedBox(height: GzSpace.s3),
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(height: GzSpace.s4),
        RepaintBoundary(
          child: ListingItem(
            listing: items[i],
            exempt: exempt,
            category: categoryOf(items[i]),
            step: nextStepOf(items[i], exempt: exempt, today: today),
            onOpen: () => go(openTarget(items[i]), {'listingId': items[i].id}),
            onStep: () {
              final s = nextStepOf(items[i], exempt: exempt, today: today)!;
              go(s.to, s.params);
            },
          ),
        ),
      ],
      const SizedBox(height: GzSpace.s5),
    ];
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
            SizedBox(height: GzSpace.s5),
            GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 112),
          ],
        ),
      );
}
