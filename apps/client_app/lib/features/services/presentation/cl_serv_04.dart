import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show gzProblemKind, gzProblemMessage, homeRepositoryProvider, servicesRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem, ApiProblemCode;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/services_providers.dart';
import 'services_glyphs.dart';
import 'widgets/serv_quote_parts.dart';

/// CL-SERV-04 Request a quote (sheet). Covers CA-SVC-11, CA-CHAT-04, CA-AUTH-10, CA-SVC-15, CA-SVC-18.
///
/// A short structured enquiry that becomes a card in a new vendor chat thread. Hard-gated, with everything typed
/// preserved through sign-in. Guests see the sign-in sheet at Send with the context line "to request a quote". Success
/// copy states that replies arrive in Messages. An "Attach your voucher" line shows when the client holds a ready
/// voucher for this provider.
class ClServ04Screen extends ConsumerWidget {
  const ClServ04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = ServicesParams.of(context.gzNav.params);
    final vendorId = params.vendorId ?? kHeroVendorId;
    final draft = ref.watch(quoteDraftProvider);
    if (draft.sentTo != null) return _QuoteSuccess(vendorId: vendorId, voucherSent: draft.attachVoucher);
    return _QuoteForm(vendorId: vendorId, presetPackageId: params.packageId, presetDate: params.date);
  }
}

/// The quote form: package, event date, venue, guests, note, the attach-voucher line, Send.
class _QuoteForm extends ConsumerStatefulWidget {
  const _QuoteForm({required this.vendorId, required this.presetPackageId, required this.presetDate});

  final String vendorId;
  final String? presetPackageId;
  final LocalDate? presetDate;

  @override
  ConsumerState<_QuoteForm> createState() => _QuoteFormState();
}

class _QuoteFormState extends ConsumerState<_QuoteForm> {
  String? _packageId;
  LocalDate? _dateOverride;
  String? _venueId;
  int _guests = 0;
  String _note = '';
  bool _sending = false;
  bool _failed = false;
  bool _showDateError = false;
  String? _problem;
  bool _seeded = false;
  final IntentKeys _keys = IntentKeys();

