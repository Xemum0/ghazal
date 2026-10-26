import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_ui/ghazal_ui.dart' show GzSheetOptions;

import 'search_brief.dart';
import 'sheet_queue.dart';
import 'wedding_profile.dart';

/// The home of the Brief: the merge sheet opens only when this screen is the visible one (prototype `CL-DISC-01.tsx`).
const String kBriefMergeScreen = 'CL-DISC-01';

/// Once after a sign-in: when the account already holds a different Brief than this phone, the merge variant of the Brief sheet
/// (CL-DISC-02, `variant: merge`) lets the person choose. A request to the [sheetQueue](sheet_queue.dart), not a sheet opened on the
/// spot: it waits for Home, 400 ms after Home is the visible screen and nothing else is open, so a sign-in raised from the voucher
/// explainer or the booking flow never has this sheet stacked over it. A sign-in and a Home that mounts both ask; it is one sheet.
final Provider<QueuedSheet> briefMergeSheetProvider = Provider<QueuedSheet>(
  (ref) => QueuedSheet(
    id: 'brief-merge',
    screen: kBriefMergeScreen,
    delay: const Duration(milliseconds: 400),
    worthShowing: () async {
      final device = ref.read(searchBriefProvider);
      if (device.isEmpty) return false;
      final profile = await ref.read(weddingProfileProvider.future);
      if (profile == null) return false;
      final account = SearchBrief.fromWedding(
        weddingDate: profile.weddingDate,
        dateMode: profile.dateMode,
        womenGuests: profile.guests.women,
        searching: profile.searching,
        areaIds: profile.areaIds,
        venueBudget: profile.venueBudget,
      );
      // A conflict is something this phone has set that the account answers differently; a blank on the phone is not one.
      final sameAreas = Set<String>.of(device.areaIds).containsAll(account.areaIds) && Set<String>.of(account.areaIds).containsAll(device.areaIds);
      return (device.date != null && device.date != account.date) || (device.guests != null && device.guests != account.guests) || (device.areaIds.isNotEmpty && !sameAreas);
    },
    open: (nav, onClose) => nav.openSheet('CL-DISC-02', options: GzSheetOptions(params: const <String, Object?>{'variant': 'merge'}, onClose: onClose)),
  ),
);
