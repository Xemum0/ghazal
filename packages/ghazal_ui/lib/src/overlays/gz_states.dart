import 'package:flutter/widgets.dart';

import '../core/core.dart';
import '../foundation.dart';
import '../nav/gz_nav_scope.dart';
import 'gz_sheet.dart';

/// The one action of a state composition.
@immutable
class GzStateAction {
  const GzStateAction({required this.label, this.onPressed, this.variant, this.iconStart, this.loading = false});

  final String label;
  final VoidCallback? onPressed;
  final GzButtonVariant? variant;
  final IconData? iconStart;
  final bool loading;
}

enum GzStateTone { neutral, danger }

/// Which composition: drives the default action variant (a success action is the gold primary) and the semantics.
enum GzStateKind { empty, success, error }

/// The drawing a glyph stands for, so a caller that passes only an `icon` gets the matching illustration (web `ART`).
GzIllustrationName? gzIllustrationForIcon(IconData icon) => _art()[icon.codePoint];

Map<int, GzIllustrationName>? _artCache;

Map<int, GzIllustrationName> _art() => _artCache ??= {
      for (final e in <(IconData, GzIllustrationName)>[
        (GzIcons.heart, GzIllustrationName.emptySaved),
        (GzIcons.heartFill, GzIllustrationName.emptySaved),
        (GzIcons.bookmark, GzIllustrationName.emptySaved),
        (GzIcons.bookmarkFill, GzIllustrationName.emptySaved),
        (GzIcons.star, GzIllustrationName.emptySaved),
        (GzIcons.search, GzIllustrationName.noResult),
        (GzIcons.filter, GzIllustrationName.noResult),
        (GzIcons.offline, GzIllustrationName.wifiOff),
        (GzIcons.lock, GzIllustrationName.shield),
        (GzIcons.shieldCheck, GzIllustrationName.shield),
        (GzIcons.warning, GzIllustrationName.warning),
        (GzIcons.warningCircle, GzIllustrationName.warning),
        (GzIcons.xCircle, GzIllustrationName.warning),
        (GzIcons.card, GzIllustrationName.card),
        (GzIcons.chat, GzIllustrationName.emptyMessages),
        (GzIcons.chatText, GzIllustrationName.emptyMessages),
        (GzIcons.mail, GzIllustrationName.emptyMessages),
        (GzIcons.calendar, GzIllustrationName.emptyBookings),
        (GzIcons.calendarCheck, GzIllustrationName.emptyBookings),
        (GzIcons.calendarPlus, GzIllustrationName.emptyBookings),
        (GzIcons.calendarDots, GzIllustrationName.emptyBookings),
        (GzIcons.calendarX, GzIllustrationName.emptyBookings),
        (GzIcons.clipboard, GzIllustrationName.emptyBookings),
        (GzIcons.checklist, GzIllustrationName.emptyBookings),
        (GzIcons.document, GzIllustrationName.emptyBookings),
        (GzIcons.ticket, GzIllustrationName.emptyVouchers),
        (GzIcons.offer, GzIllustrationName.emptyVouchers),
        (GzIcons.gift, GzIllustrationName.emptyVouchers),
        (GzIcons.bell, GzIllustrationName.emptyNotifications),
        (GzIcons.pin, GzIllustrationName.emptyVisits),
        (GzIcons.map, GzIllustrationName.emptyVisits),
        (GzIcons.navigate, GzIllustrationName.emptyVisits),
        (GzIcons.door, GzIllustrationName.emptyVisits),
        (GzIcons.key, GzIllustrationName.emptyVisits),
        (GzIcons.hall, GzIllustrationName.emptyResults),
        (GzIcons.venue, GzIllustrationName.emptyResults),
        (GzIcons.hotel, GzIllustrationName.emptyResults),
        (GzIcons.home, GzIllustrationName.emptyResults),
        (GzIcons.team, GzIllustrationName.emptyMessages),
        (GzIcons.guests, GzIllustrationName.emptyMessages),
        (GzIcons.staff, GzIllustrationName.emptyMessages),
        (GzIcons.usersThree, GzIllustrationName.emptyMessages),
        (GzIcons.qrCode, GzIllustrationName.qr),
        (GzIcons.scan, GzIllustrationName.partnerScanner),
        (GzIcons.megaphone, GzIllustrationName.partnerAds),
        (GzIcons.clock, GzIllustrationName.hourglass),
        (GzIcons.clockOff, GzIllustrationName.hourglass),
        (GzIcons.hourglass, GzIllustrationName.hourglass),
        (GzIcons.check, GzIllustrationName.seal),
        (GzIcons.checkCircle, GzIllustrationName.seal),
        (GzIcons.checkDouble, GzIllustrationName.seal),
        (GzIcons.verified, GzIllustrationName.seal),
        (GzIcons.camera, GzIllustrationName.camera),
        (GzIcons.gallery, GzIllustrationName.camera),
        (GzIcons.image, GzIllustrationName.camera),
        (GzIcons.wallet, GzIllustrationName.card),
        (GzIcons.money, GzIllustrationName.card),
        (GzIcons.coins, GzIllustrationName.card),
        (GzIcons.receipt, GzIllustrationName.emptyBookings),
        (GzIcons.chartLine, GzIllustrationName.emptyResults),
        (GzIcons.chartBar, GzIllustrationName.emptyResults),
        (GzIcons.chartUp, GzIllustrationName.emptyResults),
      ])
        e.$1.codePoint: e.$2,
    };

