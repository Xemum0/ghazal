// Changing the verified number (CL-PROF-03, CA-AUTH-05): a new number is verified with a WhatsApp code before it replaces the old one.
// Two steps in one sheet: the new number, then the code. Success writes the account's number and closes with a quiet toast; dismissing
// leaves the old number untouched. Port of the web `PhoneChange.tsx`.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_core/ghazal_core.dart' show PhoneKw, gzFormatProvider;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../../application/profile_code.dart';
import '../../application/profile_identity.dart';
import 'code_body.dart';

class PhoneChangeSheet extends ConsumerStatefulWidget {
  const PhoneChangeSheet({this.initialPhone, super.key});

  /// Opens straight on the code step for this number (a frame of the inventory state `phone-change-otp`).
  final String? initialPhone;

  @override
  ConsumerState<PhoneChangeSheet> createState() => _PhoneChangeSheetState();
}

class _PhoneChangeSheetState extends ConsumerState<PhoneChangeSheet> {
  late final ProfileCodeController _code = ProfileCodeController(ref, purpose: CodePurpose.phoneChange, phone: widget.initialPhone ?? '');
  String _phone = '';
  bool _invalid = false;
  bool _otp = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPhone != null) {
      _phone = widget.initialPhone!;
      _otp = true;
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final f = ref.read(gzFormatProvider);
    if (!f.isValidPhone(_phone)) return setState(() => _invalid = true);
    setState(() {
      _invalid = false;
      _sending = true;
    });
    _code.phone = _phone;
    final ok = await _code.send();
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _otp = true;
    });
  }

  void _verified() {
    final nav = context.gzNav;
    final msg = context.l10n.clientProfilePhoneDone;
    ref.invalidate(profileMeProvider);
    nav.closeSheet();
    nav.toast(GzToastSpec(message: msg, tone: GzToastTone.success));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final f = ref.watch(gzFormatProvider);
    if (_otp) {
      return ListenableBuilder(
        listenable: _code,
        builder: (context, _) {
          final a = codeAction(context, _code, _verified);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ProfileCodeBody(code: _code, phoneText: f.phone(PhoneKw.toE164(_phone) ?? _phone), onVerified: _verified, sheet: true),
              GzSheetFooter(child: GzButton(label: a.label, fullWidth: true, loading: a.loading, onPressed: a.disabled ? null : a.onPressed)),
            ],
          );
        },
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GzPhoneField(
          valueAlign: GzPhoneValueAlign.chip,
          label: l.clientProfilePhoneNew,
          value: _phone,
          onChange: (national, _) => setState(() {
            _phone = national;
            _invalid = false;
          }),
          error: _invalid ? l.clientProfilePhoneErrorDigits(8) : null,
          validateOnBlur: false,
        ),
        GzSheetFooter(child: GzButton(label: l.clientProfilePhoneSend, iconStart: GzIcons.whatsapp, fullWidth: true, loading: _sending, onPressed: _send)),
      ],
    );
  }
}
