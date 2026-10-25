import 'dart:async';

import 'package:flutter/services.dart' show TextInputAction;
import 'package:flutter/widgets.dart';
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../../../l10n/l10n.dart';


/// The visit chat composer (CL-VIST-03; flow-local twin of the thread
/// composer: cross-feature imports are forbidden, a shared GzChatComposer
/// is requested in docs/engineering/requests.md). A text field, an attach
/// glyph, and the microphone that becomes Send once there is text.
class VisitComposer extends StatefulWidget {
  const VisitComposer({
    required this.onSend,
    required this.onAttach,
    required this.onVoice,
    this.onTooShort,
    this.initial = '',
    this.enabled = true,
    super.key,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onAttach;
  final ValueChanged<int> onVoice;
  final VoidCallback? onTooShort;
  final String initial;
  final bool enabled;

  @override
  State<VisitComposer> createState() => _VisitComposerState();
}

class _VisitComposerState extends State<VisitComposer> {
  late String _value = widget.initial;
  bool _recording = false;
  int _seconds = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startRecording() {
    if (!widget.enabled) return;
    setState(() {
      _recording = true;
      _seconds = 0;
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _stopRecording({required bool send}) {
    _ticker?.cancel();
    final seconds = _seconds;
    setState(() {
      _recording = false;
      _seconds = 0;
    });
    if (!send) return;
    if (seconds < 1) {
      widget.onTooShort?.call();
      return;
    }
    widget.onVoice(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      key: const ValueKey<String>('visits.composer'),
      padding: EdgeInsetsDirectional.only(start: GzSpace.s2, end: GzSpace.gutter, top: GzSpace.s2, bottom: GzSpace.s3 + (GzBottomChrome.tabBarOf(context) ? GzLayout.safeBottom : 0)),
      decoration: BoxDecoration(
        color: c.surfaceCanvas,
        border: Border(top: BorderSide(color: c.borderHairline, width: GzStroke.hair)),
      ),
      child: SafeArea(
        top: false,
        child: _recording ? _recordingRow(context) : _idleRow(context),
      ),
    );
  }

  Widget _idleRow(BuildContext context) {
    final l = context.l10n;
    final hasText = _value.trim().isNotEmpty;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GzIconButton(icon: GzIcons.plus, variant: GzIconButtonVariant.outline, label: l.clientMessagesAttach, onPressed: widget.enabled ? widget.onAttach : null),
        const SizedBox(width: GzSpace.s2),
        Expanded(
          child: Semantics(
            label: l.clientMessagesComposerLabel,
            excludeSemantics: true,
            child: _ComposerField(
              placeholder: l.clientMessagesComposerPlaceholder,
              value: _value,
              onValueChange: (v) => setState(() => _value = v),
              onSubmitted: (v) {
                if (v.trim().isEmpty || !widget.enabled) return;
                widget.onSend(v.trim());
                setState(() => _value = '');
              },
              disabled: !widget.enabled,
            ),
          ),
        ),
        const SizedBox(width: GzSpace.s2),
        if (hasText)
          GzIconButton(
            icon: GzIcons.send,
            label: l.clientMessagesRecordSend,
            onPressed: widget.enabled
                ? () {
                    widget.onSend(_value.trim());
                    setState(() => _value = '');
                  }
                : null,
          )
        else
          GestureDetector(
            onLongPressStart: (_) => _startRecording(),
            child: GzIconButton(icon: GzIcons.mic, label: l.clientMessagesRecordHold, onPressed: widget.enabled ? _startRecording : null),
          ),
      ],
    );
  }

  Widget _recordingRow(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = context.gzFormat;
    return Semantics(
      container: true,
      label: l.clientMessagesRecording,
      child: Row(
        children: [
          GzIconButton(icon: GzIcons.trash, label: l.clientMessagesRecordDelete, onPressed: () => _stopRecording(send: false)),
          const SizedBox(width: GzSpace.s2),
          GzIcon(GzIcons.mic, size: GzIconSize.sm, color: c.iconDanger),
          const SizedBox(width: GzSpace.s2),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GzText(l.clientMessagesRecording, role: GzTextRole.caption, color: c.textSecondary),
                const SizedBox(height: GzSpace.s1),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: GzSpace.s1,
                        decoration: BoxDecoration(color: c.markTrack, borderRadius: GzRadius.pillAll),
                        child: FractionallySizedBox(
                          widthFactor: ((_seconds % 60) / 60).clamp(0.05, 1),
                          alignment: AlignmentDirectional.centerStart,
                          child: Container(color: c.iconDanger),
                        ),
                      ),
                    ),
                    const SizedBox(width: GzSpace.s2),
                    GzText(
                      '${f.integer(_seconds ~/ 60)}:${(_seconds % 60).toString().padLeft(2, '0')}',
                      role: GzTextRole.figCaption,
                      color: c.textPrimary,
                      figures: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: GzSpace.s2),
          GzIconButton(icon: GzIcons.send, label: l.clientMessagesRecordSend, onPressed: () => _stopRecording(send: true)),
        ],
      ),
    );
  }
}

/// The 48 high composer field of the web (`gzm-cmp__field`): raised, control border, radius sm, 12 inline padding.
class _ComposerField extends StatefulWidget {
  const _ComposerField({required this.placeholder, required this.value, required this.onValueChange, required this.onSubmitted, required this.disabled});

  final String placeholder;
  final String value;
  final ValueChanged<String> onValueChange;
  final ValueChanged<String> onSubmitted;
  final bool disabled;

  @override
  State<_ComposerField> createState() => _ComposerFieldState();
}

class _ComposerFieldState extends State<_ComposerField> {
  late final TextEditingController _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(_ComposerField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) _controller.text = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.gz.colors;
    return Container(
      constraints: const BoxConstraints(minHeight: GzSize.controlMd),
      padding: const EdgeInsetsDirectional.symmetric(horizontal: GzSpace.s3),
      alignment: AlignmentDirectional.centerStart,
      decoration: BoxDecoration(color: c.surfaceRaised, borderRadius: GzRadius.smAll, border: Border.all(color: c.borderControl, width: GzStroke.hair)),
      child: GzFieldInput(
        controller: _controller,
        placeholder: widget.placeholder,
        disabled: widget.disabled,
        textInputAction: TextInputAction.send,
        onChanged: widget.onValueChange,
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
