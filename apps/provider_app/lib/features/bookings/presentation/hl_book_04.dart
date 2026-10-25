// HL-BOOK-04 Contact client (sheet; web `HL-BOOK-04.tsx`). Requirement IDs: HA-BOOK-06, HA-BOOK-07, HA-AUTH-02.
// "Reach this client" in one tap: call the contact person, message in the app, or open WhatsApp. A number shows only once the client shared it;
// until then one short line says so and Chat stays. Call and WhatsApp say what they would do (a toast): the app never leaves itself here.
// Text diet (ADR 0034): the client's name is the title; three rows are a glyph, one word and the number; the privacy sentence is behind the
// info glyph beside the close. Params: `bookingId` (default: the hero request).
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView;
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/bookings_data.dart';
import '../application/detail_model.dart';
import 'widgets/bk_sheet.dart';
import 'widgets/booking_actions.dart';

class HlBook04Screen extends ConsumerWidget {
  const HlBook04Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final c = context.gz.colors;
    final nav = context.gzNav;
    final id = (nav.params['bookingId'] as String?) ?? kHeroBookingId;
    final async = ref.watch(bookingDetailProvider(id));
    final role = roleOf(ref.watch(partnerContextProvider));
    final b = async.value?.booking;
    final allowed = canContact(role);
    final act = BookingActions(context, ref);

    Widget body(PartnerRequestDetail d) {
      final k = d.booking;
      final shared = k.contact.shared;
      final phone = k.contact.phone;
      final name = isolate(k.contact.name);
      Widget number() => GzLtr(child: GzText(phone, role: GzTextRole.figBodyS, color: c.textSecondary, figures: true, softWrap: false));
      if (!allowed) {
        return GzEmptyState(
          illustration: GzIllustrationName.shield,
          title: cl.commonStateTitleNoAccess,
          detailTitle: cl.commonLabelDetails,
          detail: l.hotelBookingsRoleNoContact,
          fill: false,
          size: GzIllustrationSize.lg,
        );
      }
      return Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (shared)
              GzIconListRow(flush: true, icon: GzIcons.phone, title: cl.commonActionCall, trailing: number(), onPressed: () => nav.toast(GzToastSpec(message: l.hotelBookingsCallToast(name), icon: GzIcons.phone)))
            else
              Container(
                constraints: const BoxConstraints(minHeight: GzSize.rowMin),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.borderHairline, width: GzStroke.hair))),
                child: Row(
                  children: [
                    GzIcon(GzIcons.info, size: GzIconSize.sm, tone: GzIconTone.accent),
                    const SizedBox(width: GzSpace.s2),
                    Expanded(child: GzText(l.hotelBookingsNotShared, role: GzTextRole.bodyS, color: c.textPrimary)),
                  ],
                ),
              ),
            GzIconListRow(
              flush: true,
              icon: GzIcons.chat,
              title: l.hotelBookingsChatRow,
              last: !shared,
              onPressed: () {
                nav.closeSheet();
                act.chatBooking(k, conversationId: d.conversationId);
              },
            ),
            if (shared) GzIconListRow(flush: true, last: true, icon: GzIcons.whatsapp, title: cl.commonActionWhatsapp, trailing: number(), onPressed: () => nav.toast(GzToastSpec(message: l.hotelBookingsWhatsappToast(name), icon: GzIcons.whatsapp))),
          ],
        ),
      );
    }

    return BkSheet(
      title: b?.clientName ?? '',
      titleWidget: b == null ? null : GzUserText(b.clientName, role: GzTextRole.uiTitle, color: c.textStrong),
      info: allowed ? [l.hotelBookingsContactPrivacy] : null,
      infoTitle: cl.commonLabelDetails,
      children: [
        GzAsyncView<PartnerRequestDetail>(
          value: async,
          loading: const GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 192),
          onRetry: () => ref.invalidate(bookingDetailProvider),
          data: body,
        ),
      ],
    );
  }
}
