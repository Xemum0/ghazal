import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/services_providers.dart';
import 'services_glyphs.dart';
import 'widgets/serv_profile_body.dart';

/// The quantity a voucher quote is for: guests for per-person packages, 1 otherwise.
int _qtyOf(ProviderPackage p, int? guests) => p.priceStructure == PriceStructure.perPerson ? (guests ?? 1) : 1;

/// CL-SERV-03 Vendor profile. Covers CA-SVC-10, CA-SVC-11, CA-TOOL-02, CA-TOOL-03, CA-TOOL-10, CA-SVC-14, CA-SVC-15, CA-SVC-18, CA-VCH-01.
///
/// Description, portfolio, packages with prices, reviews and an honest availability line. Actions: Request quote, Save,
/// Add to budget. Guests may browse everything; the sign-in sheet opens at Request quote and at Get voucher. No tab bar.
class ClServ03Screen extends ConsumerStatefulWidget {
  const ClServ03Screen({super.key});

  @override
  ConsumerState<ClServ03Screen> createState() => _ClServ03State();
}

class _ClServ03State extends ConsumerState<ClServ03Screen> {
  int _heroIndex = 0;
  String? _chosenId;
  LocalDate? _date;
  int? _guests;
  bool _pickedDate = false;
  bool _pickedGuests = false;
  bool _dateError = false;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final params = ServicesParams.of(context.gzNav.params);
    final vendorId = params.vendorId ?? kHeroVendorId;
    final vendorAsync = ref.watch(servicesVendorProvider(vendorId));
    final brief = ref.watch(searchBriefProvider);
    final saved = ref.watch(isFavouriteProvider((SavedType.vendor, vendorId)));

    Future<void> toggleSave() async {
      final savedMsg = context.gzL10n.commonStateSaved;
      final nav = context.gzNav;
      final on = await ref.read(favouritesProvider.notifier).toggle(SavedType.vendor, vendorId);
      nav.toast(GzToastSpec(message: on ? savedMsg : l.clientVenueSavedRemoved, icon: on ? GzIcons.heartFill : null));
    }

    return GzScreen(
      top: GzTopBar(
        variant: GzTopBarVariant.transparent,
        actions: [
          GzTopBarAction(
            icon: saved ? GzIcons.heartFill : GzIcons.heart,
            label: saved ? context.gzL10n.commonA11yFavouriteRemove : context.gzL10n.commonA11yFavouriteAdd,
            pressed: saved,
            onPressed: toggleSave,
          ),
        ],
      ),
      topOverlay: true,
      bottom: vendorAsync.hasValue
          ? _ProfileBar(
              vendor: vendorAsync.value!,
              pkg: _pkgOf(vendorAsync.value!, params),
              offered: (_pkgOf(vendorAsync.value!, params))?.voucherPrice != null,
              onGetVoucher: () => _getVoucher(vendorAsync.value!, _pkgOf(vendorAsync.value!, params), brief),
              onQuote: (when) => _openQuote(vendorAsync.value!, _pkgOf(vendorAsync.value!, params)?.id, when),
            )
          : null,
      child: GzAsyncView<ServiceProvider>(
        value: vendorAsync,
        onRetry: () => ref.invalidate(servicesVendorProvider(vendorId)),
        loading: _ProfileSkeleton(key: ValueKey<String>('services.profile.$vendorId.loading')),
        data: (v) {
          final pkg = _pkgOf(v, params);
          final date = _pickedDate ? _date : brief.date;
          final guests = _pickedGuests ? _guests : brief.guests;
          final qty = pkg == null ? 1 : _qtyOf(pkg, guests);
          final quote = pkg == null ? null : ref.watch(servicesQuoteProvider(QuoteQuery(vendorId: v.id, packageId: pkg.id, qty: qty))).value;
          final offered = pkg?.voucherPrice != null;
          final budget = quote != null ? (offered ? quote.totals.voucherTotal.fils : quote.totals.standardTotal.fils) : (pkg?.price.fils ?? v.from.fils);
          return ServProfileBody(
            vendor: v,
            pkg: pkg,
            date: date,
            guests: guests,
            dateError: _dateError,
            heroIndex: _heroIndex,
            onHeroIndex: (i) => setState(() => _heroIndex = i),
            onOpenPhoto: (i) => _openViewer(context, [for (final p in v.portfolio) GzCarouselImage(src: gzImageSrc(p.file, p.baseUrl), alt: context.bi(v.name))], i, context.bi(v.name)),
            onChoose: (id) => setState(() => _chosenId = id),
            onDate: (d) => setState(() {
              _date = d;
              _pickedDate = true;
              _dateError = false;
            }),
            onGuests: (n) => setState(() {
              _guests = n;
              _pickedGuests = true;
            }),
            onAsk: () => _openQuote(v, pkg?.id, date),
            onAddBudget: () => _addBudget(v, pkg, quote),
            budgetFils: budget,
          );
        },
      ),
    );
  }

  ProviderPackage? _pkgOf(ServiceProvider v, ServicesParams params) =>
      v.packages.where((p) => p.id == (_chosenId ?? params.packageId)).firstOrNull ?? v.packages.firstOrNull;

  void _openQuote(ServiceProvider v, String? packageId, LocalDate? when) {
    final nav = context.gzNav;
    final date = when ?? ref.read(searchBriefProvider).date;
    final quoteParams = <String, Object?>{'vendorId': v.id, if (date != null) 'date': date.toString()};
    if (packageId != null) quoteParams['packageId'] = packageId;
    nav.openSheet('CL-SERV-04', options: GzSheetOptions(params: quoteParams));
  }

  void _getVoucher(ServiceProvider v, ProviderPackage? pkg, SearchBrief brief) {
    if (pkg == null) return;
    final nav = context.gzNav;
    final date = _pickedDate ? _date : brief.date;
    final guests = _pickedGuests ? _guests : brief.guests;
    if (date == null) {
      setState(() => _dateError = true);
      return;
    }
    final params = <String, Object?>{
      'providerId': v.id,
      'packageId': pkg.id,
      'date': date.toString(),
      if (guests != null) 'guests': _qtyOf(pkg, guests),
      'from': 'CL-SERV-03',
    };
    nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: params));
  }

  void _addBudget(ServiceProvider v, ProviderPackage? pkg, Quote? quote) {
    final amount = quote != null ? (quote.totals.voucherTotal.fils != 0 ? quote.totals.voucherTotal.fils : quote.totals.standardTotal.fils) : (pkg?.price.fils ?? v.from.fils);
    context.gzNav.openSheet('CL-WEDD-04', options: GzSheetOptions(params: <String, Object?>{'categoryId': v.categoryId.value, 'amount': amount}));
  }
}

