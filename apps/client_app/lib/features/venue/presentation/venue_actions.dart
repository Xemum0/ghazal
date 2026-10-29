import 'package:client_app/app/state/state.dart';
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import 'widgets/venue_sheets.dart';

/// What a quote carries into the voucher explainer and the request (CL-VCHR-01, CL-BOOK-01): the page's own choices on top of the Brief.
@immutable
final class QuoteCarry {
  const QuoteCarry({required this.venueId, this.hallId, this.sessionId, this.packageId, this.date, this.guests, this.audience});

  final String venueId;
  final String? hallId;
  final String? sessionId;
  final String? packageId;
  final LocalDate? date;
  final int? guests;
  final Audience? audience;

  Map<String, Object?> get params => <String, Object?>{
    'venueId': venueId,
    'hallId': hallId,
    'sessionId': sessionId,
    'packageId': packageId,
    'eventDate': date?.toString(),
    'guests': guests,
    'audience': audience?.value,
    'from': 'venue',
  };
}

/// What a tap does on the venue detail (CL-VENU-01 and CL-VENU-06): every edge of the inventory's `navigatesTo`, wired once, by route
/// name through the navigator. Every client is signed in (ADR 0038), so no action meets a gate.
class VenueActions {
  VenueActions(this.context, this.ref, this.venueId);

  final BuildContext context;
  final WidgetRef ref;
  final String venueId;

  GzNavigator get _nav => context.gzNav;
  AppL10n get _l => context.l10n;

  /// Heart: saved to the account's list.
  Future<void> toggleFavourite() async {
    final notifier = ref.read(favouritesProvider.notifier);
    final on = await notifier.toggle(SavedType.venue, venueId);
    if (!context.mounted) return;
    _nav.toast(
      GzToastSpec(
        message: on ? context.gzL10n.commonStateSaved : _l.clientVenueSavedRemoved,
        icon: on ? GzIcons.heartFill : null,
        undo: !on,
        action: on
            ? GzToastAction(label: _l.clientVenueSavedView, onPressed: () => _nav.switchTab('saved'))
            : GzToastAction(label: context.gzL10n.commonActionUndo, onPressed: () => notifier.toggle(SavedType.venue, venueId)),
      ),
    );
  }

  /// Compare toggle (a header badge on this page). Already in the set: the badge opens the tray sheet. The fourth add asks which one to
  /// replace.
  void toggleCompare() {
    final notifier = ref.read(compareProvider.notifier);
    if (ref.read(compareProvider).contains(venueId)) {
      _nav.openSheet('CL-SAVD-02');
      return;
    }
    if (notifier.add(venueId) == CompareResult.full) {
      _nav.openSheet('CL-SAVD-03', options: GzSheetOptions(params: <String, Object?>{'incoming': venueId}));
      return;
    }
    final count = ref.read(compareProvider).venueIds.length;
    _nav.toast(
      GzToastSpec(
        message: _l.clientVenueCompareAdded,
        icon: GzIcons.compare,
        action: count >= 2 ? GzToastAction(label: _l.clientVenueCompareView, onPressed: () => _nav.push('CL-SAVD-04')) : null,
      ),
    );
  }

  /// Share: the OS sheet carries a universal link (F4); the toast says the link is on the clipboard.
  void share() => _nav.toast(GzToastSpec(message: _l.clientVenueShareCopied, icon: GzIcons.link, tone: GzToastTone.success));

  void openCalendar([String? hallId]) => _nav.openSheet('CL-VENU-03', options: GzSheetOptions(params: <String, Object?>{'venueId': venueId, 'hallId': hallId}));

  /// The Brief owns date and guests; its sheet is the one editor (CL-DISC-02).
  void editBrief() => _nav.openSheet('CL-DISC-02', options: const GzSheetOptions(params: <String, Object?>{'focus': 'guests'}));

  void openPackage(String packageId, [String? hallId]) =>
      _nav.openSheet('CL-VENU-04', options: GzSheetOptions(params: <String, Object?>{'venueId': venueId, 'packageId': packageId, 'hallId': hallId}));

  void openPolicies(String segment, [String? hallId]) =>
      _nav.openSheet('CL-VENU-05', options: GzSheetOptions(params: <String, Object?>{'venueId': venueId, 'segment': segment, 'hallId': hallId}));

  /// Closes the sheet this action runs in and lets the navigator settle (its list of open sheets decides whether the next sheet gets a
  /// scrim, and it is updated one event-loop turn after the pop).
  Future<void> _closeSheet(GzNavigator nav) {
    nav.closeSheet();
    return Future<void>.delayed(Duration.zero);
  }

  /// Get voucher: the explainer bound to this quote (CL-VCHR-01). Every client is signed in (ADR 0038), so there is no gate before it.
  ///
  /// [closeSheet]: called from a sheet (the calendar, CL-VENU-03): it gives way to the explainer instead of staying open underneath the
  /// whole pay flow, where it would also keep the app's own sheet (the Face ID offer) waiting for ever.
  Future<void> getVoucher(QuoteCarry c, {bool closeSheet = false}) async {
    final nav = _nav; // taken while the context is alive: the entry navigator forwards every action to the app's one navigator
    ref
        .read(bookingDraftProvider.notifier)
        .start(venueId: venueId, hallId: c.hallId, sessionId: c.sessionId, packageId: c.packageId, eventDate: c.date, guests: c.guests, audience: c.audience);
    if (closeSheet) await _closeSheet(nav);
    nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: c.params));
  }

  void openHow(QuoteCarry c) => _nav.openSheet('CL-VCHR-01', options: GzSheetOptions(params: <String, Object?>{...c.params, 'mode': 'explain'}));

  /// Send request with a ready voucher: the booking flow opens with the quote and the voucher carried over (CL-BOOK-01).
  Future<void> sendRequest(QuoteCarry c, Voucher voucher, {bool closeSheet = false}) async {
    final nav = _nav;
    final draft = ref.read(bookingDraftProvider.notifier);
    draft.start(venueId: venueId, hallId: c.hallId, sessionId: c.sessionId, packageId: c.packageId, eventDate: c.date, guests: c.guests, audience: c.audience);
    draft.patch((d) => d.copyWith(voucherId: voucher.id));
    if (closeSheet) await _closeSheet(nav);
    nav.push('CL-BOOK-01', params: <String, Object?>{'venueId': venueId});
  }

  /// Book a visit (CL-VIST-01): no voucher needed.
  void bookVisit() => _nav.openSheet('CL-VIST-01', options: GzSheetOptions(params: <String, Object?>{'venueId': venueId}));

  /// Contact the venue, the browse-only path: the in-app chat (CL-MSGS-02).
  void contactVenue() => _nav.push('CL-MSGS-02', params: <String, Object?>{'venueId': venueId});

  void openReviews() => _nav.push('CL-RVRW-01', params: <String, Object?>{'venueId': venueId});

  void openSimilar(VenueSummary v) =>
      _nav.push(v.channel == BookingChannel.externalLink ? 'CL-VENU-06' : 'CL-VENU-01', params: <String, Object?>{'venueId': v.id, 'from': 'venue'});

  void openMaps() => _nav.openSheetBuilder((_) => const VenueMapsSheet(), options: GzSheetOptions(title: _l.clientVenueMapsTitle));
}
