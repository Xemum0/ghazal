// HL-PROV-03 Listing (web `HL-PROV-03.tsx`): create or edit a listing. Category, title and description in Arabic and English (both required
// before review), photos, packages each with a standard price and a voucher price on the same basis, and the contact options. Save draft keeps
// it; Continue goes to the plan (or straight to review for a fee-exempt partner or a resubmission). A live listing keeps its approved version
// until the new one is approved. Requirements: PA-LST-01..03, PA-LST-07, HA-VMGT-09.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/listing_draft.dart';
import '../application/provider_actions.dart';
import '../application/provider_data.dart';
import 'widgets/package_cards.dart';
import 'widgets/photo_strip.dart';
import 'widgets/prov_bits.dart';
import 'widgets/what_couples_see.dart';

class HlProv03Screen extends ConsumerWidget {
  const HlProv03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    final isNew = nav.params['new'] == true;
    final id = isNew ? null : (nav.params['listingId'] as String? ?? kHeroReviewListingId);
    final listing = isNew ? const AsyncValue<Listing?>.data(null) : ref.watch(pickedListingProvider(ListingPick(id, const [])));
    final packages = ref.watch(providerPackagesProvider);
    final err = listing.hasError ? listing : packages;
    if (!listing.isLoading && !packages.isLoading && !listing.hasError && !packages.hasError) {
      final k = listing.value;
      return _Editor(key: ValueKey(k?.id ?? 'new'), listing: k, initial: k == null ? const ListingDraft() : ListingDraft.of(k, packages.value ?? const []));
    }
    return GzScreen(
      top: GzTopBar(title: isNew ? l.hotelProviderEditorTitleNew : l.hotelProviderEditorTitle),
      child: GzAsyncView<Object?>(
        value: err.hasError ? AsyncValue<Object?>.error(err.error!, err.stackTrace ?? StackTrace.empty) : const AsyncValue<Object?>.loading(),
        loading: const _EditorSkeleton(),
        onRetry: () {
          ref.invalidate(pickedListingProvider);
          ref.invalidate(providerPackagesProvider);
        },
        data: (_) => const SizedBox.shrink(),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.listing, required this.initial, super.key});

  final Listing? listing;
  final ListingDraft initial;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  late ListingDraft _draft = widget.initial;
  late ListingDraft _base = widget.initial;
  String? _createdId;
  bool _tried = false;
  bool _saved = false;
  int _pk = 0;

  Listing? get _listing => widget.listing;
  String? get _id => _listing?.id ?? _createdId;
  bool get _dirty => _draft != _base;

  void _patch(ListingDraft d) => setState(() {
        _saved = false;
        _draft = d;
      });

  Future<String?> _persist() async {
    final nav = GzNavigatorScope.of(context);
    final res = await ref.read(listingActionsProvider.notifier).saveDraft(_draft, listingId: _id);
    if (!mounted) return null;
    switch (res) {
      case ActionSuccess(:final value):
        _createdId = value.id;
        setState(() => _base = _draft);
        return value.id;
      case ActionFailure(:final problem):
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
    return null;
  }

  Future<void> _saveDraft() async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    if (_draft.titleEn.trim().isEmpty && _draft.titleAr.trim().isEmpty) {
      nav.toast(GzToastSpec(message: l.hotelProviderEditorDraftNeedsTitle, icon: GzIcons.info));
      return;
    }
    if (await _persist() == null || !mounted) return;
    nav.toast(GzToastSpec(message: l.hotelProviderEditorDraftSaved, tone: GzToastTone.success));
    // opened from the account-type step there is nothing to go back to: land on the listings
    if (nav.canGoBack) {
      nav.pop();
    } else {
      nav.reset('HL-PROV-02');
    }
  }

