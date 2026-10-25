// Quiet hours (CL-PROF-04). Two windows, both configuration until the owner confirms them (OQ-L-15): offers and news are held 10 PM to
// 9 AM; booking and payment alerts still arrive but silently between 11 PM and 8 AM. Nothing here is edited yet, so the one action is Done.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/profile_state.dart';

/// `10:00 PM – 9:00 AM` in the current language, from the two civil times (Kuwait).
String quietRange(WidgetRef ref, QuietWindow w) {
  final f = ref.watch(gzFormatProvider);
  return f.timeRange(f.kuwaitDate(2027, 1, 1, hour: w.from.$1, minute: w.from.$2), f.kuwaitDate(2027, 1, 2, hour: w.to.$1, minute: w.to.$2));
}

class QuietSheet extends ConsumerWidget {
  const QuietSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    Widget window(QuietWindow w) => GzFactChip(icon: GzIcons.moon, value: quietRange(ref, w), label: l.clientProfileNotifQuiet);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzIconListRow(flush: true, icon: GzIcons.offer, title: l.clientProfileNotifQuietOffers, facts: window(kQuietMarketing)),
        GzIconListRow(flush: true, icon: GzIcons.bell, title: l.clientProfileNotifQuietAlerts, facts: window(kQuietAlerts), last: true),
        GzSheetFooter(child: GzButton(label: l.commonActionDone, fullWidth: true, onPressed: context.gzNav.closeSheet)),
      ],
    );
  }
}