  void _seed(ServiceProvider v) {
    if (_seeded) return;
    _seeded = true;
    _packageId = widget.presetPackageId != null && v.packages.any((p) => p.id == widget.presetPackageId) ? widget.presetPackageId : v.packages.firstOrNull?.id;
    final g = ref.read(searchBriefProvider).guests;
    if (g != null) _guests = g;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final draft = ref.watch(quoteDraftProvider);
    final vendorAsync = ref.watch(servicesVendorProvider(widget.vendorId));
    final vendor = vendorAsync.value;
    if (vendor != null) _seed(vendor);
    final brief = ref.watch(searchBriefProvider);
    final draftVenue = ref.watch(bookingDraftProvider.select((b) => b.venueId));
    final linkVenue = context.gzNav.params['venueId'] as String?;
    final venueId = _venueId == null ? (linkVenue ?? draftVenue) : (_venueId!.isEmpty ? null : _venueId);
    final date = _dateOverride ?? widget.presetDate ?? brief.date;
    final ready = ref.watch(servicesReadyVoucherProvider(widget.vendorId)).value;
    final venues = ref.watch(servicesVenuesProvider).value ?? const <VenueSummary>[];
    final pkg = vendor?.packages.where((p) => p.id == _packageId).firstOrNull ?? vendor?.packages.firstOrNull;
    final Voucher? voucher = ready;
    final attached = draft.attachVoucher && voucher != null;
    final eventDate = attached ? voucher.eventDate : date;
    final dateError = _showDateError && eventDate == null;

    Future<void> send() async {
      if (vendor == null || pkg == null) return;
      if (eventDate == null) {
        setState(() => _showDateError = true);
        return;
      }
      if (_sending) return;
      setState(() {
        _sending = true;
        _failed = false;
        _problem = null;
      });
      try {
        final boundGuests = attached && pkg.priceStructure == PriceStructure.perPerson ? voucher.guests : (_guests == 0 ? null : _guests);
        final req = await ref.read(servicesRepositoryProvider).createQuoteRequest(
          body: CreateQuoteRequestInput(providerId: vendor.id, packageId: attached ? voucher.packageId : pkg.id, eventDate: attached ? voucher.eventDate : eventDate, venueId: venueId, guests: boundGuests, note: _note.trim().isEmpty ? null : _note.trim()),
          idempotencyKey: _keys.keyFor('quote:${vendor.id}:${pkg.id}:${eventDate.toString()}'),
        );
        ref.read(quoteDraftProvider.notifier).sent(req.conversationId ?? req.id);
        ref.read(clientDataRevisionProvider.notifier).bump();
      } on ApiProblem catch (e) {
        setState(() {
          _sending = false;
          _failed = true;
          _problem = e.messageKey;
        });
      }
    }

    final cats = ref.watch(servicesCategoriesProvider).value ?? const <ServiceCategory>[];
    final category = cats.where((c) => c.id == vendor?.categoryId).firstOrNull;
    final glyph = category == null ? GzIcons.sparkle : servicesGlyphOf(category.icon);
    final c = context.gz.colors;
    final lc = context.gzL10n;

    // A picker row: its name is the accessible name only (the glyph is the label, ADR 0034).
    Widget pick<V extends Object>({
      required String name,
      required List<GzSelectOption<V>> options,
      required List<V> values,
      required IconData icon,
      required ValueChanged<V> onPick,
      bool searchable = false,
      bool disabled = false,
      V? selected,
    }) {
      return QuoteNamed(
        name: name,
        child: GzSelectRow<V>(
          label: '',
          options: options,
          values: values,
          placeholder: lc.commonLabelNotDecided,
          startAdornment: GzIcon(icon, size: GzIconSize.sm, tone: GzIconTone.secondary),
          disabled: disabled,
          onTap: disabled
              ? null
              : () {
                  final nav = context.gzNav;
                  nav.openSheetBuilder(
                    (_) => GzPickerList<V>(
                      options: options,
                      selected: [?selected ?? (values.isEmpty ? null : values.first)],
                      searchable: searchable,
                      onPick: (v) {
                        onPick(v);
                        nav.closeSheet();
                      },
                    ),
                    options: GzSheetOptions(title: name),
                  );
                },
        ),
      );
    }

    final packageOptions = [
      if (vendor != null)
        for (final p in vendor.packages) GzSelectOption<String>(value: p.id, label: context.bi(p.name), description: context.gzFormat.money(p.price.fils)),
    ];
    final venueOptions = [
      GzSelectOption<String>(value: '', label: lc.commonLabelNotDecided),
      for (final v in venues) GzSelectOption<String>(value: v.id, label: context.bi(v.name)),
    ];
    final guestOptions = [
      GzSelectOption<String>(value: 'none', label: lc.commonLabelNotDecided),
      for (final n in _guestSteps(_guests)) GzSelectOption<String>(value: '$n', label: context.gzFormat.integer(n)),
    ];

    return Column(
      key: ValueKey<String>('services.quote.${widget.vendorId}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzSheetPinnedHeader(
          child: QuoteHead(
            name: vendor == null ? l.clientServicesQuoteTitle : context.bi(vendor.name),
            glyph: glyph,
            accessibleTitle: l.clientServicesQuoteTitle,
            onClose: () => context.gzNav.closeSheet(),
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        if (vendorAsync.isLoading && vendor == null)
          const Column(children: [GzSkeleton(blockSize: 56), SizedBox(height: GzSpace.s3), GzSkeleton(blockSize: 56), SizedBox(height: GzSpace.s3), GzSkeleton(blockSize: 96)])
        else if (vendor == null && vendorAsync.hasError)
          GzErrorState(
            key: const ValueKey<String>('services.quote.error'),
            kind: gzProblemKind(vendorAsync.error is ApiProblem ? vendorAsync.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown)),
            body: gzProblemMessage(lc, vendorAsync.error is ApiProblem ? vendorAsync.error! as ApiProblem : const ApiProblem(status: 0, code: ApiProblemCode.unknown)),
            fill: false,
            onRetry: () => ref.invalidate(servicesVendorProvider(widget.vendorId)),
          )
        else if (vendor == null)
          GzEmptyState(
            illustration: GzIllustrationName.noResult,
            title: l.clientServicesListEmptyTitle,
            action: GzStateAction(label: l.commonActionClose, variant: GzButtonVariant.primary, onPressed: () => context.gzNav.closeSheet()),
          )
        else ...[
          if (_failed)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: GzSpace.s4),
              child: GzBanner(message: _problem ?? l.clientServicesQuoteErrorTitle, tone: GzBannerTone.danger, shape: GzBannerShape.card),
            ),
          if (ready != null) ...[
            GzToggleRow(
              title: l.clientServicesQuoteAttachTitle,
              description: ready.code,
              checked: draft.attachVoucher,
              onChanged: (v) => ref.read(quoteDraftProvider.notifier).attach(v),
              disabled: _sending,
              divider: false,
            ),
            if (attached && pkg != null)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                child: Row(
                  children: [
                    GzPrice(fils: pkg.voucherPrice?.fils ?? pkg.price.fils, size: GzPriceSize.strong),
                    const SizedBox(width: GzSpace.s2),
                    GzInfoButton(title: l.clientServicesQuoteAttachInfoTitle, label: l.clientServicesQuoteAttachInfoTitle, paragraphs: [l.clientServicesQuoteAttachNote]),
                  ],
                ),
              ),
            const SizedBox(height: GzSpace.s4),
          ],
          pick<String>(
            name: l.clientServicesQuotePackage,
            options: packageOptions,
            values: attached ? [voucher.packageId] : [if (pkg != null) pkg.id],
            icon: GzIcons.package,
            disabled: _sending || attached,
            onPick: (id) => setState(() => _packageId = id),
          ),
          const SizedBox(height: GzSpace.s3),
          QuoteNamed(
            name: l.clientServicesQuoteDate,
            child: QuoteDateField(
              value: eventDate?.toString(),
              placeholder: l.clientServicesQuoteDatePlaceholder,
              error: dateError ? l.clientServicesQuoteDateError : null,
              disabled: _sending || attached,
              onTap: _sending || attached
                  ? null
                  : () {
                      final nav = context.gzNav;
                      nav.openSheetBuilder(
                        (_) => GzDateFieldSheetContent(
                          value: eventDate?.toString(),
                          onConfirm: (v) {
                            if (v != null) setState(() => _dateOverride = LocalDate.parse(v));
                            nav.closeSheet();
                          },
                        ),
                        options: GzSheetOptions(title: l.clientServicesQuoteDate),
                      );
                    },
            ),
          ),
          const SizedBox(height: GzSpace.s3),
          pick<String>(
            name: l.clientServicesQuoteVenue,
            options: venueOptions,
            values: venueId == null ? const [] : [venueId],
            selected: venueId ?? '',
            icon: GzIcons.hall,
            searchable: true,
            disabled: _sending,
            onPick: (id) => setState(() => _venueId = id),
          ),
          const SizedBox(height: GzSpace.s3),
          pick<String>(
            name: l.clientServicesQuoteGuests,
            options: guestOptions,
            values: [_guests == 0 ? 'none' : '$_guests'],
            icon: GzIcons.usersThree,
            disabled: _sending,
            onPick: (id) => setState(() => _guests = id == 'none' ? 0 : int.parse(id)),
          ),
          const SizedBox(height: GzSpace.s3),
          QuoteNamed(
            name: l.clientServicesQuoteNoteLabel,
            child: GzTextArea(placeholder: l.clientServicesQuoteNotePlaceholder, value: _note, onValueChange: (v) => setState(() => _note = v), rows: 2, disabled: _sending),
          ),
          const SizedBox(height: GzSpace.s4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: GzSpace.s3),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzButton(label: l.clientServicesQuoteSend, iconStart: attached ? GzIcons.ticket : null, fullWidth: true, loading: _sending, onPressed: _sending ? null : send),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The guest steps of the picker, with the current count kept when it is off the ladder.
List<int> _guestSteps(int current) {
  const steps = <int>[100, 150, 200, 250, 300, 350, 400, 500, 600, 800];
  if (current > 0 && !steps.contains(current)) return [...steps, current]..sort();
  return steps;
}

/// "Request sent": replies arrive in Messages. An attached voucher turns it into a request at the voucher price.
class _QuoteSuccess extends ConsumerWidget {
  const _QuoteSuccess({required this.vendorId, required this.voucherSent});

  final String vendorId;
  final bool voucherSent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final vendor = ref.watch(servicesVendorProvider(vendorId)).value;
    final name = vendor == null ? '' : context.bi(vendor.name);
    final hours = ref.watch(_quoteConfirmHoursProvider).value;
    void openChat() {
      context.gzNav.closeSheet();
      context.gzNav.push('CL-MSGS-02', params: <String, Object?>{'vendorId': vendorId});
    }

    return Column(
      key: const ValueKey<String>('services.quote.success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GzSheetPinnedHeader(child: GzSheetHeader(onClose: () => context.gzNav.closeSheet(), title: l.clientServicesQuoteTitle)),
        const SizedBox(height: GzSpace.s4),
        GzSuccessState(
          illustration: GzIllustrationName.successRequest,
          title: l.clientServicesRequestSent,
          detailTitle: l.clientServicesQuoteNextTitle,
          detail: voucherSent && hours != null ? l.clientServicesQuoteVoucherSuccessBody(name, context.gzL10n.commonCountHours(hours)) : null,
          action: GzStateAction(label: voucherSent ? l.clientServicesQuoteViewRequest : l.clientServicesProfileOpenChat, variant: GzButtonVariant.primary, onPressed: openChat),
          secondary: voucherSent
              ? GzStateAction(label: l.clientServicesProfileOpenChat, variant: GzButtonVariant.secondary, onPressed: openChat)
              : GzStateAction(label: context.gzL10n.commonActionDone, variant: GzButtonVariant.secondary, onPressed: () => context.gzNav.closeSheet()),
        ),
        const SizedBox(height: GzSpace.s2),
      ],
    );
  }
}

final _quoteConfirmHoursProvider = FutureProvider.autoDispose<int>((ref) async => (await ref.watch(homeRepositoryProvider).getAppConfig()).config.confirmWindowHours);

// Edges (inventory navigatesTo): 'CL-MSGS-02' (the sent request opens in the vendor chat). 'CL-VCHR-04' is not wired: attaching a voucher needs the voucher flow's contract.
