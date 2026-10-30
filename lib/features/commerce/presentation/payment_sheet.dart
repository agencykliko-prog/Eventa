import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/sound/sounds.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/app_theme.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../ui/widgets/pressable.dart';
import '../../../ui/widgets/ui.dart';
import '../domain/commerce_models.dart';

/// Une option de montant (acompte, total, solde…).
class PayOption {
  const PayOption(this.label, this.amount, {this.caption});
  final String label;
  final int amount;
  final String? caption;
}

/// Feuille de paiement : choix du montant et du moyen, confirmation,
/// reçu. [onPay] applique le paiement et renvoie le reçu à afficher.
Future<Receipt?> showPaymentSheet(
  BuildContext context, {
  required String title,
  required String payee,
  required List<PayOption> options,
  required Receipt Function(int amount, PayMethod method) onPay,
}) {
  return showEventaSheet<Receipt>(
    context,
    builder: (_) => _PaymentSheet(
      title: title,
      payee: payee,
      options: options,
      onPay: onPay,
    ),
  );
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.title,
    required this.payee,
    required this.options,
    required this.onPay,
  });

  final String title;
  final String payee;
  final List<PayOption> options;
  final Receipt Function(int amount, PayMethod method) onPay;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  int _option = 0;
  PayMethod _method = PayMethod.wave;
  bool _paying = false;
  Receipt? _receipt;

  Future<void> _pay() async {
    setState(() => _paying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    final r = widget.onPay(widget.options[_option].amount, _method);
    ProviderScope.containerOf(context).read(soundProvider).play(Sfx.payment);
    setState(() {
      _paying = false;
      _receipt = r;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Motion.base,
      curve: Motion.easeOut,
      child: AnimatedSwitcher(
        duration: Motion.base,
        switchInCurve: Motion.easeOut,
        child: _receipt != null
            ? ReceiptView(
                key: const ValueKey('r'),
                receipt: _receipt!,
                onDone: () => Navigator.of(context).pop(_receipt),
              )
            : _form(context),
      ),
    );
  }

  Widget _form(BuildContext context) {
    final amount = widget.options[_option].amount;
    return SingleChildScrollView(
      key: const ValueKey('f'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(icon: AppIcons.shield, hue: Hue.lagoon, size: 38),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: context.text.titleMedium),
                    Text(
                      'Bénéficiaire : {0}'.trf([widget.payee]),
                      style: context.text.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (widget.options.length > 1) ...[
            Row(
              children: [
                for (var i = 0; i < widget.options.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(
                    child: Pressable(
                      onTap: () => setState(() => _option = i),
                      child: AnimatedContainer(
                        duration: Motion.fast,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: i == _option ? Confetti.ink : Confetti.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: i == _option ? Confetti.ink : Confetti.line,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.options[i].label,
                              style: context.text.labelMedium?.copyWith(
                                color: i == _option
                                    ? Colors.white70
                                    : context.eventa.muted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              fcfaCompact(widget.options[i].amount),
                              style: context.text.titleLarge?.copyWith(
                                color: i == _option
                                    ? Confetti.onInk
                                    : Confetti.ink,
                              ),
                            ),
                            if (widget.options[i].caption != null)
                              Text(
                                widget.options[i].caption!,
                                style: context.text.labelSmall?.copyWith(
                                  color: i == _option
                                      ? Colors.white60
                                      : context.eventa.muted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
          ] else ...[
            Text(fcfa(amount), style: context.text.headlineMedium),
            const SizedBox(height: 16),
          ],
          Text('Moyen de paiement'.tr, style: context.text.labelMedium),
          const SizedBox(height: 10),
          MethodPicker(
            value: _method,
            onChanged: (m) => setState(() => _method = m),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(AppIcons.lock, size: 15, color: Confetti.lagoonText),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Paiement sécurisé, conservé jusqu’à la validation de la prestation, puis reversé au prestataire. Démonstration : aucun débit réel.'
                      .tr,
                  style: context.text.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Payer {0}'.trf([fcfa(amount)]),
            icon: AppIcons.lock,
            loading: _paying,
            onPressed: _pay,
          ),
        ],
      ),
    );
  }
}

/// Choix du moyen de paiement : Mobile Money (menu déroulant des quatre
/// opérateurs), carte, Apple Pay, Google Pay.
class MethodPicker extends StatefulWidget {
  const MethodPicker({super.key, required this.value, required this.onChanged});

  final PayMethod value;
  final ValueChanged<PayMethod> onChanged;

  @override
  State<MethodPicker> createState() => _MethodPickerState();
}

class _MethodPickerState extends State<MethodPicker> {
  bool _open = false;
  PayMethod _operator = PayMethod.wave;

  @override
  void initState() {
    super.initState();
    if (widget.value.mobileMoney) _operator = widget.value;
  }

  @override
  Widget build(BuildContext context) {
    final mm = widget.value.mobileMoney;
    Widget row({
      required IconData icon,
      required String label,
      String? trailing,
      required bool selected,
      required VoidCallback onTap,
      Widget? end,
    }) => Pressable(
      onTap: onTap,
      scale: 0.99,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Confetti.ink),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: context.text.titleSmall)),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  trailing,
                  style: context.text.labelMedium?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
              ),
            ?end,
            _Radio(selected: selected),
          ],
        ),
      ),
    );

    return Panel(
      padding: EdgeInsets.zero,
      radius: 16,
      child: Column(
        children: [
          row(
            icon: AppIcons.mobile,
            label: 'Mobile Money'.tr,
            trailing: mm ? widget.value.label : null,
            selected: mm,
            end: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: Motion.fast,
                child: Icon(
                  AppIcons.chevronDown,
                  size: 15,
                  color: Confetti.inkMuted,
                ),
              ),
            ),
            onTap: () {
              setState(() => _open = !_open);
              if (!mm) widget.onChanged(_operator);
            },
          ),
          AnimatedSize(
            duration: Motion.base,
            curve: Motion.easeOut,
            alignment: Alignment.topCenter,
            child: !_open
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(46, 0, 14, 10),
                    child: Column(
                      children: [
                        for (final op in PayMethod.values.where(
                          (m) => m.mobileMoney,
                        ))
                          Pressable(
                            scale: 0.99,
                            onTap: () {
                              setState(() {
                                _operator = op;
                                _open = false;
                              });
                              widget.onChanged(op);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: widget.value == op
                                    ? Confetti.lavender.withValues(alpha: 0.7)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  PayLogo(method: op),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      op.label,
                                      style: context.text.bodyMedium,
                                    ),
                                  ),
                                  if (widget.value == op)
                                    Icon(
                                      AppIcons.check,
                                      size: 15,
                                      color: Confetti.coral,
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
          for (final m in [
            PayMethod.card,
            PayMethod.applePay,
            PayMethod.googlePay,
          ]) ...[
            const Divider(height: 1, indent: 14, endIndent: 14),
            row(
              icon: m.icon,
              label: m.label,
              end: m.logo == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: PayLogo(method: m),
                    ),
              selected: widget.value == m,
              onTap: () {
                setState(() => _open = false);
                widget.onChanged(m);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Motion.fast,
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(
        color: selected ? Confetti.coral : Confetti.border,
        width: selected ? 6 : 1.6,
      ),
    ),
  );
}

/// Reçu généré après paiement.
class ReceiptView extends StatelessWidget {
  const ReceiptView({super.key, required this.receipt, required this.onDone});

  final Receipt receipt;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final r = receipt;
    Widget row(String a, String b, {bool strong = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(a, style: context.text.bodySmall)),
          Text(
            b,
            style: strong ? context.text.titleMedium : context.text.titleSmall,
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.7, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (_, s, child) => Transform.scale(scale: s, child: child),
            child: Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: Confetti.lagoon,
                shape: BoxShape.circle,
              ),
              child: const Icon(AppIcons.check, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 14),
          Text('Paiement confirmé'.tr, style: context.text.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Reçu enregistré dans votre coffre-fort'.tr,
            style: context.text.bodySmall,
          ),
          const SizedBox(height: 18),
          Panel(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Column(
              children: [
                row('Référence'.tr, r.ref),
                row('Objet'.tr, r.label),
                row('Bénéficiaire'.tr, r.payee),
                row('Moyen'.tr, r.method.label),
                row('Date'.tr, '${mediumDate(r.date)} · ${timeOf(r.date)}'),
                const Divider(height: 14),
                row('Montant payé'.tr, fcfa(r.total), strong: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PillButton(
            label: 'Terminé'.tr,
            tone: ButtonTone.dark,
            onPressed: onDone,
          ),
        ],
      ),
    );
  }
}

/// Logo officiel d'un moyen de paiement, sur une petite tuile blanche.
class PayLogo extends StatelessWidget {
  const PayLogo({super.key, required this.method, this.height = 26});

  final PayMethod method;
  final double height;

  @override
  Widget build(BuildContext context) {
    final logo = method.logo;
    return Container(
      height: height,
      width: height * 1.5,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Confetti.line),
      ),
      child: logo == null
          ? Icon(method.icon, size: height * 0.6, color: Confetti.ink)
          : Image.asset(logo, fit: BoxFit.contain),
    );
  }
}
