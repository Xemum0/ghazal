import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/booking_actions.dart';
import '../application/booking_flow_local.dart';
import '../application/booking_flow_model.dart';
import '../application/booking_flow_providers.dart';
import 'booking_glyphs.dart';
import 'widgets/bar_total.dart';
import 'widgets/booking_async.dart';
import 'widgets/booking_info.dart';
import 'widgets/booking_layout.dart';
import 'widgets/extra_row.dart';
import 'widgets/step_scaffold.dart';

/// CL-BOOK-03 Extras (step 3 of 5). Covers CA-BOOK-05, CA-BOOK-14, CA-VDET-13, CA-AUTH-10, CA-VCH-02.
///
/// An extra is a glyph, a name and a price in its unit; choosing is the whole row (a ring that fills) or a stepper. The one sentence of
/// the step lives behind the info glyph beside the title. A running voucher total, and for a guest the account gate right before
/// personal data. Continue is never disabled.
class ClBook03Screen extends ConsumerWidget {
  const ClBook03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final nav = context.gzNav;
    final async = ref.watch(bookingFlowProvider);
    final flow = keepStale(async).value;
    final draft = ref.watch(effectiveBookingDraftProvider);
    void retry() => ref.invalidate(bookingFlowProvider);

    // A guest meets the account sheet ('CL-AUTH-01', opened by requireSignIn) right before personal data and resumes at step 4.
    void next() {
      final reason = flow != null && flow.bound ? GateReason.sendRequest : GateReason.voucher;
      if (flow != null && !ref.requireSignIn(reason, resume: const GateResume('CL-BOOK-04'))) {
        return;
      }
      nav.push('CL-BOOK-04');
    }

    void setIds(List<String> ids) => patchBookingDraft(ref, (d) => d.copyWith(extras: ids));

    final rows = flow == null ? const <ExtraChoice>[] : _rows(flow);
    final failed = async.hasError && flow == null;
    GzActionBarAction? action;
    Widget? summary;
    if (!failed) {
      action = GzActionBarAction(label: l10n.commonActionContinue, loading: flow == null, onPressed: next);
      if (flow?.total != null) {
        summary = BookingBarTotal(
          fils: flow!.total!,
          icon: flow.hasVoucherPrice ? GzIcons.ticket : GzIcons.coins,
          label: flow.hasVoucherPrice ? l10n.clientBookingVoucherTotalLabel : l10n.commonMoneyTotal,
        );
      }
    }
    return BookingStepScaffold(
      step: 3,
      venueName: flow == null ? '' : context.bi(flow.venue.name),
      title: l10n.clientBookingExtrasTitle,
      info: failed || (flow != null && rows.isEmpty)
          ? null
          : BookingInfoButton(
              title: l10n.clientBookingExtrasInfoTitle,
              paragraphs: [l10n.clientBookingExtrasLead, l10n.clientBookingExtrasSettledNote],
            ),
      action: action,
      summary: summary,
      showBar: action != null,
      children: [
        BookingAsync<FlowModel>(
          value: async,
          onRetry: retry,
          loading: const _ExtrasSkeleton(),
          data: (flow) {
            final list = _rows(flow);
            if (list.isEmpty) {
              return StepSection(
                children: [
                  GzEmptyState(
                    fill: false,
                    illustration: GzIllustrationName.bouquet,
                    title: l10n.clientBookingExtrasNone,
                    detail: l10n.clientBookingExtrasNoneOffered,
                    detailTitle: l10n.clientBookingExtrasInfoTitle,
                  ),
                ],
              );
            }
            final local = ref.watch(bookingFlowLocalProvider);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StepSection(
                  label: l10n.clientBookingExtrasTitle,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: context.gz.colors.borderStrong, width: GzStroke.hair),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final r in list)
                            BookingExtraRow(
                              choice: r,
                              onToggle: () => setIds(
                                draft.extras.contains(r.extra.id)
                                    ? [
                                        for (final x in draft.extras)
                                          if (x != r.extra.id) x,
                                      ]
                                    : [...draft.extras, r.extra.id],
                              ),
                              onQty: (q) {
                                ref
                                    .read(bookingFlowLocalProvider.notifier)
                                    .update((l) => l.copyWith(extraQty: {...local.extraQty, r.extra.id: q < 1 ? 1 : q}));
                                if (q > 0 && !draft.extras.contains(r.extra.id)) setIds([...draft.extras, r.extra.id]);
                                if (q <= 0) {
                                  setIds([
                                    for (final x in draft.extras)
                                      if (x != r.extra.id) x,
                                  ]);
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                StepSection(
                  bottom: 0,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StartBleed(
                        child: GzButton(
                          label: l10n.clientBookingExtrasNone,
                          variant: GzButtonVariant.tertiary,
                          onPressed: () {
                            setIds(const <String>[]);
                            next();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// The extras the screen lists, in the order a Kuwaiti couple asks about them; included ones last.
  List<ExtraChoice> _rows(FlowModel flow) {
    final rows = <ExtraChoice>[for (final cat in kExtraOrder) ...flow.extras.where((e) => e.extra.category == cat)];
    rows.sort((a, b) => (a.included ? 1 : 0).compareTo(b.included ? 1 : 0));
    return rows;
  }
}

class _ExtrasSkeleton extends StatelessWidget {
  const _ExtrasSkeleton();

  @override
  Widget build(BuildContext context) {
    return StepSection(
      children: [
        for (var i = 0; i < 4; i++)
          const Row(
            children: [
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 40, blockSize: 40),
              SizedBox(width: GzSpace.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GzSkeleton(inlineSize: 160, blockSize: 24),
                    SizedBox(height: GzSpace.s1),
                    GzSkeleton(inlineSize: 96, blockSize: 20),
                  ],
                ),
              ),
              GzSkeleton(variant: GzSkeletonVariant.block, inlineSize: 24, blockSize: 24),
            ],
          ),
      ],
    );
  }
}
