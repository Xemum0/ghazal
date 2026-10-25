// The pieces of the redeem screen (web `Redeem.tsx`, ADR 0034): the scanner viewfinder (a drawn frame and a torch, no caption), the code field,
// the quote of a code that can be redeemed (the voucher price as one figure with the standard struck, the client, the date, the hall, the
// package, the guests), the calm outcomes (a drawing, a title of at most four words, one fact, one action, the reason behind an info glyph) and
// the demo chips (one live code per outcome). The camera is a drawn viewfinder: the prototype never opens one.
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ghazal_domain/ghazal_domain.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';
import '../../application/redeem_data.dart';
import '../../application/redeem_model.dart';
import 'bk_bits.dart';
import 'detail_parts.dart';
import 'triage_card.dart' show BkStruckMoney;

class Viewfinder extends StatelessWidget {
  const Viewfinder({required this.torch, required this.onTorch, required this.onScan, super.key});

  final bool torch;
  final VoidCallback onTorch;
  final VoidCallback onScan;

  Widget _corner(Color color, {required bool top, required bool start}) {
    final s = BorderSide(width: GzStroke.threadMax, color: color);
    return PositionedDirectional(
      top: top ? GzSpace.s12 : null,
      bottom: top ? null : GzSpace.s12,
      start: start ? GzSpace.s12 : null,
      end: start ? null : GzSpace.s12,
      width: GzSpace.s8,
      height: GzSpace.s8,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(
            top: top ? s : BorderSide.none,
            bottom: top ? BorderSide.none : s,
            start: start ? s : BorderSide.none,
            end: start ? BorderSide.none : s,
          ),
          borderRadius: BorderRadiusDirectional.only(
            topStart: top && start ? const Radius.circular(GzRadius.md) : Radius.zero,
            topEnd: top && !start ? const Radius.circular(GzRadius.md) : Radius.zero,
            bottomStart: !top && start ? const Radius.circular(GzRadius.md) : Radius.zero,
            bottomEnd: !top && !start ? const Radius.circular(GzRadius.md) : Radius.zero,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              height: 360,
              decoration: BoxDecoration(color: c.surfaceDark, borderRadius: GzRadius.mdAll),
              child: ExcludeSemantics(
                child: Stack(
                  children: [
                    Center(child: GzIcon(GzIcons.qrCode, size: GzIconSize.lg, color: c.textOnDarkMuted)),
                    _corner(c.textOnDark, top: true, start: true),
                    _corner(c.textOnDark, top: true, start: false),
                    _corner(c.textOnDark, top: false, start: true),
                    _corner(c.textOnDark, top: false, start: false),
                    PositionedDirectional(start: GzSpace.s12, end: GzSpace.s12, top: 360 * 0.66, height: GzStroke.hair, child: ColoredBox(color: c.markKhayt)),
                  ],
                ),
              ),
            ),
            PositionedDirectional(
              top: GzSpace.s1,
              end: GzSpace.s1,
              child: GzIconButton(icon: GzIcons.bolt, label: torch ? l.hotelBookingsTorchOff : l.hotelBookingsTorchOn, variant: GzIconButtonVariant.onScrim, active: torch, onPressed: onTorch),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s3),
        Center(child: GzButton(label: l.hotelBookingsScanDemo, variant: GzButtonVariant.tertiary, iconStart: GzIcons.scan, onPressed: onScan)),
      ],
    );
  }
}