/// The sticky bar: Get voucher (or Request quote when no voucher price), Open chat beneath.
class _ProfileBar extends ConsumerWidget {
  const _ProfileBar({required this.vendor, required this.pkg, required this.offered, required this.onGetVoucher, required this.onQuote});

  final ServiceProvider vendor;
  final ProviderPackage? pkg;
  final bool offered;
  final VoidCallback onGetVoucher;
  final void Function(LocalDate?) onQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final brief = ref.watch(searchBriefProvider);
    void openChat() {
      context.gzNav.push('CL-MSGS-02', params: <String, Object?>{'vendorId': vendor.id});
    }

    // The three paths (voucher-model section 3): the gold action, Request quote as a quiet text action and the chat glyph, one row apart
    // (web `.gzs-prof__barnote`: space between, 12 gap). Without a voucher price the gold action is Request quote and only the chat is left.
    final note = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (offered) GzButton(label: l.clientServicesProfileRequest, variant: GzButtonVariant.tertiary, onPressed: () => onQuote(brief.date)) else const SizedBox.shrink(),
        GzIconButton(icon: GzIcons.chat, label: context.gzL10n.commonActionMessage, variant: GzIconButtonVariant.outline, onPressed: openChat),
      ],
    );
    if (offered) {
      final c = context.gz.colors;
      // The fee as a glyph and a figure (the word is the accessible name): web `.gzs-prof__fee`.
      final fee = Semantics(
        label: context.gzL10n.commonVoucher,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: GzIcon(GzIcons.ticket, size: GzIconSize.md, color: c.iconPrimary)),
            const SizedBox(width: GzSpace.s2),
            const GzPrice(fils: 2000, size: GzPriceSize.strong),
          ],
        ),
      );
      return GzActionBar(
        action: GzActionBarAction(label: l.clientServicesProfileGetVoucher, onPressed: onGetVoucher),
        summaryValue: fee,
        noteWidget: note,
      );
    }
    return GzActionBar(action: GzActionBarAction(label: l.clientServicesProfileRequest, onPressed: () => onQuote(brief.date)), noteWidget: note);
  }
}

/// The portfolio viewer: the shared gallery viewer route (the viewer-as-route is 'CL-VENU-02' for venues).
Future<void> _openViewer(BuildContext context, List<GzCarouselImage> images, int index, String name) =>
    showGzGalleryViewer(context, images: images, label: name, initialIndex: index, heroGroup: 'vendor-portfolio-$name');

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(height: GzLayout.heroVenue, color: context.gz.colors.surfacePlaceholder),
      const SizedBox(height: GzSpace.s4),
      const Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [GzSkeleton(inlineSize: 24, blockSize: 1), SizedBox(height: GzSpace.s2), GzSkeleton(inlineSize: 180, blockSize: 24), SizedBox(height: GzSpace.s2), GzSkeleton(blockSize: 20)],
        ),
      ),
      const SizedBox(height: GzSpace.s3),
      const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: GzSkeletonText(lines: 3)),
      const SizedBox(height: GzSpace.s4),
      const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: GzSkeleton(blockSize: 120)),
      const SizedBox(height: GzSpace.s3),
      const Padding(padding: EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter), child: GzSkeleton(blockSize: 120)),
    ],
  );
}

// Edges (inventory navigatesTo): 'CL-SERV-04' (Request a quote opens the quote sheet), 'CL-WEDD-04' (Add to budget),
// 'CL-SERV-02' (back returns to the list), 'CL-VENU-02' (the portfolio opens through the shared gallery viewer route),
// 'CL-VCHR-01' (Get voucher bound to the package), 'CL-MSGS-02' (Contact opens the vendor chat).
