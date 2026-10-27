import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/avatars.dart';
import '../../../core/widgets/brand.dart';
import '../../../core/widgets/entrance.dart';
import '../../../core/sound/sounds.dart';
import '../../../core/widgets/forms.dart';
import '../../../core/widgets/mascot.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/ui.dart';
import '../../account/presentation/photo_cropper.dart';
import '../../events/domain/models.dart';
import '../domain/profile.dart';
import 'session_provider.dart';

/// Connexion et inscription, pour les deux profils.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({
    super.key,
    this.signUp = false,
    this.role = UserRole.organizer,
  });

  final bool signUp;
  final UserRole role;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _signUp = widget.signUp;
  late UserRole _role = widget.role;

  @override
  Widget build(BuildContext context) {
    final creator = _role == UserRole.creator;
    return Scaffold(
      // Fond blanc épuré (le mode sombre garde son fond).
      backgroundColor: Confetti.dark ? Confetti.cream : Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: SizedBox(
                        height: 56,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RoundIconButton(
                                icon: AppIcons.back,
                                tooltip: 'Retour',
                                onTap: () => context.canPop()
                                    ? context.pop()
                                    : context.go(Routes.onboarding),
                              ),
                            ),
                            const Entrance(child: EventaWordmark(size: 30)),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Entrance(
                                      index: 1,
                                      offset: 16,
                                      child: AnimatedSwitcher(
                                        duration: Motion.base,
                                        child: Text(
                                          _signUp
                                              ? 'Créer un compte'.tr
                                              : 'Bon retour'.tr,
                                          key: ValueKey(_signUp),
                                          style: context.text.headlineMedium
                                              ?.copyWith(
                                                fontSize: 32,
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Entrance(
                                      index: 2,
                                      offset: 16,
                                      child: Text(
                                        _signUp
                                            ? 'Choisissez votre profil pour commencer.'
                                                  .tr
                                            : 'Connectez-vous à votre espace.'
                                                  .tr,
                                        style: context.text.bodyLarge?.copyWith(
                                          color: context.eventa.muted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AuthMascot(
                                color: creator
                                    ? MascotColor.creator
                                    : MascotColor.organizer,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Entrance(
                            index: 3,
                            child: RolePicker(
                              value: _role,
                              onChanged: (r) => setState(() => _role = r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.base,
                        switchInCurve: Motion.easeOut,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                              begin: const Offset(0, 0.04),
                              end: Offset.zero,
                            ).animate(a),
                            child: child,
                          ),
                        ),
                        child: KeyedSubtree(
                          key: ValueKey('$_signUp-$_role'),
                          child: !_signUp
                              ? _SignInForm(
                                  role: _role,
                                  onSwitch: () =>
                                      setState(() => _signUp = true),
                                )
                              : _role == UserRole.organizer
                              ? _OrganizerSignUp(
                                  onSwitch: () =>
                                      setState(() => _signUp = false),
                                )
                              : _CreatorSignUp(
                                  onSwitch: () =>
                                      setState(() => _signUp = false),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Choix du profil : deux tuiles symétriques.
class RolePicker extends StatelessWidget {
  const RolePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.dark = false,
  });

  final UserRole value;
  final ValueChanged<UserRole> onChanged;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    Widget tile(UserRole r, IconData icon) {
      final on = r == value;
      return Expanded(
        child: Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(r);
          },
          child: AnimatedScale(
            duration: Motion.base,
            curve: Curves.easeOutBack,
            scale: on ? 1 : 0.97,
            child: AnimatedContainer(
              duration: Motion.fast,
              curve: Motion.easeOut,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: on ? Confetti.ink : Confetti.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: on ? Confetti.ink : Confetti.line),
                boxShadow: on
                    ? [
                        BoxShadow(
                          color: Confetti.ink.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: on ? Confetti.onInk : Confetti.ink,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.label,
                          style: context.text.titleSmall?.copyWith(
                            color: on ? Confetti.onInk : Confetti.ink,
                          ),
                        ),
                        Text(
                          r.pitch,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall?.copyWith(
                            color: on ? Colors.white70 : Confetti.inkMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(UserRole.organizer, AppIcons.confetti),
        const SizedBox(width: 10),
        tile(UserRole.creator, AppIcons.vendors),
      ],
    );
  }
}

// ─── Connexion ──────────────────────────────────────────────────────────

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm({required this.role, required this.onSwitch});

  final UserRole role;
  final VoidCallback onSwitch;

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _form = GlobalKey<FormState>();
  bool _accepted = false;
  bool _consentError = false;
  final _id = TextEditingController();
  final _pwd = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _id.dispose();
    _pwd.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _consentError = !_accepted);
    if (!ok || !_accepted) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    authMascotKey.currentState?.jump();
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    ref.read(sessionProvider.notifier).signIn(widget.role);
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          AppField(
            floating: true,
            label: widget.role == UserRole.creator
                ? 'E-mail professionnel ou téléphone'.tr
                : 'E-mail ou téléphone'.tr,
            controller: _id,
            hint: 'nom@exemple.ci',
            keyboard: TextInputType.emailAddress,
            validator: Validators.required,
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Mot de passe'.tr,
            controller: _pwd,
            password: true,
            validator: Validators.required,
            textInputAction: TextInputAction.done,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => toast(
                context,
                'Lien de réinitialisation envoyé'.tr,
                icon: AppIcons.mail,
              ),
              child: Text(
                'Mot de passe oublié ?'.tr,
                style: context.text.labelMedium?.copyWith(
                  color: Confetti.coralDeep,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          LegalConsent(
            value: _accepted,
            error: _consentError,
            onChanged: (v) => setState(() {
              _accepted = v;
              if (v) _consentError = false;
            }),
          ),
          const SizedBox(height: 16),
          PillButton(
            flat: true,
            label: 'Se connecter'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          Text(
            'Démonstration : saisissez n’importe quel identifiant et mot de passe.'
                .tr,
            textAlign: TextAlign.center,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 22),
          _SwitchLine(
            text: 'Pas encore de compte ?'.tr,
            action: 'Créer un compte'.tr,
            onTap: widget.onSwitch,
          ),
          const SizedBox(height: 26),
          const AuthFooter(),
        ],
      ),
    );
  }
}

class _SwitchLine extends StatelessWidget {
  const _SwitchLine({
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          text,
          style: context.text.bodyMedium?.copyWith(color: context.eventa.muted),
        ),
        const SizedBox(width: 6),
        Pressable(
          onTap: onTap,
          child: Text(
            action,
            style: context.text.titleSmall?.copyWith(color: Confetti.coralDeep),
          ),
        ),
      ],
    );
  }
}

// ─── Inscription Organisateur ───────────────────────────────────────────

class _OrganizerSignUp extends ConsumerStatefulWidget {
  const _OrganizerSignUp({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_OrganizerSignUp> createState() => _OrganizerSignUpState();
}

class _OrganizerSignUpState extends ConsumerState<_OrganizerSignUp> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _accepted = false;
  bool _consentError = false;
  String? _city = 'Abidjan'.tr;
  Uint8List? _photo;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _pwd, _pwd2]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final ok = _form.currentState!.validate();
    setState(() => _consentError = !_accepted);
    if (!ok || !_accepted) return;
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    authMascotKey.currentState?.jump();
    ref.read(soundProvider).play(Sfx.success);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    ref
        .read(sessionProvider.notifier)
        .signUp(
          UserProfile(
            role: UserRole.organizer,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: '+225 ${_phone.text.trim()}',
            city: _city ?? 'Abidjan'.tr,
            photoBytes: _photo,
          ),
        );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        children: [
          Center(
            child: PhotoPicker(
              bytes: _photo,
              initials: _name.text.isEmpty ? '' : _name.text[0].toUpperCase(),
              onPicked: (b) => setState(() => _photo = b),
            ),
          ),
          const SizedBox(height: 20),
          AppField(
            floating: true,
            label: 'Nom et prénom'.tr,
            controller: _name,
            hint: 'Awa Traoré'.tr,
            validator: Validators.required,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Adresse e-mail'.tr,
            controller: _email,
            hint: 'awa@exemple.ci',
            keyboard: TextInputType.emailAddress,
            validator: Validators.email,
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Téléphone'.tr,
            controller: _phone,
            hint: '07 08 12 34 56',
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
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Mot de passe'.tr,
            controller: _pwd,
            password: true,
            hint: '8 caractères minimum'.tr,
            validator: Validators.password,
          ),
          const SizedBox(height: 14),
          AppField(
            floating: true,
            label: 'Confirmation du mot de passe'.tr,
            controller: _pwd2,
            password: true,
            textInputAction: TextInputAction.done,
            validator: (v) => v == _pwd.text
                ? null
                : 'Les mots de passe ne correspondent pas'.tr,
          ),
          const SizedBox(height: 16),
          LegalConsent(
            value: _accepted,
            error: _consentError,
            onChanged: (v) => setState(() {
              _accepted = v;
              if (v) _consentError = false;
            }),
          ),
          const SizedBox(height: 16),
          PillButton(
            flat: true,
            label: 'Créer mon compte'.tr,
            loading: _busy,
            onPressed: _submit,
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 18),
          const AuthFooter(),
          const SizedBox(height: 8),
          _SwitchLine(
            text: 'Déjà inscrit ?'.tr,
            action: 'Se connecter'.tr,
            onTap: widget.onSwitch,
          ),
        ],
      ),
    );
  }
}

/// Photo de profil : import, recadrage, aperçu.
class PhotoPicker extends StatelessWidget {
  const PhotoPicker({
    super.key,
    required this.bytes,
    required this.onPicked,
    this.asset,
    this.initials = '',
    this.size = 92,
  });

  final Uint8List? bytes;
  final String? asset;
  final String initials;
  final ValueChanged<Uint8List> onPicked;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      semanticLabel: 'Choisir une photo de profil'.tr,
      onTap: () async {
        final b = await pickAndCropPhoto(context);
        if (b != null) onPicked(b);
      },
      child: Column(
        children: [
          SizedBox.square(
            dimension: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (bytes == null && asset == null)
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: Confetti.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Confetti.line, width: 1.5),
                    ),
                    child: initials.isEmpty
                        ? Icon(
                            AppIcons.user,
                            size: size * 0.36,
                            color: Confetti.inkFaint,
                          )
                        : Center(
                            child: Text(
                              initials,
                              style: context.text.headlineMedium?.copyWith(
                                color: Confetti.violetText,
                              ),
                            ),
                          ),
                  )
                else
                  Avatar(bytes: bytes, image: asset, size: size),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Confetti.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: Confetti.cream, width: 2.5),
                    ),
                    child: const Icon(
                      AppIcons.camera,
                      size: 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bytes == null && asset == null
                ? 'Ajouter une photo'.tr
                : 'Modifier la photo'.tr,
            style: context.text.labelMedium?.copyWith(
              color: Confetti.coralDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inscription Creator ────────────────────────────────────────────────

class _CreatorSignUp extends ConsumerStatefulWidget {
  const _CreatorSignUp({required this.onSwitch});

  final VoidCallback onSwitch;

  @override
  ConsumerState<_CreatorSignUp> createState() => _CreatorSignUpState();
}

class _CreatorSignUpState extends ConsumerState<_CreatorSignUp> {
  final _forms = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];
  int _step = 0;
  bool _accepted = false;
  bool _consentError = false;
  bool _busy = false;

  // Informations professionnelles
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _pwd = TextEditingController();
  CreatorKind _kind = CreatorKind.freelancer;

  // Activité
  final _business = TextEditingController();
  VendorCategory? _category;
  String? _zone = 'Abidjan'.tr;
  final _rccm = TextEditingController();
  final _desc = TextEditingController();

  // Profil public
  final _display = TextEditingController();
  final _price = TextEditingController();
  final _address = TextEditingController();
  final _website = TextEditingController();
  final _portfolio = TextEditingController();

  static const _titles = [
    'Informations professionnelles',
    'Activité',
    'Profil public',
  ];

  @override
  void dispose() {
    for (final c in [
      _name,
      _email,
      _phone,
      _pwd,
      _business,
      _rccm,
      _desc,
      _display,
      _price,
      _address,
      _website,
      _portfolio,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _next() {
    if (!_forms[_step].currentState!.validate()) return;
    if (_step == 1 && _category == null) {
      toast(
        context,
        'Choisissez une catégorie commerciale'.tr,
        icon: AppIcons.info,
      );
      return;
    }
    if (_step == 1 && _display.text.isEmpty) _display.text = _business.text;
    if (_step < 2) {
      setState(() => _step++);
    } else if (!_accepted) {
      setState(() => _consentError = true);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    authMascotKey.currentState?.jump();
    ref.read(soundProvider).play(Sfx.success);
    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    ref
        .read(sessionProvider.notifier)
        .signUp(
          UserProfile(
            role: UserRole.creator,
            name: _name.text.trim(),
            email: _email.text.trim(),
            phone: '+225 ${_phone.text.trim()}',
            city: _zone ?? 'Abidjan'.tr,
            creator: CreatorInfo(
              kind: _kind,
              businessName: _business.text.trim(),
              category: _category!,
              zone: _zone ?? 'Abidjan'.tr,
              rccm: opt(_rccm),
              description: _desc.text.trim(),
              displayName: _display.text.trim(),
              priceFrom: int.tryParse(_price.text) ?? 0,
              address: _address.text.trim(),
              website: opt(_website),
              portfolio: opt(_portfolio),
            ),
          ),
        );
    context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(
                      child: AnimatedContainer(
                        duration: Motion.base,
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _step ? Confetti.ink : Confetti.lavender,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Étape {0}/3'.trf([_step + 1]),
                    style: context.text.labelSmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _titles[_step].tr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.titleSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: Motion.base,
            switchInCurve: Motion.easeOut,
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(a),
                child: c,
              ),
            ),
            child: Form(
              key: _forms[_step],
              child: ListView(
                key: ValueKey(_step),
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  ...switch (_step) {
                    0 => _proInfo(context),
                    1 => _activity(context),
                    _ => _publicProfile(context),
                  },
                  if (_step == 2) ...[
                    const SizedBox(height: 16),
                    LegalConsent(
                      value: _accepted,
                      error: _consentError,
                      onChanged: (v) => setState(() {
                        _accepted = v;
                        if (v) _consentError = false;
                      }),
                    ),
                  ],
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      if (_step > 0) ...[
                        Expanded(
                          child: PillButton(
                            flat: true,
                            label: 'Retour'.tr,
                            tone: ButtonTone.ghost,
                            onPressed: () => setState(() => _step--),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        flex: 2,
                        child: PillButton(
                          flat: true,
                          label: _step < 2
                              ? 'Continuer'.tr
                              : 'Créer mon espace Creator'.tr,
                          loading: _busy,
                          onPressed: _next,
                        ),
                      ),
                    ],
                  ),
                  if (_step == 0) ...[
                    const SizedBox(height: 20),
                    _SwitchLine(
                      text: 'Déjà inscrit ?'.tr,
                      action: 'Se connecter'.tr,
                      onTap: widget.onSwitch,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _proInfo(BuildContext context) => [
    FieldLabel('Type de compte'.tr),
    Row(
      children: [
        for (final k in CreatorKind.values) ...[
          if (k != CreatorKind.values.first) const SizedBox(width: 10),
          Expanded(
            child: Pressable(
              onTap: () => setState(() => _kind = k),
              child: AnimatedContainer(
                duration: Motion.fast,
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Confetti.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _kind == k ? Confetti.ink : Confetti.line,
                    width: _kind == k ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      k == CreatorKind.freelancer
                          ? AppIcons.user
                          : AppIcons.buildings,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(k.label, style: context.text.labelMedium),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Nom et prénom'.tr,
      controller: _name,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Adresse e-mail professionnelle'.tr,
      controller: _email,
      keyboard: TextInputType.emailAddress,
      hint: 'contact@monentreprise.ci',
      validator: Validators.email,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Numéro de téléphone'.tr,
      controller: _phone,
      keyboard: TextInputType.phone,
      prefix: const PhonePrefix(),
      hint: '07 08 12 34 56',
      formatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
        LengthLimitingTextInputFormatter(14),
      ],
      validator: Validators.phone,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Mot de passe'.tr,
      controller: _pwd,
      password: true,
      hint: '8 caractères minimum'.tr,
      validator: Validators.password,
    ),
  ];

  List<Widget> _activity(BuildContext context) => [
    AppField(
      floating: true,
      label: _kind == CreatorKind.agency
          ? 'Nom de l’agence'.tr
          : 'Nom commercial'.tr,
      controller: _business,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppSelect<VendorCategory>(
      label: 'Catégorie commerciale'.tr,
      value: _category,
      options: VendorCategory.values,
      labelOf: (c) => c.label,
      iconOf: (c) => c.icon,
      onChanged: (c) => setState(() => _category = c),
    ),
    const SizedBox(height: 14),
    AppSelect<String>(
      label: 'Ville / zone d’intervention'.tr,
      value: _zone,
      options: [
        'Abidjan'.tr,
        'Abidjan et périphérie'.tr,
        'Grand-Bassam & Assinie'.tr,
        'Yamoussoukro'.tr,
        'Bouaké'.tr,
        'San-Pédro'.tr,
        'Toute la Côte d’Ivoire'.tr,
      ],
      labelOf: (c) => c,
      onChanged: (c) => setState(() => _zone = c),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Numéro RCCM'.tr,
      controller: _rccm,
      optional: true,
      hint: 'CI-ABJ-2024-B-12345'.tr,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Description de votre activité'.tr,
      controller: _desc,
      maxLines: 4,
      hint: 'Vos prestations, votre style, votre expérience…'.tr,
      validator: Validators.required,
    ),
  ];

  List<Widget> _publicProfile(BuildContext context) => [
    AppField(
      floating: true,
      label: 'Nom affiché sur la plateforme'.tr,
      controller: _display,
      validator: Validators.required,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Tarif de départ'.tr,
      controller: _price,
      keyboard: TextInputType.number,
      suffixText: 'FCFA'.tr,
      formatters: [FilteringTextInputFormatter.digitsOnly],
      validator: Validators.required,
      onChanged: (_) => setState(() {}),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Adresse professionnelle'.tr,
      controller: _address,
      hint: 'Rue, quartier, commune'.tr,
      validator: Validators.required,
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Site web'.tr,
      controller: _website,
      optional: true,
      hint: 'monentreprise.ci',
      keyboard: TextInputType.url,
      prefix: const Icon(AppIcons.globe, size: 18),
    ),
    const SizedBox(height: 14),
    AppField(
      floating: true,
      label: 'Portfolio ou réseau social'.tr,
      controller: _portfolio,
      optional: true,
      hint: 'instagram.com/…'.tr,
      keyboard: TextInputType.url,
      prefix: const Icon(AppIcons.link, size: 18),
    ),
    const SizedBox(height: 18),
    FieldLabel('Aperçu dans Explorer'.tr),
    Panel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          IconTile(
            icon: _category?.icon ?? AppIcons.vendors,
            hue: Hue.mango,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _display.text.isEmpty ? 'Votre nom'.tr : _display.text,
                  style: context.text.titleMedium,
                ),
                Text(
                  _category?.label ?? 'Catégorie'.tr,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            _price.text.isEmpty
                ? '—'
                : 'dès {0}'.trf([fcfaCompact(int.tryParse(_price.text) ?? 0)]),
            style: context.text.titleSmall,
          ),
        ],
      ),
    ),
  ];
}

// ─── Mascotte de connexion ──────────────────────────────────────────────

/// Clé de la mascotte de connexion, pour la faire sauter de joie.
final authMascotKey = GlobalKey<MascotState>();

/// La mascotte suit la saisie du regard, se cache les yeux pendant la
/// saisie d'un mot de passe masqué, et salue à l'arrivée.
class AuthMascot extends ConsumerStatefulWidget {
  const AuthMascot({super.key, this.color = MascotColor.organizer});

  final MascotColor color;

  @override
  ConsumerState<AuthMascot> createState() => _AuthMascotState();
}

class _AuthMascotState extends ConsumerState<AuthMascot> {
  TextEditingController? _watched;
  Offset? _look;
  bool _cover = false;
  bool _waving = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_onFocus);
    _timer = Timer(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => _waving = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    FocusManager.instance.removeListener(_onFocus);
    _watched?.removeListener(_onText);
    super.dispose();
  }

  EditableText? get _field => FocusManager.instance.primaryFocus?.context
      ?.findAncestorWidgetOfExactType<EditableText>();

  void _onFocus() {
    final field = _field;
    if (field?.controller != _watched) {
      _watched?.removeListener(_onText);
      _watched = field?.controller?..addListener(_onText);
    }
    _onText();
  }

  void _onText() {
    if (!mounted) return;
    final field = _field;
    setState(() {
      if (field == null) {
        _look = null;
        _cover = false;
        return;
      }
      // Le regard glisse le long du texte saisi, vers le formulaire.
      final n = field.controller.text.length.clamp(0, 28);
      _look = Offset(-0.8 + n / 28 * 1.6, 0.9);
      _cover = field.obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 2),
      child: Mascot(
        key: authMascotKey,
        size: 104,
        color: widget.color,
        look: _look,
        cover: _cover,
        waving: _waving,
        onTap: () => ref.read(soundProvider).play(Sfx.success),
      ),
    );
  }
}

/// Consentement obligatoire, en une ligne sobre : case à cocher animée,
/// liens vers les deux documents.
class LegalConsent extends StatelessWidget {
  const LegalConsent({
    super.key,
    required this.value,
    required this.onChanged,
    this.error = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final link = context.text.bodySmall?.copyWith(
      color: Confetti.ink,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: Confetti.border,
    );
    final border = error ? Confetti.danger : Confetti.border;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              checked: value,
              label: 'J’accepte les conditions'.tr,
              child: Pressable(
                scale: 0.88,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(!value);
                },
                child: AnimatedContainer(
                  duration: Motion.fast,
                  curve: Motion.easeOut,
                  width: 22,
                  height: 22,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: value ? Confetti.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: value ? Confetti.ink : border,
                      width: 1.6,
                    ),
                  ),
                  child: AnimatedScale(
                    duration: Motion.fast,
                    curve: Curves.easeOutBack,
                    scale: value ? 1 : 0,
                    child: Icon(
                      AppIcons.check,
                      size: 14,
                      color: Confetti.onInk,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'En continuant, vous acceptez nos '.tr),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Pressable(
                        onTap: () => context.push(Routes.terms),
                        child: Text('Conditions d’utilisation'.tr, style: link),
                      ),
                    ),
                    TextSpan(text: ' et notre '.tr),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.baseline,
                      baseline: TextBaseline.alphabetic,
                      child: Pressable(
                        onTap: () => context.push(Routes.privacy),
                        child: Text(
                          'Politique de confidentialité'.tr,
                          style: link,
                        ),
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                style: context.text.bodySmall?.copyWith(
                  color: Confetti.inkMuted,
                ),
              ),
            ),
          ],
        ),
        AnimatedSize(
          duration: Motion.fast,
          child: error
              ? Padding(
                  padding: const EdgeInsets.only(left: 32, top: 6),
                  child: Text(
                    'Cochez la case pour continuer.'.tr,
                    style: TextStyle(color: Confetti.danger, fontSize: 12),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Pied des formulaires d'accès, minimaliste : communauté et pays à venir.
class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.text.bodySmall?.copyWith(color: Confetti.inkMuted);
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 22,
              child: Stack(
                children: [
                  for (var i = 0; i < 4; i++)
                    Positioned(
                      left: i * 12.0,
                      child: Avatar(
                        image: 'assets/images/avatar_${i + 1}.jpg',
                        initials: '',
                        size: 22,
                        ring: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Plus de 1 000 utilisateurs nous font déjà confiance.'.tr,
                style: muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            Text('Bientôt disponible :'.tr, style: muted),
            for (final c in Country.soon)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MiniFlag(country: c),
                  const SizedBox(width: 4),
                  Text(c.name.tr, style: muted),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// Pays où Eventa arrive bientôt.
enum Country {
  mali('Mali'),
  burkina('Burkina Faso'),
  togo('Togo'),
  benin('Bénin');

  const Country(this.name);
  final String name;

  static const soon = Country.values;
}

/// Petit drapeau dessiné (les drapeaux émoji ne s'affichent pas partout).
class MiniFlag extends StatelessWidget {
  const MiniFlag({super.key, required this.country});

  final Country country;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: CustomPaint(
        size: const Size(18, 12),
        painter: _FlagPainter(country),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.c);

  final Country c;

  static const _green = Color(0xFF14B53A);
  static const _yellow = Color(0xFFFCD116);
  static const _red = Color(0xFFCE1126);

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    Paint p(Color c) => Paint()..color = c;
    void star(Offset o, double r, Color color) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final a = -1.5708 + i * 0.6283;
        final rr = i.isEven ? r : r * 0.42;
        final pt = o + Offset(rr * _cos(a), rr * _sin(a));
        i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
      }
      canvas.drawPath(path..close(), p(color));
    }

    switch (c) {
      case Country.mali:
        canvas.drawRect(Rect.fromLTWH(0, 0, w / 3, h), p(_green));
        canvas.drawRect(Rect.fromLTWH(w / 3, 0, w / 3, h), p(_yellow));
        canvas.drawRect(Rect.fromLTWH(2 * w / 3, 0, w / 3, h), p(_red));
      case Country.burkina:
        canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 2), p(_red));
        canvas.drawRect(Rect.fromLTWH(0, h / 2, w, h / 2), p(_green));
        star(Offset(w / 2, h / 2), h * 0.24, _yellow);
      case Country.togo:
        for (var i = 0; i < 5; i++) {
          canvas.drawRect(
            Rect.fromLTWH(0, i * h / 5, w, h / 5),
            p(i.isEven ? const Color(0xFF006A4E) : _yellow),
          );
        }
        canvas.drawRect(Rect.fromLTWH(0, 0, h * 0.6, h * 0.6), p(_red));
        star(Offset(h * 0.3, h * 0.3), h * 0.22, Colors.white);
      case Country.benin:
        canvas.drawRect(Rect.fromLTWH(0, 0, w * 0.4, h), p(_green));
        canvas.drawRect(Rect.fromLTWH(w * 0.4, 0, w * 0.6, h / 2), p(_yellow));
        canvas.drawRect(Rect.fromLTWH(w * 0.4, h / 2, w * 0.6, h / 2), p(_red));
    }
  }

  static double _cos(double a) => math.cos(a);
  static double _sin(double a) => math.sin(a);

  @override
  bool shouldRepaint(_FlagPainter old) => old.c != c;
}
