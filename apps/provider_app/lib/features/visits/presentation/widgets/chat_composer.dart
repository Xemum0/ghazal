// Composer: the message bar of the conversation (web `Composer.tsx`, HA-MSG-02, HA-MSG-03). Quick-reply chips above (defaults only, bilingual), then
// Attach (+), a text field that sets its own direction (ADR 0014 D8) and either Send (text typed) or a hold-to-record voice button (field empty).
// Voice: hold to record; slide toward inline-start to cancel; slide up to lock; releasing sends. Gold is not used here: the one gold action of the
// thread is Accept in the context bar. The recording hints are glyphs, the sentences are read.
import 'dart:async';

import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';

class QuickReply {
  const QuickReply({required this.id, required this.label, required this.text});

  final String id;
  final String label;
  final String text;
}

const double _kCancelDistance = 96;
const double _kLockDistance = 64;

enum _RecMode { holding, locked }

class ThreadComposer extends StatefulWidget {
  const ThreadComposer({required this.quick, required this.onSend, required this.onAttach, required this.onVoice, this.onTooShort, super.key});

  final List<QuickReply> quick;
  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final ValueChanged<int> onVoice;

  /// A tap that was too short to record: the hint says to hold.
  final VoidCallback? onTooShort;

  @override
  State<ThreadComposer> createState() => _ThreadComposerState();
}

class _ThreadComposerState extends State<ThreadComposer> {
  final TextEditingController _text = TextEditingController();
  final FocusNode _focus = FocusNode();
  _RecMode? _rec;
  int _seconds = 0;
  bool _cancel = false;
  Offset? _start;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _clock(int s) {
    final f = context.gzFormat;
    return '${f.integer(s ~/ 60)}:${(s % 60).toString().padLeft(2, '0')}';
  }

