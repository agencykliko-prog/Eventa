import 'package:flutter/material.dart';

import '../../../core/i18n/tr.dart';
import '../../../platform/mobile/notification_permission_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/notification_permission_web.dart';
import '../../../platform/mobile/prefs_store_mobile.dart'
    if (dart.library.js_interop) '../../../platform/web/prefs_store_web.dart';
import '../../../ui/theme/app_icons.dart';
import '../../../ui/theme/eventa_colors.dart';
import '../../../ui/widgets/ui.dart';

/// Une fois dans l'application, propose une fois d'activer les notifications,
/// avant la demande du système (qu'on ne peut poser qu'une fois).
class NotificationPrompt extends StatefulWidget {
  const NotificationPrompt({super.key, required this.child});

  final Widget child;

  @override
  State<NotificationPrompt> createState() => _NotificationPromptState();
}

class _NotificationPromptState extends State<NotificationPrompt> {
  static const _key = 'notifications.asked';

  @override
  void initState() {
    super.initState();
    _maybeAsk();
  }

  Future<void> _maybeAsk() async {
    if (readPref(_key) == '1' || !await canAskNotifications()) return;
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    writePref(_key, '1');
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _PromptDialog(),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _PromptDialog extends StatelessWidget {
  const _PromptDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Confetti.surface,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Hue.violet.tint,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(AppIcons.bell, size: 30, color: Hue.violet.text),
              ),
              const SizedBox(height: 18),
              Text(
                'Ne manquez rien de votre événement'.tr,
                textAlign: TextAlign.center,
                style: context.text.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Recevez un rappel pour vos tâches, les réponses de vos invités et les messages de vos prestataires.'
                    .tr,
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(
                  color: context.eventa.muted,
                ),
              ),
              const SizedBox(height: 22),
              PillButton(
                label: 'Activer les notifications'.tr,
                icon: AppIcons.bell,
                onPressed: () {
                  Navigator.of(context).pop();
                  requestNotifications();
                },
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Plus tard'.tr),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
