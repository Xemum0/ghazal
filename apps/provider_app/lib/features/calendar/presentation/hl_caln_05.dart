// HL-CALN-05 Calendar by email, sheet (web `HL-CALN-05.tsx`): keep an outside calendar (Google, Outlook, Apple) in step by email. One switch (an .ics
// invitation for each confirmed booking and block, to the account address), one optional second address, one test action. Emails go through Resend;
// there is no WhatsApp channel for this (ADR 0035 D8). Reception sees it read-only. Text diet: a mail glyph and one short line per control,
// addresses as LTR isolates, nothing else. Requirements: HA-CAL-10, HA-CAL-06.
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage, partnerCalendarRepositoryProvider;
import 'package:ghazal_core/ghazal_core.dart' show ApiProblem;
import 'package:ghazal_domain/ghazal_domain.dart' show CalendarSync, UpdateCalendarSyncInput;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../l10n/l10n.dart';
import '../application/calendar_data.dart';
import 'widgets/sheet_bits.dart';

final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

enum _Test { idle, sending, sent }

class HlCaln05Screen extends ConsumerStatefulWidget {
  const HlCaln05Screen({super.key});

  @override
  ConsumerState<HlCaln05Screen> createState() => _HlCaln05ScreenState();
}

class _HlCaln05ScreenState extends ConsumerState<HlCaln05Screen> {
  bool? _on;
  String _extra = '';
  _Test _test = _Test.idle;
  String? _error;

  Future<void> _save(CalendarSync sync, bool on) async {
    final gzL = context.gzL10n;
    setState(() {
      _on = on;
      _error = null;
    });
    try {
      await ref.read(partnerCalendarRepositoryProvider).updateCalendarSync(body: UpdateCalendarSyncInput(address: sync.address, ics: on));
      ref.invalidate(calendarSyncProvider);
    } on ApiProblem catch (p) {
      if (!mounted) return;
      setState(() {
        _on = sync.ics;
        _error = gzProblemMessage(gzL, p);
      });
    }
  }

  // There is no "send a test" endpoint (requests.md): the test shows the same outcome as the prototype after a short wait.
  Future<void> _sendTest() async {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    setState(() => _test = _Test.sending);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() => _test = _Test.sent);
    nav.toast(GzToastSpec(message: l.hotelCalendarEmailTestSent, tone: GzToastTone.success, icon: GzIcons.checkCircle));
  }

  @override
  Widget build(BuildContext context) {
    final nav = GzNavigatorScope.of(context);
    final l = context.l10n;
    final c = context.gz.colors;
    final readOnly = !canBlock(ref.watch(calendarRoleProvider));
    final value = ref.watch(calendarSyncProvider);
    final invalid = _extra.trim().isNotEmpty && !_email.hasMatch(_extra.trim());
    final head = GzSheetPinnedHeader(child: GzSheetHeader(title: l.hotelCalendarEmailTitle, onClose: nav.closeSheet));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        head,
        GzAsyncView<CalendarSync>(
          value: value,
          loading: const Padding(padding: EdgeInsets.only(bottom: GzSpace.s6), child: Column(children: [GzSkeleton(blockSize: 56), SizedBox(height: GzSpace.s4), GzSkeleton(blockSize: 56)])),
          onRetry: () => ref.invalidate(calendarSyncProvider),
          data: (sync) {
            final on = _on ?? sync.ics;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null) ...[CalNotice(tone: NoticeTone.danger, actionLabel: context.gzL10n.commonActionRetry, onAction: () => setState(() => _error = null), children: [GzText(_error!, role: GzTextRole.bodyS, color: c.statusDangerText)]), const SizedBox(height: GzSpace.s4)],
                Padding(
                  padding: const EdgeInsets.only(top: GzSpace.s3),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: GzSize.controlLg),
                    child: Row(
                      children: [
                        GzIcon(GzIcons.mail, size: GzIconSize.md, color: c.iconPrimary),
                        const SizedBox(width: GzSpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GzText(l.hotelCalendarEmailSwitch, role: GzTextRole.body, color: c.textPrimary),
                              const SizedBox(height: GzSpace.s1),
                              Directionality(textDirection: TextDirection.ltr, child: Align(alignment: AlignmentDirectional.centerStart, child: GzText(sync.address, role: GzTextRole.caption, color: c.textSecondary))),
                            ],
                          ),
                        ),
                        GzSwitch(label: l.hotelCalendarEmailSwitch, checked: on, disabled: readOnly, onChanged: (v) => _save(sync, v)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: GzSpace.s4),
                GzTextField(
                  label: l.hotelCalendarEmailAdd,
                  value: _extra,
                  dir: GzFieldDir.ltr,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  onValueChange: (v) => setState(() {
                    _extra = v;
                    _test = _Test.idle;
                  }),
                  error: invalid ? l.hotelCalendarEmailInvalid : null,
                  disabled: !on || readOnly,
                  startAdornment: GzIcon(GzIcons.mail, size: GzIconSize.sm, color: c.iconSecondary),
                ),
                GzSheetFooter(
                  child: GzButton(label: l.hotelCalendarEmailTest, fullWidth: true, iconStart: GzIcons.send, loading: _test == _Test.sending, onPressed: !on || invalid || readOnly || _test == _Test.sending ? null : _sendTest),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