  void _begin(PointerDownEvent e) {
    _start = e.position;
    setState(() {
      _rec = _RecMode.holding;
      _seconds = 0;
      _cancel = false;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _rec != null) setState(() => _seconds++);
    });
  }

  void _move(PointerMoveEvent e) {
    final s = _start;
    if (s == null || _rec == null || _rec == _RecMode.locked) return;
    // Inline-start is left in LTR and right in RTL: the cancel slide is measured along it.
    final along = (context.gz.isRtl ? 1 : -1) * (e.position.dx - s.dx);
    final up = s.dy - e.position.dy;
    if (up > _kLockDistance) {
      setState(() {
        _rec = _RecMode.locked;
        _cancel = false;
      });
    } else if (_cancel != along > _kCancelDistance) {
      setState(() => _cancel = along > _kCancelDistance);
    }
  }

  void _end(PointerEvent e) {
    if (_start == null || _rec == null) return;
    _start = null;
    if (_rec == _RecMode.locked) return;
    _ticker?.cancel();
    final seconds = _seconds;
    final cancelled = _cancel;
    setState(() => _rec = null);
    if (cancelled) return;
    if (seconds > 0) {
      widget.onVoice(seconds);
    } else {
      widget.onTooShort?.call();
    }
  }

  void _discard() {
    _ticker?.cancel();
    setState(() => _rec = null);
  }

  void _sendLocked() {
    _ticker?.cancel();
    final seconds = _seconds < 1 ? 1 : _seconds;
    setState(() => _rec = null);
    widget.onVoice(seconds);
  }

  void _submit() {
    final value = _text.text.trim();
    if (value.isEmpty) return;
    widget.onSend(value);
    _text.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    // The prototype pads the composer by the safe-bottom inset even above the tab bar (the shell consumes the inset): keep that.
    final bottom = MediaQuery.paddingOf(context).bottom < GzLayout.safeBottom ? GzLayout.safeBottom : MediaQuery.paddingOf(context).bottom;
    final rec = _rec;
    final hasText = _text.text.trim().isNotEmpty;

    Widget disk(IconData icon, String label, VoidCallback onPressed) => GzPressable(
      onPressed: onPressed,
      semanticLabel: label,
      borderRadius: GzRadius.pillAll,
      child: Container(
        width: GzSize.touchMin,
        height: GzSize.touchMin,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: c.surfaceDark),
        child: GzIcon(icon, size: GzIconSize.sm, color: c.iconOnDark),
      ),
    );

    final lead = rec == null
        ? GzIconButton(icon: GzIcons.plus, label: l.hotelTodayAttach, variant: GzIconButtonVariant.outline, onPressed: widget.onAttach)
        : (rec == _RecMode.locked
              ? GzIconButton(icon: GzIcons.trash, label: l.hotelTodayRecordDelete, onPressed: _discard)
              : const SizedBox(width: GzSize.touchMin, height: GzSize.touchMin));

    final Widget middle;
    if (rec != null) {
      middle = Semantics(
        liveRegion: true,
        label: l.hotelTodayRecording,
        child: ExcludeSemantics(
          child: Row(
            children: [
              Container(
                width: GzSpace.s3,
                height: GzSpace.s3,
                decoration: BoxDecoration(shape: BoxShape.circle, color: c.textDanger),
              ),
              const SizedBox(width: GzSpace.s3),
              GzText(_clock(_seconds), role: GzTextRole.title, color: c.textStrong, figures: true),
              const SizedBox(width: GzSpace.s3),
              if (rec == _RecMode.locked)
                GzIcon(GzIcons.lock, size: GzIconSize.sm, color: c.iconSecondary)
              else if (_cancel)
                GzIcon(GzIcons.trash, size: GzIconSize.sm, color: c.iconDanger)
              else ...[
                GzIcon(GzIcons.chevronLeft, size: GzIconSize.xs, color: c.iconSecondary),
                GzIcon(GzIcons.trash, size: GzIconSize.xs, color: c.iconSecondary),
                const SizedBox(width: GzSpace.s4),
                GzIcon(GzIcons.chevronUp, size: GzIconSize.xs, color: c.iconSecondary),
                GzIcon(GzIcons.lock, size: GzIconSize.xs, color: c.iconSecondary),
              ],
            ],
          ),
        ),
      );
    } else {
      middle = Container(
        constraints: const BoxConstraints(minHeight: GzSize.controlMd),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          borderRadius: GzRadius.smAll,
          border: Border.all(color: c.borderControl, width: GzStroke.hair),
        ),
        child: GzFieldInput(
          controller: _text,
          focusNode: _focus,
          placeholder: l.hotelTodayComposerPlaceholder,
          semanticsLabel: l.hotelTodayComposerLabel,
          textInputAction: TextInputAction.send,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    final Widget end;
    if (rec == _RecMode.locked) {
      end = disk(GzIcons.send, l.hotelTodayRecordSend, _sendLocked);
    } else if (hasText && rec == null) {
      end = disk(GzIcons.send, context.gzL10n.commonActionSend, _submit);
    } else {
      end = Listener(
        onPointerDown: _begin,
        onPointerMove: _move,
        onPointerUp: _end,
        onPointerCancel: _end,
        child: Semantics(
          button: true,
          label: l.hotelTodayRecordHold,
          onTap: () => widget.onVoice(1),
          child: Container(
            width: GzSize.touchMin,
            height: GzSize.touchMin,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, color: rec != null ? c.surfaceDark : null),
            child: GzIcon(GzIcons.mic, size: GzIconSize.md, color: rec != null ? c.iconOnDark : c.textStrong),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s3 + bottom),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(
          top: BorderSide(color: c.borderHairline, width: GzStroke.hair),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (rec == null) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.gutter),
              child: Semantics(
                container: true,
                label: l.hotelTodayQuickLabel,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.quick.length; i++) ...[
                      if (i > 0) const SizedBox(width: GzSpace.s2),
                      GzChip(
                        label: widget.quick[i].label,
                        onPressed: () {
                          _text.text = widget.quick[i].text;
                          _text.selection = TextSelection.collapsed(offset: _text.text.length);
                          _focus.requestFocus();
                          setState(() {});
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: GzSpace.s2),
          ],
          Padding(
            padding: const EdgeInsetsDirectional.only(start: GzSpace.s2, end: GzSpace.gutter),
            child: Row(
              children: [
                lead,
                const SizedBox(width: GzSpace.s2),
                Expanded(child: middle),
                const SizedBox(width: GzSpace.s2),
                end,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
