import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GateReason, GateResume, WidgetSessionGate, sessionProvider, visitsRepositoryProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show VisitBookingInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../app/state/state.dart';
import '../../../l10n/l10n.dart';
import '../application/visits_view.dart';
import 'widgets/visit_widgets.dart';

/// CL-VIST-01 Book a visit (sheet). Covers CA-VIS-01, CA-VIS-02, CA-AUTH-10.
///
/// Choose a visit slot: date, arrival window, visitors and an optional note.
/// No voucher is needed. Guests are gated at Send with the choice kept.
/// States: default, no-slots-this-week, slot-taken, sending, guest-gate,
/// error, offline.
class ClVist01Screen extends ConsumerStatefulWidget {
  const ClVist01Screen({super.key});

  @override
  ConsumerState<ClVist01Screen> createState() => _ClVist01ScreenState();
}

class _ClVist01ScreenState extends ConsumerState<ClVist01Screen> {
  String? _date;
  DateTime? _slot;
  int _visitors = 2;
  String _note = '';
  bool _busy = false;
  bool _failed = false;
  bool _seeded = false;

  GzNavigator get _nav => context.gzNav;

  String get _venueId => (_nav.params['venueId'] as String?) ?? 'V01';

  Future<void> _send() async {
    if (_slot == null || _date == null || _busy) return;
    // Opened from the venue ('CL-VENU-01'): closing the sheet returns. A guest reads and chooses freely and meets the sign-in sheet ('CL-AUTH-01', via requireSignIn) only at Send, the choice kept.
    final repo = ref.read(visitsRepositoryProvider);
    if (!ref.read(sessionProvider).isSignedIn) {
      ref.requireSignIn(
        GateReason.visit,
        resume: GateResume('CL-VIST-01', <String, Object?>{'venueId': _venueId, 'date': _date!, 'slot': _slot!.toIso8601String(), 'visitors': _visitors, if (_note.isNotEmpty) 'note': _note}),
      );
      return;
    }
    setState(() {
      _failed = false;
      _busy = true;
    });
    try {
      final thread = await repo.bookVisit(
        body: VisitBookingInput(venueId: _venueId, slotStart: _slot!, visitors: _visitors, note: _note.trim().isEmpty ? null : _note.trim()),
      );
      ref.read(clientDataRevisionProvider.notifier).bump();
      if (!mounted) return;
      _nav.closeSheet();
      _nav.push('CL-VIST-02', params: <String, Object?>{'visitId': thread.visit.id});
    } on Object {
      if (mounted) {
        setState(() {
          _busy = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lc = context.gzL10n;
    final nav = _nav;
    final lang = context.gz.locale.languageCode;
    final venueName = ref.watch(venueOfProvider(_venueId)).value?.name.of(lang) ?? '';
    final info = <String>[l.clientVisitsInfoFree, l.clientVisitsInfoChat(venueName), l.clientVisitsInfoWindow(context.gzFormat.integer(30))];
    final params = nav.params;
    if (!_seeded) {
      _seeded = true;
      _visitors = ((params['visitors'] as int?) ?? 2).clamp(1, 6);
      _note = (params['note'] as String?) ?? '';
      _date = params['date'] as String?;
      final slotRaw = params['slot'] as String?;
      _slot = slotRaw == null ? null : DateTime.tryParse(slotRaw);
    }
    return Column(
      key: const ValueKey<String>('visits.book'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHead(title: l.clientVisitsBookTitle, info: info),
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VenueLineTile(venueId: _venueId),
                if (_failed) ...[
                  const SizedBox(height: GzSpace.s4),
                  GzBanner(message: l.clientVisitsNotSent, icon: GzIcons.warning, tone: GzBannerTone.danger, actionLabel: lc.commonActionRetry, onAction: _send),
                ],
                const SizedBox(height: GzSpace.s4),
                VisitSlotPicker(
                  venueId: _venueId,
                  date: _date,
                  slot: _slot,
                  disabled: _busy,
                  onChange: (d, s) => setState(() {
                    _date = d;
                    _slot = s;
                  }),
                ),
                const SizedBox(height: GzSpace.s4),
                GzStepper(
                  labelWidget: GzIcon(GzIcons.usersThree, size: GzIconSize.md, color: context.gz.colors.iconSecondary),
                  semanticLabel: l.clientVisitsVisitors,
                  compact: true,
                  value: _visitors,
                  min: 1,
                  max: 6,
                  disabled: _busy,
                  onChanged: (v) => setState(() => _visitors = v),
                  valueText: (n) => l.clientVisitsVisitorsCount(n),
                ),
                const SizedBox(height: GzSpace.s4),
                Semantics(
                  label: l.clientVisitsNoteLabel,
                  excludeSemantics: true,
                  child: GzTextField(
                    placeholder: l.clientVisitsNote,
                    value: _note,
                    onValueChange: (v) => setState(() => _note = v.length > 140 ? v.substring(0, 140) : v),
                    disabled: _busy,
                    startAdornment: GzIcon(GzIcons.chatText, size: GzIconSize.sm, color: context.gz.colors.iconSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: GzSpace.s4),
        Container(
          padding: const EdgeInsetsDirectional.only(top: GzSpace.s3),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.gz.colors.borderHairline, width: GzStroke.hair))),
          child: GzButton(
            key: const ValueKey<String>('visits.book.send'),
            label: l.clientVisitsBookAction,
            fullWidth: true,
            loading: _busy,
            onPressed: _slot == null || _busy ? null : _send,
          ),
        ),
      ],
    );
  }
}

/// The title row of a visit sheet: the title at inline-start with an info
/// glyph (the free / chat / window sentences), close at inline-end.
class _SheetHead extends StatelessWidget {
  const _SheetHead({required this.title, this.info = const []});

  final String title;
  final List<String> info;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.only(top: GzSpace.s2),
                child: GzText(title, role: GzTextRole.d1, color: context.gz.colors.textStrong, header: true),
              ),
            ),
            if (info.isNotEmpty) ...[
              const SizedBox(width: GzSpace.s1),
              GzInfoButton(title: title, paragraphs: info),
            ],
            const SizedBox(width: GzSpace.s3),
            GzBarButton(
              key: const ValueKey<String>('gz:sheet.close'),
              icon: GzIcons.close,
              label: context.gzL10n.commonActionClose,
              onPressed: () => context.gzNav.closeSheet(),
            ),
          ],
        ),
        const SizedBox(height: GzSpace.s2),
      ],
    );
  }
}