int _words(String s) => s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

/// A helper is a fragment of six words or fewer; anything longer is a paragraph and belongs behind the info glyph.
const int gzStateHelperWords = 6;

/// EmptyState (ADR 0034, docs/design/02-text-diet.md section 5): one composition, an illustration, a title of at most four words and
/// one action. The sentence that used to sit under the title is not on the screen: [detail] opens it from an info glyph (the
/// error-recovery exception), and a legacy [body] is treated the same way unless it is a helper of six words or fewer.
/// Single-purpose state screens centre their one composition (ADR 0034 D7); content screens never do.
class GzEmptyState extends StatelessWidget {
  const GzEmptyState({
    this.illustration,
    this.icon,
    this.title,
    this.body,
    this.detail,
    this.detailTitle,
    this.action,
    this.secondary,
    this.tone = GzStateTone.neutral,
    this.artTone,
    this.fill = true,
    this.size,
    this.center = true,
    this.facts,
    this.flush = false,
    this.kind,
    super.key,
  });

  /// The drawing. Without it, [icon] is mapped to one, else a quiet shelf (or the warning triangle for the danger tone).
  final GzIllustrationName? illustration;

  /// Legacy: a glyph; it only selects the illustration.
  final IconData? icon;

  /// At most four words.
  final String? title;

  /// Legacy and helper text: six words or fewer render as a quiet caption; longer text moves behind the info glyph.
  final String? body;

  /// The paragraph behind the info glyph (error recovery, a rule).
  final String? detail;

  /// Sheet title of the detail (at most three words). Default: "Details".
  final String? detailTitle;
  final GzStateAction? action;

  /// A second, quieter way out (tertiary).
  final GzStateAction? secondary;
  final GzStateTone tone;

  /// Rebinds the drawing's colour roles (the drawing never changes).
  final GzIllustrationTone? artTone;

  /// `true` takes the top-third position of a whole-screen blank (padding 48 above); `false` hugs its content (a blank inside a list).
  final bool fill;

  /// `hero` (200) for a whole screen, `lg` (144) inside a list. Default follows [fill].
  final GzIllustrationSize? size;

  /// Centred (default) or aligned to inline-start.
  final bool center;

  /// One line of facts between the title and the action (the date and time of a booked visit).
  final Widget? facts;

  /// Drops the state's own gutter and block padding, for a state placed inside a shelf or body that already has them.
  final bool flush;
  final GzStateKind? kind;

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    final l10n = context.gzL10n;
    final app = GzAppScope.of(context);
    final name = illustration ?? (icon == null ? null : gzIllustrationForIcon(icon!)) ?? (tone == GzStateTone.danger ? GzIllustrationName.warning : GzIllustrationName.shelf);
    final bodyIsHelper = body != null && _words(body!) <= gzStateHelperWords;
    final info = detail ?? (body != null && !bodyIsHelper ? body : null);
    final helper = body != null && bodyIsHelper ? body : null;
    final role = kind ?? (tone == GzStateTone.danger ? GzStateKind.error : GzStateKind.empty);
    final cross = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final artSize = size ?? (fill ? GzIllustrationSize.hero : GzIllustrationSize.lg);

    final children = <Widget>[
      GzFadeReveal(
        child: GzIllustration(name, size: artSize, tone: artTone ?? (tone == GzStateTone.danger ? GzIllustrationTone.danger : GzIllustrationTone.standard)),
      ),
      if (title != null) GzText(title!, role: app == GzAppKind.client ? GzTextRole.d2 : GzTextRole.uiTitle, color: c.textStrong, textAlign: center ? TextAlign.center : TextAlign.start, header: true),
      if (helper != null) GzText(helper, role: GzTextRole.caption, color: c.textSecondary, textAlign: center ? TextAlign.center : TextAlign.start),
      ?facts,
      if (action != null || secondary != null)
        Padding(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
          child: Wrap(
            alignment: center ? WrapAlignment.center : WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: GzSpace.s3,
            runSpacing: GzSpace.s3,
            children: [
              if (action != null)
                GzButton(
                  label: action!.label,
                  onPressed: action!.onPressed,
                  variant: action!.variant ?? (role == GzStateKind.success ? GzButtonVariant.primary : GzButtonVariant.secondary),
                  iconStart: action!.iconStart,
                  loading: action!.loading,
                ),
              if (secondary != null) GzButton(label: secondary!.label, onPressed: secondary!.onPressed, variant: GzButtonVariant.tertiary, iconStart: secondary!.iconStart),
            ],
          ),
        ),
      if (info != null)
        Builder(
          builder: (context) => GzIconButton(
            key: const ValueKey('gz:state.info'),
            icon: GzIcons.info,
            label: l10n.commonA11yInfo,
            onPressed: () => showGzSheet<void>(
              context,
              title: detailTitle ?? l10n.commonLabelDetails,
              builder: (context) => GzText(info, role: GzTextRole.body, color: c.textPrimary),
            ),
          ),
        ),
    ];
    return Semantics(
      container: true,
      child: Padding(
        padding: flush
            ? EdgeInsets.zero
            : EdgeInsetsDirectional.only(start: GzSpace.gutter, end: GzSpace.gutter, top: fill ? GzSpace.s12 : GzSpace.s8, bottom: GzSpace.s8),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: cross,
            children: [for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: GzSpace.s4), children[i]]],
          ),
        ),
      ),
    );
  }
}

