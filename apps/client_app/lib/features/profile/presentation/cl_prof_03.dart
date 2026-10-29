// CL-PROF-03 Personal info. Port of CL-PROF-03.tsx. Requirements: CA-PROF-01, CA-AUTH-05.
// Name (one field, no first and last split) with a live monogram, the sex (female or male, a two-option glyph switch: required at
// sign-up in CL-AUTH-03, editable here, ADR 0038 D4; not shown to venues, not used to filter), an optional email (an LTR island), the verified phone with "Change" (a
// new number is verified by a WhatsApp code before it replaces the old one) and the sign-in methods linked to the account. Accounts are
// never merged by email (ADR 0028). No photo upload anywhere. The Save bar appears with the first edit and carries the one gold action.
import 'package:client_app/l10n/l10n.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ghazal_app_kit/ghazal_app_kit.dart' show GzAsyncView, gzProblemMessage;
import 'package:ghazal_core/ghazal_core.dart' show gzFormatProvider, localeProvider;
import 'package:ghazal_domain/ghazal_domain.dart' show Me, Sex;
import 'package:ghazal_ui/ghazal_ui.dart';

import '../application/profile_identity.dart';
import 'widgets/phone_change_sheet.dart';
import 'widgets/profile_parts.dart';

final RegExp _emailShape = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

class ClProf03Screen extends ConsumerWidget {
  const ClProf03Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GzAsyncView<Me?>(
      value: ref.watch(profileMeProvider),
      loading: GzScreen(top: GzTopBar(title: context.l10n.clientProfilePersTitle), child: const _Skeleton()),
      onRetry: () => ref.invalidate(profileMeProvider),
      data: (me) {
        final lang = ref.watch(localeProvider).languageCode;
        final latin = me?.user.nameLatin;
        final initial = lang == 'en' && latin != null && latin.isNotEmpty ? latin : (me?.user.name ?? '');
        return _Form(key: ValueKey<String>('$lang|${me?.user.id}|$initial|${me?.user.email}'), me: me, initialName: initial);
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.gzL10n.commonStateLoading,
    container: true,
    child: const Padding(
      padding: EdgeInsetsDirectional.only(top: GzSpace.s2, start: GzSpace.gutter, end: GzSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72), SizedBox(height: GzSpace.s4), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 72), SizedBox(height: GzSpace.s4), GzSkeleton(variant: GzSkeletonVariant.block, blockSize: 64)],
      ),
    ),
  );
}

class _Form extends ConsumerStatefulWidget {
  const _Form({required this.me, required this.initialName, super.key});

  final Me? me;

  /// The name as the screen language shows it (the Latin spelling in English when there is one).
  final String initialName;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late String _name = widget.initialName;
  late String _email = widget.me?.user.email ?? '';
  late Sex _sex = _knownSex(widget.me?.user.sex);
  late final String _name0 = _name;
  late final String _email0 = _email;
  late final Sex _sex0 = _sex;
  bool _shown = false;
  bool _saving = false;

  /// The stored sex; an account that somehow has none shows the first option, like the web.
  static Sex _knownSex(Sex? s) => s == Sex.male ? Sex.male : Sex.female;

  bool get _dirty => _name != _name0 || _sex != _sex0 || _email != _email0;

