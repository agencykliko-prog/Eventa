import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/ui.dart';
import '../../auth/presentation/auth_screen.dart';
import '../../auth/presentation/session_provider.dart';

/// Modification de la photo et des informations personnelles
/// (et du profil public pour un Creator).
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final p = ref.read(profileProvider);
  late final _name = TextEditingController(text: p.name);
  late final _email = TextEditingController(text: p.email);
  late final _phone = TextEditingController(
    text: p.phone.replaceFirst('+225 ', ''),
  );
  late String? _city = ivoryCities.contains(p.city) ? p.city : 'Autre'.tr;
  late final _display = TextEditingController(
    text: p.creator?.displayName ?? '',
  );
  late final _price = TextEditingController(
    text: '${p.creator?.priceFrom ?? ''}',
  );
  late final _desc = TextEditingController(text: p.creator?.description ?? '');
  late final _address = TextEditingController(text: p.creator?.address ?? '');
  late final _website = TextEditingController(text: p.creator?.website ?? '');
  Uint8List? _photo;

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _display,
      _price,
      _desc,
      _address,
      _website,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final c = p.creator;
    ref
        .read(sessionProvider.notifier)
        .update(
          p.copyWith(
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: '+225 ${_phone.text.trim()}',
            city: _city,
            photoBytes: _photo,
            creator: c?.copyWith(
              displayName: _display.text.trim(),
              priceFrom: int.tryParse(_price.text) ?? c.priceFrom,
              description: _desc.text.trim(),
              address: _address.text.trim(),
              website: _website.text.trim().isEmpty
                  ? null
                  : _website.text.trim(),
            ),
          ),
        );
    context.pop();
    toast(context, 'Profil mis à jour'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: AppIcons.back,
                        tooltip: 'Retour',
                        onTap: () => context.pop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Modifier le profil'.tr,
                          style: context.text.titleLarge,
                        ),
                      ),
                      PillButton(
                        label: 'Enregistrer'.tr,
                        tone: ButtonTone.dark,
                        expand: false,
                        height: 40,
                        onPressed: _save,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: PhotoPicker(
                      bytes: _photo ?? p.photoBytes,
                      asset: _photo == null && p.photoBytes == null
                          ? p.photoAsset
                          : null,
                      initials: p.initials,
                      size: 104,
                      onPicked: (b) => setState(() => _photo = b),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _Section('Informations personnelles'.tr),
                  AppField(
                    label: 'Nom et prénom'.tr,
                    controller: _name,
                    validator: Validators.required,
                  ),
                  const SizedBox(height: 14),
                  AppField(
                    label: 'Adresse e-mail'.tr,
                    controller: _email,
                    keyboard: TextInputType.emailAddress,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  AppField(
                    label: 'Téléphone'.tr,
                    controller: _phone,
                    keyboard: TextInputType.phone,
                    prefix: const PhonePrefix(),
                    formatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                      LengthLimitingTextInputFormatter(14),
                    ],
                    validator: Validators.phone,
                  ),
                  const SizedBox(height: 14),
                  AppSelect<String>(
                    label: 'Ville de résidence'.tr,
                    value: _city,
                    options: ivoryCities,
                    labelOf: (c) => c,
                    onChanged: (c) => setState(() => _city = c),
                  ),
                  if (p.creator != null) ...[
                    const SizedBox(height: 28),
                    _Section('Profil public'.tr),
                    AppField(
                      label: 'Nom affiché sur la plateforme'.tr,
                      controller: _display,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Tarif de départ'.tr,
                      controller: _price,
                      keyboard: TextInputType.number,
                      suffixText: 'FCFA'.tr,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Description de votre activité'.tr,
                      controller: _desc,
                      maxLines: 4,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Adresse professionnelle'.tr,
                      controller: _address,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: 14),
                    AppField(
                      label: 'Site web'.tr,
                      controller: _website,
                      optional: true,
                      prefix: const Icon(AppIcons.globe, size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Text(
      title.toUpperCase(),
      style: context.text.labelSmall?.copyWith(
        color: Confetti.inkMuted,
        letterSpacing: 0.8,
      ),
    ),
  );
}