/// A finished thing: request sent, voucher ready, booking confirmed, payment done, visit booked. One drawing, the outcome in at most
/// four words, one gold action.
class GzSuccessState extends StatelessWidget {
  const GzSuccessState({
    this.illustration = GzIllustrationName.seal,
    this.title,
    this.body,
    this.detail,
    this.detailTitle,
    this.action,
    this.secondary,
    this.fill = true,
    this.size,
    this.center = true,
    this.facts,
    this.flush = false,
    super.key,
  });

  final GzIllustrationName illustration;
  final String? title;
  final String? body;
  final String? detail;
  final String? detailTitle;
  final GzStateAction? action;
  final GzStateAction? secondary;
  final bool fill;
  final GzIllustrationSize? size;
  final bool center;
  final Widget? facts;
  final bool flush;

  @override
  Widget build(BuildContext context) => GzEmptyState(
        illustration: illustration,
        kind: GzStateKind.success,
        title: title,
        body: body,
        detail: detail,
        detailTitle: detailTitle,
        action: action,
        secondary: secondary,
        fill: fill,
        size: size,
        center: center,
        facts: facts,
        flush: flush,
      );
}

enum GzErrorKind { generic, load, network, noAccess, notFound, payment }

/// What went wrong in at most four words, one retry that is one tap, and the recovery text one tap further (info glyph).
class GzErrorState extends StatelessWidget {
  const GzErrorState({this.kind = GzErrorKind.generic, this.title, this.body, this.detailTitle, this.onRetry, this.retrying = false, this.secondary, this.fill = true, super.key});

  final GzErrorKind kind;

  /// Overrides the catalogue title (at most four words).
  final String? title;

  /// The recovery text; it lives behind the info glyph; overrides the catalogue sentence of the kind.
  final String? body;
  final String? detailTitle;

  /// Retry handler; a kind that cannot be retried (no access, not found) shows none unless given.
  final VoidCallback? onRetry;
  final bool retrying;
  final GzStateAction? secondary;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final l10n = context.gzL10n;
    final (String titleText, String detailText, GzIllustrationName art, GzIllustrationTone artTone, bool canRetry) = switch (kind) {
      GzErrorKind.generic => (l10n.commonStateTitleGeneric, l10n.commonStateErrorGeneric, GzIllustrationName.warning, GzIllustrationTone.danger, true),
      GzErrorKind.load => (l10n.commonStateTitleLoad, l10n.commonStateErrorLoad, GzIllustrationName.warning, GzIllustrationTone.danger, true),
      GzErrorKind.network => (l10n.commonStateTitleNetwork, l10n.commonStateErrorNetwork, GzIllustrationName.wifiOff, GzIllustrationTone.standard, true),
      GzErrorKind.noAccess => (l10n.commonStateTitleNoAccess, l10n.commonStateErrorNoAccess, GzIllustrationName.shield, GzIllustrationTone.standard, false),
      GzErrorKind.notFound => (l10n.commonStateTitleNotFound, l10n.commonStateErrorNotFound, GzIllustrationName.noResult, GzIllustrationTone.standard, false),
      GzErrorKind.payment => (l10n.commonStateTitlePayment, l10n.commonStateErrorPayment, GzIllustrationName.card, GzIllustrationTone.danger, true),
    };
    final showRetry = canRetry || onRetry != null;
    return GzEmptyState(
      tone: GzStateTone.danger,
      kind: GzStateKind.error,
      illustration: art,
      artTone: artTone,
      title: title ?? titleText,
      detail: body ?? detailText,
      detailTitle: detailTitle,
      action: showRetry ? GzStateAction(label: l10n.commonActionRetry, onPressed: onRetry, variant: GzButtonVariant.secondary, iconStart: GzIcons.refresh, loading: retrying) : null,
      secondary: secondary,
      fill: fill,
    );
  }
}

/// The offline blank of a screen that needs the network: the wifi-off drawing, "You're offline" and one retry.
class GzOfflineState extends StatelessWidget {
  const GzOfflineState({this.onRetry, this.retrying = false, this.secondary, this.fill = true, super.key});

  final VoidCallback? onRetry;
  final bool retrying;
  final GzStateAction? secondary;
  final bool fill;

  @override
  Widget build(BuildContext context) => GzErrorState(kind: GzErrorKind.network, onRetry: onRetry, retrying: retrying, secondary: secondary, fill: fill);
}
