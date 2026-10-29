import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/bar_total.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_layout.dart';
import 'widgets/package_choice.dart';
import 'widgets/quote_lines.dart';
import 'widgets/step_scaffold.dart';

/// CL-BOOK-02 Package (step 2 of 4). Covers CA-BOOK-04, CA-BOOK-06, CA-BOOK-14, CA-VDET-07, CA-VCH-02.
///
/// Exactly one package, priced by the server for the date and guests in both columns. A voucher is bound to one package: the others are
/// shown, and choosing one opens the voucher quote sheet; a package with no voucher price says it is not covered. The bar keeps the
/// voucher total with its breakdown.
class ClBook02Screen extends ConsumerStatefulWidget {
  const ClBook02Screen({super.key});

  @override
  ConsumerState<ClBook02Screen> createState() => _ClBook02State();
}

class _ClBook02State extends ConsumerState<ClBook02Screen> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final async = ref.watch(bookingFlowProvider);
    final flow = keepStale(async).value;

    // A reception that sells exactly one package needs no decision: it is chosen for you (the person still sees it, and can go back).
    ref.listen(bookingFlowProvider, (prev, next) {
      final fl = next.value;
      if (fl == null || fl.demo) return;
      final only = fl.section.options.length == 1 ? fl.section.options.first : null;
      if (fl.section.chosen == null && only != null) patchBookingDraft(ref, (d) => d.copyWith(packageId: only.pkg.id));
    });

    void retry() => ref.invalidate(bookingFlowProvider);
    GzActionBarAction? action;
    Widget? summary;
    if (async.hasError && flow == null) {
      action = null;
    } else if (flow == null) {
      action = GzActionBarAction(label: l10n.commonActionContinue, loading: true, onPressed: retry);
    } else {
      final sec = flow.section;
      final missing = sec.chosen == null;
      final noneFit = sec.options.isEmpty;
      final blocked = noneFit || missing;
      action = GzActionBarAction(
        label: l10n.commonActionContinue,
        onPressed: () => nav.push('CL-BOOK-04'),
        disabled: blocked,
        reason: !blocked || noneFit ? null : l10n.clientBookingPackageMissingReason,
      );
      if (!missing && flow.quote != null) {
        final label = flow.hasVoucherPrice
            ? (flow.bound ? l10n.clientBookingVoucherTotalLabel : l10n.clientBookingVoucherEstimateLabel)
            : l10n.commonMoneyTotal;
        summary = GzPressable(
          onPressed: () => _openBreakdown(flow),
          semanticLabel: '$label: ${l10n.clientBookingPackageBreakdownOpen}',
          minWidth: 0,
          minHeight: GzSize.controlMd,
          scale: 1,
          child: BookingBarTotal(
            fils: flow.total!,
            icon: flow.hasVoucherPrice ? GzIcons.ticket : GzIcons.coins,
            label: label,
            estimate: !flow.bound,
            after: GzIcon(GzIcons.chevronUp, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
          ),
        );
      }
    }

    return BookingStepScaffold(
      step: 2,
      venueName: flow == null ? '' : context.bi(flow.venue.name),
      title: l10n.clientBookingPackageTitle,
      action: action,
      summary: summary,
      showBar: action != null,
      children: [
        BookingAsync<FlowModel>(
          value: async,
          onRetry: retry,
          loading: const StepSection(gap: GzSpace.s4, children: [BookingPackageSkeleton(), BookingPackageSkeleton()]),
          data: (flow) => _PackageList(flow: flow),
        ),
      ],
    );
  }

  void _openBreakdown(FlowModel flow) {
    final nav = context.gzNav;
    nav.openSheetBuilder(
      (sheet) => BookingQuoteLines(quote: flow.quote!),
      options: GzSheetOptions(title: context.l10n.clientBookingPriceTitle),
    );
  }
}

class _PackageList extends ConsumerWidget {
  const _PackageList({required this.flow});

  final FlowModel flow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final f = ref.watch(gzFormatProvider);
    final sec = flow.section;

    if (sec.options.isEmpty) {
      return StepSection(
        children: [
          GzEmptyState(
            fill: false,
            illustration: GzIllustrationName.noResult,
            title: l10n.clientBookingPackageNoneTitle,
            detail: l10n.clientBookingPackageNoneBody(f.guests(sec.guests, afterPreposition: true)),
            detailTitle: l10n.clientBookingPackageNoneInfoTitle,
            action: GzStateAction(label: l10n.clientBookingPackageNoneAction, onPressed: () => goBookingStep(ref, nav, from: 2, to: 1)),
          ),
        ],
      );
    }
    void choose(PricedPackage o) {
      final chosen = sec.chosen;
      if (flow.bound && chosen?.pkg.id != o.pkg.id) {
        // A voucher is bound to one quote: another package is a different quote (CL-VCHR-04 re-runs the saving test).
        if (!o.hasVoucher) {
          nav.toast(GzToastSpec(message: l10n.clientBookingPackageNotCoveredToast));
        } else {
          changeBookingVoucher(nav, flow, 'CL-BOOK-02');
        }
        return;
      }
      patchBookingDraft(ref, (d) => d.copyWith(packageId: o.pkg.id));
    }

    return StepSection(
      gap: GzSpace.s4,
      label: l10n.clientBookingPackageTitle,
      children: [
        for (final o in sec.options)
          RepaintBoundary(
            child: BookingPackageChoice(
              option: o,
              guests: sec.guests,
              selected: sec.chosen?.pkg.id == o.pkg.id,
              elsewhere: flow.bound && sec.chosen?.pkg.id != o.pkg.id,
              onSelect: () => choose(o),
              onDetails: () =>
                  nav.openSheet('CL-VENU-04', options: GzSheetOptions(params: <String, Object?>{'packageId': o.pkg.id, 'venueId': flow.venue.id})),
            ),
          ),
      ],
    );
  }
}
