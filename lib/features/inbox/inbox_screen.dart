import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/i18n/tr.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/eventa_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/avatars.dart';
import '../../core/widgets/ui.dart';
import '../auth/presentation/session_provider.dart';
import 'inbox_providers.dart';

/// Heure du dernier message : minutes, heures, puis date.
String _ago(DateTime at) {
  final d = DateTime.now().difference(at);
  if (d.inMinutes < 1) return 'à l’instant'.tr;
  if (d.inMinutes < 60) return 'il y a {0} min'.trf([d.inMinutes]);
  if (d.inHours < 24) return 'il y a {0} h'.trf([d.inHours]);
  return shortDate(at);
}

String _initials(String name) => name
    .split(' ')
    .where((w) => w.isNotEmpty)
    .take(2)
    .map((w) => w[0].toUpperCase())
    .join();

/// En-tête commun : retour, titre, sous-titre.
class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          RoundIconButton(
            icon: AppIcons.back,
            tooltip: 'Retour',
            onTap: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.titleLarge,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(
                      color: Confetti.inkMuted,
                    ),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

// ─── Liste des conversations ────────────────────────────────────────────

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(conversationsProvider);
    final creator = ref.watch(profileProvider).isCreator;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: 'Messages'.tr,
              subtitle: creator
                  ? 'Vos échanges avec les clients, par demande.'.tr
                  : 'Vos échanges avec les prestataires, par réservation.'.tr,
            ),
            Expanded(
              child: list.isEmpty
                  ? _Empty(creator: creator)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      physics: const BouncingScrollPhysics(),
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) => _Row(c: list[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends ConsumerWidget {
  const _Row({required this.c});
  final Conversation c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadInProvider(c.id));
    final last = c.messages.lastOrNull;
    final preview = last == null
        ? 'Aucun message pour l’instant'.tr
        : (last.fromMe ? 'Vous : {0}'.trf([last.text]) : last.text);
    return Panel(
      key: ValueKey('conv-${c.id}'),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(Routes.conversation(c.id)),
      child: Row(
        children: [
          Avatar(image: c.avatar, initials: _initials(c.title), size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _ago(c.lastAt),
                      style: context.text.labelSmall?.copyWith(
                        color: unread > 0 ? Confetti.violet : Confetti.inkFaint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  c.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelSmall?.copyWith(
                    color: Confetti.inkMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodySmall?.copyWith(
                          color: unread > 0 ? Confetti.ink : Confetti.inkMuted,
                          fontWeight: unread > 0 ? FontWeight.w600 : null,
                        ),
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        constraints: const BoxConstraints(minWidth: 20),
                        height: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Confetti.violet,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.creator});
  final bool creator;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(icon: AppIcons.message, hue: Hue.violet, size: 56),
            const SizedBox(height: 14),
            Text(
              'Pas encore de conversation'.tr,
              style: context.text.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              creator
                  ? 'Les messages de vos clients arriveront ici.'.tr
                  : 'Demandez un devis à un prestataire : vos échanges apparaîtront ici.'
                        .tr,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: Confetti.inkMuted,
              ),
            ),
            if (!creator) ...[
              const SizedBox(height: 18),
              PillButton(
                label: 'Trouver un prestataire'.tr,
                icon: AppIcons.search,
                expand: false,
                onPressed: () => context.go(Routes.explore),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Conversation ───────────────────────────────────────────────────────

class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationState();
}

class _ConversationState extends ConsumerState<ConversationScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _composer.text.trim();
    if (text.isEmpty) return;
    ref.read(messengerProvider).send(widget.id, text);
    _composer.clear();
  }

  /// Marque comme lu ce qui est affiché et descend au dernier message.
  void _seen(Conversation c) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(readMarksProvider.notifier).seen(c);
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(conversationProvider(widget.id));
    if (c == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _Header(title: 'Messages'.tr),
              Expanded(
                child: Center(
                  child: Text(
                    'Conversation introuvable.'.tr,
                    style: context.text.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    _seen(c);
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: c.title,
              subtitle: c.subtitle,
              trailing: RoundIconButton(
                icon: AppIcons.file,
                tooltip: 'Voir le dossier',
                onTap: () => context.push(c.folder),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: c.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          'Écrivez le premier message.'.tr,
                          style: context.text.bodyMedium?.copyWith(
                            color: Confetti.inkMuted,
                          ),
                        ),
                      ),
                    )
                  : ListView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      children: [
                        for (final m in c.messages)
                          ChatBubble(text: m.text, at: m.at, fromMe: m.fromMe),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('composer'),
                      controller: _composer,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: 'Écrire un message…'.tr,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoundIconButton(
                    key: const ValueKey('send'),
                    icon: AppIcons.send,
                    background: Confetti.violet,
                    foreground: Colors.white,
                    size: 48,
                    tooltip: 'Envoyer',
                    onTap: _send,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulle de discussion : mes messages à droite sur encre, les autres à
/// gauche sur surface.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.text,
    required this.at,
    required this.fromMe,
  });

  final String text;
  final DateTime at;
  final bool fromMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: fromMe ? Confetti.ink : Confetti.surface,
          border: fromMe ? null : Border.all(color: Confetti.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(fromMe ? 18 : 4),
            bottomRight: Radius.circular(fromMe ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: fromMe ? Confetti.onInk : Confetti.ink,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              timeOf(at),
              style: context.text.labelSmall?.copyWith(
                color: fromMe ? Colors.white54 : Confetti.inkFaint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
