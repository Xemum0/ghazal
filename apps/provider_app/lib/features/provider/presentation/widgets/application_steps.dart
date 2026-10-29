// The two other steps of HL-PROV-01 (web `HL-PROV-01.tsx`): the account type to apply as (a service provider or a private hall; a hotel or a hall
// chain is onboarded by Ghazal) and "Application received" (the account stays under review, what happens next).
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/application_form.dart';
import 'account_cards.dart';
import 'prov_bits.dart';

const EdgeInsetsDirectional _pad = EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s8);

/// Step 1: two large choice cards (one choice, then Continue) and a quiet line for hotels and chains.
class ApplyChoose extends StatelessWidget {
  const ApplyChoose({required this.kind, required this.onPick, super.key});

  final ApplicantKind? kind;
  final ValueChanged<ApplicantKind> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(alignment: AlignmentDirectional.centerStart, child: GzText(l.hotelProviderChooseTitle, role: GzTextRole.uiXl, color: context.gz.colors.textStrong)),
          const SizedBox(height: GzSpace.s5),
          AccountCard(
            icon: GzIcons.megaphone,
            title: l.hotelProviderTypeProviderTitle,
            facts: const [GzIcons.catering, GzIcons.flower, GzIcons.camera],
            selected: kind == ApplicantKind.serviceProvider,
            onTap: () => onPick(ApplicantKind.serviceProvider),
          ),
          const SizedBox(height: GzSpace.s4),
          AccountCard(
            icon: GzIcons.hall,
            title: l.hotelProviderTypeHallTitle,
            facts: const [GzIcons.calendar, GzIcons.chat, GzIcons.ticket],
            selected: kind == ApplicantKind.privateHall,
            onTap: () => onPick(ApplicantKind.privateHall),
          ),
          const SizedBox(height: GzSpace.s5),
          ProvNote(tone: NoteTone.quiet, icon: GzIcons.hotel, text: l.hotelProviderChooseChains),
        ],
      ),
    );
  }
}

/// Step 3: "Application received". The business, then what happens next as three glyph rows.
class ApplyReceived extends StatelessWidget {
  const ApplyReceived({required this.name, required this.hall, super.key});

  final String name;
  final bool hall;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Padding(
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(alignment: AlignmentDirectional.centerStart, child: GzIllustration(GzIllustrationName.partnerReview, size: GzIllustrationSize.lg)),
          const SizedBox(height: GzSpace.s3),
          Align(alignment: AlignmentDirectional.centerStart, child: GzText(l.hotelProviderSubmittedTitle, role: GzTextRole.uiXl, color: c.textStrong)),
          const SizedBox(height: GzSpace.s3),
          Align(alignment: AlignmentDirectional.centerStart, child: GzText(l.hotelProviderSubmittedLine, role: GzTextRole.body, color: c.textSecondary)),
          const SizedBox(height: GzSpace.s5),
          Row(
            children: [
              GzAvatar(name: name, voice: GzAvatarVoice.sans),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzUserText(name, role: GzTextRole.title, color: c.textStrong)),
              GzIcon(hall ? GzIcons.hall : GzIcons.megaphone, size: GzIconSize.md, color: c.iconSecondary),
            ],
          ),
          const SizedBox(height: GzSpace.s5),
          Semantics(
            container: true,
            label: l.hotelProviderSubmittedNext,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(l.hotelProviderSubmittedNext, role: GzTextRole.label, color: c.textSecondary),
                const SizedBox(height: GzSpace.s1),
                GzIconListRow(flush: true, icon: GzIcons.clipboard, title: l.hotelProviderNextReview),
                const SizedBox(height: GzSpace.s1), // `.hp01__next { gap: space-1 }`: the web stacks the rows 4 dp apart (69 dp pitch)
                GzIconListRow(flush: true, icon: GzIcons.mail, title: l.hotelProviderNextEmail),
                const SizedBox(height: GzSpace.s1),
                GzIconListRow(flush: true, last: true, icon: GzIcons.megaphone, title: l.hotelProviderNextListings),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