  Future<void> _save() async {
    setState(() => _shown = true);
    final emailOk = _email.trim().isEmpty || _emailShape.hasMatch(_email.trim());
    if (_name.trim().isEmpty || !emailOk) return;
    final nav = context.gzNav;
    final saved = context.gzL10n.commonStateSaved;
    final gz = context.gzL10n;
    setState(() => _saving = true);
    final problem = await saveProfileDetails(ref, name: _name.trim(), sex: _sex, email: _email.trim());
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (problem == null) _shown = false;
    });
    nav.toast(problem == null ? GzToastSpec(message: saved, tone: GzToastTone.success) : GzToastSpec(message: gzProblemMessage(gz, problem), tone: GzToastTone.danger));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.gz.colors;
    final f = ref.watch(gzFormatProvider);
    final nav = context.gzNav;
    final phone = widget.me?.user.phone ?? ref.watch(profileIdentityProvider)?.phone ?? '';
    final nameError = _shown && _name.trim().isEmpty ? l.clientProfilePersNameError : null;
    final emailError = _shown && _email.trim().isNotEmpty && !_emailShape.hasMatch(_email.trim()) ? l.clientProfilePersEmailError : null;
    final monogram = profileMonogramFor(_name);

    return GzScreen(
      top: GzTopBar(title: l.clientProfilePersTitle),
      bottom: _dirty ? GzActionBar(action: GzActionBarAction(label: context.gzL10n.commonActionSave, loading: _saving, onPressed: _save)) : null,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: GzSpace.s2, bottom: GzSpace.s8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: kProfPad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GzAvatar(name: l.clientProfilePersMonogram, initial: monogram, size: GzAvatarSize.md),
                      const SizedBox(width: GzSpace.s4),
                      Expanded(
                        child: GzTextField(
                          label: l.clientProfilePersName,
                          value: _name,
                          onValueChange: (v) => setState(() => _name = v),
                          autofillHints: const [AutofillHints.name],
                          error: nameError,
                          disabled: _saving,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: GzSpace.s4),
                  GzSexChoice.switcher(
                    value: _sex,
                    label: l.clientProfilePersSex,
                    femaleLabel: l.clientProfilePersSexFemale,
                    maleLabel: l.clientProfilePersSexMale,
                    onChanged: (v) => setState(() => _sex = v),
                    disabled: _saving,
                  ),
                  const SizedBox(height: GzSpace.s4),
                  GzTextField(
                    label: l.clientProfilePersEmail,
                    optional: true,
                    dir: GzFieldDir.ltr,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    autocorrect: false,
                    enableSuggestions: false,
                    value: _email,
                    onValueChange: (v) => setState(() => _email = v),
                    error: emailError,
                    disabled: _saving,
                  ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s6),
            Padding(
              padding: kProfPad,
              child: Row(
                children: [
                  GzText(l.clientProfilePersPhone, role: GzTextRole.label, color: c.textSecondary),
                  const SizedBox(width: GzSpace.s1),
                  GzInfoButton(title: l.clientProfilePersPhoneNoteTitle, icon: GzIcons.lock, paragraphs: [l.clientProfilePersPhoneNote]),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s3),
            Padding(
              padding: kProfPad,
              child: Row(
                children: [
                  const ProfDisk(icon: GzIcons.phone),
                  const SizedBox(width: GzSpace.s4),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: GzNum(f.phone(phone), role: GzTextRole.figTitle, color: c.textStrong)),
                        const SizedBox(width: GzSpace.s2),
                        Semantics(label: l.clientProfileHubVerified, image: true, excludeSemantics: true, child: GzIcon(GzIcons.checkCircle, size: GzIconSize.xs, color: c.iconSuccess)),
                      ],
                    ),
                  ),
                  GzButton(
                    label: l.clientProfilePersPhoneChange,
                    variant: GzButtonVariant.tertiary,
                    onPressed: () => nav.openSheetBuilder((_) => const PhoneChangeSheet(), options: GzSheetOptions(title: l.clientProfilePhoneTitle)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: GzSpace.s6),
            Padding(padding: kProfPad, child: GzSectionHeader(title: l.clientProfilePersMethods)),
            const SizedBox(height: GzSpace.s3),
            Column(
              children: [
                GzIconListRow(
                  icon: GzIcons.whatsapp,
                  title: l.clientProfilePersMethodWhatsapp,
                  trailing: Semantics(label: l.clientProfilePersMethodLinked, image: true, excludeSemantics: true, child: GzIcon(GzIcons.checkCircle, size: GzIconSize.sm, color: c.iconSuccess)),
                ),
                GzIconListRow(
                  icon: GzIcons.apple,
                  title: l.clientProfilePersMethodApple,
                  trailing: GzFactChip(icon: GzIcons.eyeOff, value: l.clientProfilePersMethodHidden, label: l.clientProfilePersMethodLinked, tone: GzFactTone.muted),
                ),
                GzIconListRow(icon: GzIcons.google, title: l.clientProfilePersMethodGoogle, trailing: Text(l.clientProfilePersMethodNotLinked), last: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