  Future<void> _next(bool exempt) async {
    final l = context.l10n;
    final nav = GzNavigatorScope.of(context);
    setState(() => _tried = true);
    if (problemsOf(_draft).any) {
      nav.toast(GzToastSpec(message: l.hotelProviderEditorFixFields, tone: GzToastTone.danger));
      return;
    }
    final id = await _persist();
    if (id == null || !mounted) return;
    final k = _listing;
    final mode = k?.status;
    if (mode == ListingStatus.active) {
      nav.replace('HL-PROV-06', params: {'listingId': id});
    } else if (mode == ListingStatus.rejected && k?.planCycle != null) {
      final r = await ref.read(listingActionsProvider.notifier).submit(id);
      if (!mounted) return;
      if (r is ActionFailure<Listing>) {
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, r.problem), tone: GzToastTone.danger));
        return;
      }
      nav.replace('HL-PROV-06', params: {'listingId': id});
    } else {
      nav.push('HL-PROV-04', params: {'listingId': id});
    }
  }

  Future<void> _leave() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    if (!_dirty) return nav.pop();
    final r = await nav.openDialog(
      GzDialogSpec(title: l.hotelProviderGuardTitle, body: l.hotelProviderGuardBody, icon: GzIcons.warning, confirmLabel: l.hotelProviderGuardDiscard, cancelLabel: l.hotelProviderGuardKeep, tone: GzDialogTone.destructive),
    );
    if (r == GzDialogResult.confirm && mounted) nav.pop();
  }

  void _editPackage(PackageDraft? p, int fee) {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final isNew = p == null;
    final initial = p ?? PackageDraft(id: 'pk-new-${_pk++}', isNew: true);
    nav.openSheetBuilder(
      (_) => PackageSheetBody(
        initial: initial,
        isNew: isNew,
        feeFils: fee,
        onSave: (saved) {
          _patch(_draft.copyWith(packages: isNew ? [..._draft.packages, saved] : [for (final x in _draft.packages) x.id == saved.id ? saved : x]));
          nav.closeSheet();
        },
        onDelete: () {
          _patch(_draft.copyWith(packages: [for (final x in _draft.packages) if (x.id != initial.id) x]));
          nav.closeSheet();
        },
      ),
      options: GzSheetOptions(title: isNew ? l.hotelProviderPkgSheetNew : l.hotelProviderPkgSheetEdit),
    );
  }

  Future<void> _addPhoto() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    var id = _id;
    if (id == null) {
      if (_draft.titleEn.trim().isEmpty && _draft.titleAr.trim().isEmpty) {
        nav.toast(GzToastSpec(message: l.hotelProviderEditorDraftNeedsTitle, icon: GzIcons.info));
        return;
      }
      id = await _persist();
      if (id == null || !mounted) return;
    }
    final res = await ref.read(listingActionsProvider.notifier).addPhoto(id);
    if (!mounted) return;
    switch (res) {
      case ActionSuccess(:final value):
        setState(() {
          _draft = _draft.copyWith(photos: [?value.cover]);
          _base = _base.copyWith(photos: [?value.cover]);
        });
      case ActionFailure(:final problem):
        nav.toast(GzToastSpec(message: gzProblemMessage(context.gzL10n, problem), tone: GzToastTone.danger));
      case ActionGated():
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lang = context.gz.locale.languageCode;
    final k = _listing;
    final exempt = ref.watch(partnerBillingProvider).value?.feeExempt ?? false;
    final fee = ref.watch(voucherFeeProvider).value ?? 2000;
    final cats = ref.watch(serviceCategoriesProvider).value ?? const <ServiceCategory>[];
    final busy = ref.watch(listingActionsProvider);
    final problems = problemsOf(_draft);
    final show = _tried;
    final required = l.hotelProviderRequired;
    final live = k?.status == ListingStatus.active;
    final rejected = k?.status == ListingStatus.rejected;
    final label = _saved
        ? l.hotelProviderEditorSaved
        : live
            ? l.hotelProviderEditorSubmitChanges
            : rejected
                ? l.hotelProviderEditorResubmit
                : exempt
                    ? l.hotelProviderStepSubmit
                    : l.hotelProviderEditorContinue;
    final category = cats.where((c) => c.id == _draft.categoryId).firstOrNull;
    final options = [for (final c in cats) GzSelectOption<String>(value: c.id.value, label: c.name.of(lang))];
    final gap = const SizedBox(height: GzSpace.section);
    Widget section(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [GzSectionHeader(title: title, voice: GzHeaderVoice.partner), const SizedBox(height: GzSpace.s4), child],
        );

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: GzScreen(
        top: GzTopBar(title: k == null ? l.hotelProviderEditorTitleNew : l.hotelProviderEditorTitle, onBack: _leave),
        bottom: GzActionBar(
          action: GzActionBarAction(label: label, iconEnd: _saved ? GzIcons.check : GzIcons.chevronRight, loading: busy.isBusyWith('save'), disabled: _saved, onPressed: () => _next(exempt)),
          secondary: live ? null : GzActionBarAction(label: l.hotelProviderEditorSaveDraft, onPressed: _saveDraft),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (live) ...[ProvNote(icon: GzIcons.eye, text: l.hotelProviderEditorLiveNote), gap],
              if (rejected && k?.rejection != null) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderEditorRejectedNote(k!.rejection!.note.of(lang))), gap],
              if (show && problems.any) ...[ProvNote(tone: NoteTone.danger, text: l.hotelProviderEditorValidationNote), gap],
              section(
                l.hotelProviderEditorCategory,
                GzSelectRow<String>(
                  label: l.hotelProviderEditorCategory,
                  options: options,
                  values: [if (_draft.categoryId != null) _draft.categoryId!.value],
                  placeholder: l.hotelProviderEditorCategoryPlaceholder,
                  error: show && problems.category ? required : null,
                  onTap: () {
                    final nav = GzNavigatorScope.of(context);
                    nav.openSheetBuilder(
                      (_) => GzPickerList<String>(
                        options: options,
                        selected: [if (_draft.categoryId != null) _draft.categoryId!.value],
                        onPick: (v) {
                          _patch(_draft.copyWith(categoryId: cats.firstWhere((c) => c.id.value == v).id));
                          nav.closeSheet();
                        },
                      ),
                      options: GzSheetOptions(title: l.hotelProviderEditorCategory),
                    );
                  },
                ),
              ),
              gap,
              section(
                l.hotelProviderEditorTexts,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BilingualField(
                      label: l.hotelProviderEditorTitleField,
                      ar: _draft.titleAr,
                      en: _draft.titleEn,
                      onAr: (v) => _patch(_draft.copyWith(titleAr: v)),
                      onEn: (v) => _patch(_draft.copyWith(titleEn: v)),
                      errorAr: show && problems.titleAr ? required : null,
                      errorEn: show && problems.titleEn ? required : null,
                      maxLength: 60,
                    ),
                    const SizedBox(height: GzSpace.s4),
                    BilingualField(
                      label: l.hotelProviderEditorDescField,
                      ar: _draft.descAr,
                      en: _draft.descEn,
                      onAr: (v) => _patch(_draft.copyWith(descAr: v)),
                      onEn: (v) => _patch(_draft.copyWith(descEn: v)),
                      errorAr: show && problems.descAr ? required : null,
                      errorEn: show && problems.descEn ? required : null,
                      maxLength: 400,
                      multiline: true,
                    ),
                  ],
                ),
              ),
              gap,
              section(
                l.hotelProviderEditorPhotos,
                PhotoStrip(
                  photos: _draft.photos,
                  adding: busy.isBusyWith('photo'),
                  onAdd: _addPhoto,
                  onRemove: (p) => _patch(_draft.copyWith(photos: [for (final x in _draft.photos) if (x.file != p.file) x])),
                ),
              ),
              gap,
              section(l.hotelProviderEditorPackages, PackageCards(packages: _draft.packages, feeFils: fee, onEdit: (p) => _editPackage(p, fee), onAdd: () => _editPackage(null, fee), error: show && problems.packages)),
              gap,
              WhatCouplesSee(draft: _draft, feeFils: fee, category: category?.name),
              gap,
              section(
                l.hotelProviderEditorContact,
                Column(
                  children: [
                    GzToggleRow(title: l.hotelProviderEditorChat, checked: _draft.chat, onChanged: (v) => _patch(_draft.copyWith(chat: v))),
                    GzToggleRow(title: l.hotelProviderEditorPhone, checked: _draft.showPhone, onChanged: (v) => _patch(_draft.copyWith(showPhone: v)), divider: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorSkeleton extends StatelessWidget {
  const _EditorSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2),
        child: GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 240),
      );
}