/// Uppercases and groups what is typed as `2611-K7QM`.
class CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = formatTyped(newValue.text);
    return TextEditingValue(text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class CodeField extends StatelessWidget {
  const CodeField({required this.value, required this.onChanged, this.error, this.loading = false, this.onSubmit, super.key});

  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final bool loading;
  final VoidCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GzTextField(
        label: context.gzL10n.commonVoucherCode,
        value: value,
        dir: GzFieldDir.ltr,
        onValueChange: (v) => onChanged(formatTyped(v)),
        onSubmitted: (_) => onSubmit?.call(),
        textAlign: TextAlign.start,
        placeholder: '2611-K7QM',
        maxLength: 9,
        autocorrect: false,
        enableSuggestions: false,
        textCapitalization: TextCapitalization.characters,
        inputFormatters: [CodeFormatter()],
        error: error,
        loading: loading,
        startAdornment: GzText(kCodePrefix, role: GzTextRole.figTitle, color: c.textSecondary, figures: true, softWrap: false),
      ),
    );
  }
}

class QuoteCard extends StatelessWidget {
  const QuoteCard({required this.booking, required this.voucher, required this.hallName, required this.packageName, super.key});

  final Booking booking;
  final Voucher voucher;
  final String hallName;
  final String packageName;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    final c = context.gz.colors;
    final first = booking.clientName.trim().split(RegExp(r'\s+')).first;
    final t = booking.totals;
    final guests = booking.sections.fold<int>(0, (n, s) => n + s.guests);
    return BkPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ExcludeSemantics(child: GzAvatar(name: booking.clientName, size: GzAvatarSize.sm, voice: GzAvatarVoice.sans)),
              const SizedBox(width: GzSpace.s3),
              Expanded(child: GzUserText(first, role: GzTextRole.title, color: c.textStrong)),
              const SizedBox(width: GzSpace.s3),
              GzVoucherChip(code: voucher.code),
              const SizedBox(width: GzSpace.s1),
              GzInfoButton(title: cl.uiSharedVoucher, paragraphs: [l.hotelBookingsRedeemFine]),
            ],
          ),
          const SizedBox(height: GzSpace.s3),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Semantics(label: cl.commonVoucherPrice, child: GzPrice(fils: t.voucherTotal.fils, mode: GzMoneyMode.exact, size: GzPriceSize.total)),
          ),
          if (t.standardTotal.fils > t.voucherTotal.fils) ...[
            const SizedBox(height: GzSpace.s1),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: GzSpace.s5,
              runSpacing: GzSpace.s1,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [GzIcon(GzIcons.offer, size: GzIconSize.xs, tone: GzIconTone.secondary), const SizedBox(width: GzSpace.s1), BkStruckMoney(fils: t.standardTotal.fils, label: cl.commonStandardPrice, exact: true)]),
                Row(mainAxisSize: MainAxisSize.min, children: [GzIcon(GzIcons.trendDown, size: GzIconSize.xs, tone: GzIconTone.success), const SizedBox(width: GzSpace.s1), BkQuietMoney(fils: t.savings.fils, label: l.hotelBookingsClientSaves, color: c.textSuccess)]),
              ],
            ),
          ],
          const SizedBox(height: GzSpace.s3),
          BkLines(
            lines: [
              if (hallName.isNotEmpty) BkLine(icon: GzIcons.hall, label: l.hotelBookingsRowHall, child: GzUserText(hallName, role: GzTextRole.title, color: c.textStrong)),
              if (packageName.isNotEmpty) BkLine(icon: GzIcons.package, label: l.hotelBookingsRowPackage, child: GzUserText(packageName, role: GzTextRole.title, color: c.textStrong)),
              BkLine(
                icon: GzIcons.calendar,
                label: l.hotelBookingsRowDate,
                facts: GzFactRow(label: l.hotelBookingsFactsLabel, children: [GzFactChip(icon: GzIcons.usersThree, label: l.hotelBookingsFactGuests, value: f.integer(guests))]),
                child: GzText(f.date(booking.eventDate.toString()), role: GzTextRole.title, color: c.textStrong, figures: true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The calm outcome of a code that cannot be redeemed: a drawing, a short title, one fact, one action, the reason behind the info glyph.
class ResultNotice extends StatelessWidget {
  const ResultNotice({required this.outcome, required this.onAgain, super.key});

  final RedeemOutcome outcome;
  final VoidCallback onAgain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final cl = context.gzL10n;
    final f = context.gzFormat;
    GzIllustrationName art = GzIllustrationName.noResult;
    String title = l.hotelBookingsErrUnknownTitle;
    String detail = l.hotelBookingsErrUnknownBody;
    Widget? fact;
    switch (outcome) {
      case OutcomeOtherPartner():
        art = GzIllustrationName.shield;
        title = l.hotelBookingsErrOtherTitle;
        detail = l.hotelBookingsErrOtherBody;
      case OutcomeNotConfirmed(:final booking):
        art = GzIllustrationName.hourglass;
        title = l.hotelBookingsErrNotConfirmedTitle;
        detail = l.hotelBookingsErrNotConfirmedBody;
        final by = booking?.confirmBy;
        if (by != null) {
          final left = durationOf(context, minutesBetween(f.now(), by), lead: true);
          fact = GzFactRow(
            label: l.hotelBookingsConfirmLeft(left.spoken),
            children: [GzFactChip(icon: GzIcons.hourglass, tone: GzFactTone.accent, label: l.hotelBookingsConfirmLeft(left.spoken), value: left.visual)],
          );
        }
      case OutcomeAlreadyUsed(:final usedAt):
        art = GzIllustrationName.seal;
        title = l.hotelBookingsErrUsedPlain;
        detail = l.hotelBookingsErrUsedBody;
        if (usedAt != null) {
          fact = GzFactRow(
            label: l.hotelBookingsErrUsedPlain,
            children: [
              GzFactChip(icon: GzIcons.calendar, label: l.hotelBookingsRowDate, value: dayLine(f, LocalDate.parse(f.isoDay(usedAt)), year: true)),
              GzFactChip(icon: GzIcons.clock, label: l.hotelBookingsRowTime, value: f.time(usedAt)),
            ],
          );
        }
      case OutcomeExpired():
        art = GzIllustrationName.clock;
        title = l.hotelBookingsErrExpiredTitle;
        detail = l.hotelBookingsErrExpiredBody;
      default:
    }
    return Semantics(
      liveRegion: true,
      container: true,
      child: GzEmptyState(
        illustration: art,
        title: title,
        detail: detail,
        detailTitle: cl.commonLabelDetails,
        facts: fact,
        fill: false,
        size: GzIllustrationSize.lg,
        action: GzStateAction(label: l.hotelBookingsTryAnother, variant: GzButtonVariant.secondary, iconStart: GzIcons.scan, onPressed: onAgain),
      ),
    );
  }
}

/// One live code per outcome so every state is reachable by tapping. Quiet by design (glyph chips, no sentence); a demo aid, not product UI.
class ProtoShortcuts extends StatelessWidget {
  const ProtoShortcuts({required this.codes, required this.onPick, super.key});

  final SampleCodes codes;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final items = <(IconData, String, String?)>[
      (GzIcons.ticket, l.hotelBookingsProtoReady, codes.ready),
      (GzIcons.hourglass, l.hotelBookingsProtoNotConfirmed, codes.notConfirmed),
      (GzIcons.checkDouble, l.hotelBookingsProtoUsed, codes.used),
    ].where((i) => i.$3 != null).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Semantics(
      container: true,
      label: l.hotelBookingsProtoTitle,
      child: Container(
        padding: const EdgeInsets.only(top: GzSpace.s3),
        decoration: BoxDecoration(border: Border(top: BorderSide(color: c.borderStrong, width: GzStroke.hair))),
        child: Row(
          children: [
            Expanded(child: GzText(l.hotelBookingsProtoTag, role: GzTextRole.label, color: c.textSecondary)),
            for (final i in items) GzIconButton(icon: i.$1, iconSize: GzIconSize.sm, label: i.$2, variant: GzIconButtonVariant.outline, onPressed: () => onPick(i.$3!)),
          ],
        ),
      ),
    );
  }
}
