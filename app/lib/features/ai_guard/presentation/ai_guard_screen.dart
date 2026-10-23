import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/entities/entities.dart';
import '../../panic/application/panic_controller.dart';
import '../application/ai_controller.dart';

const guardianSuggestions = [
  'Someone is following me',
  'Safe way home at night',
  'What are my rights if police refuse an FIR?',
  'How to de-escalate a harasser',
];

Future<void> _dial(String n) => launchUrl(Uri(scheme: 'tel', path: n));

class AiGuardScreen extends ConsumerStatefulWidget {
  const AiGuardScreen({super.key});

  @override
  ConsumerState<AiGuardScreen> createState() => _AiGuardScreenState();
}

class _AiGuardScreenState extends ConsumerState<AiGuardScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final text = preset ?? _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    await ref.read(aiControllerProvider.notifier).send(text);
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final to = _scroll.position.maxScrollExtent;
      if (ShaktiMotion.reduced(context)) {
        _scroll.jumpTo(to);
      } else {
        _scroll.animateTo(to, duration: ShaktiMotion.navigation, curve: ShaktiMotion.curve);
      }
    });
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Clear this chat?'),
        content: const Text('All messages with Guardian are deleted from this phone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: ShaktiColors.sosGlow),
            child: const Text('Clear chat'),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(aiControllerProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(aiControllerProvider);
    final ctrl = ref.read(aiControllerProvider.notifier);
    ref.listen(aiControllerProvider.select((v) => (v.messages.length, v.typing)), (_, _) => _toBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guardian'),
        actions: [
          IconButton(
            tooltip: 'Draft an FIR',
            icon: const Icon(Icons.description_outlined),
            onPressed: () => context.push(Routes.fir),
          ),
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: s.messages.isEmpty ? null : _confirmClear,
          ),
        ],
      ),
      body: ShaktiBackdrop(
        child: LayoutBuilder(
          builder: (context, box) => Column(
            children: [
              if (s.showCrisis)
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: box.maxHeight * 0.38),
                    child: SingleChildScrollView(child: _CrisisBanner(onDismiss: ctrl.dismissCrisis)),
                  ),
                ),
              Expanded(
                child: !s.loaded
                    ? const Center(child: CircularProgressIndicator())
                    : s.messages.isEmpty && !s.typing
                    ? _EmptyChat(onPick: _send)
                    : ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          ShaktiSpace.lg,
                          ShaktiSpace.md,
                          ShaktiSpace.lg,
                          ShaktiSpace.md,
                        ),
                        children: [
                          for (final m in s.messages)
                            if (m.role != ChatRole.system) _Bubble(message: m),
                          if (s.showConcern) _ConcernCard(onDismiss: ctrl.dismissCrisis),
                          if (s.typing) const _Typing(),
                          if (s.error != null) _ErrorCard(message: s.error!, onRetry: ctrl.retry),
                        ],
                      ),
              ),
              _Composer(controller: _input, busy: s.typing, onSend: _send),
            ],
          ),
        ),
      ),
    );
  }
}

class _CrisisBanner extends ConsumerWidget {
  const _CrisisBanner({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const ValueKey('crisis-banner'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(ShaktiSpace.md, ShaktiSpace.sm, ShaktiSpace.xs, ShaktiSpace.sm),
        decoration: BoxDecoration(
          color: ShaktiColors.sosDeep,
          border: Border(bottom: BorderSide(color: ShaktiColors.sosGlow.withValues(alpha: 0.5))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emergency_rounded, color: ShaktiColors.textHi),
                const SizedBox(width: ShaktiSpace.xs),
                Expanded(child: Text('If you are in danger, get help now', style: t.titleMedium)),
                IconButton(
                  onPressed: onDismiss,
                  tooltip: 'Hide help banner',
                  color: ShaktiColors.textHi,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Wrap(
              spacing: ShaktiSpace.xs,
              runSpacing: ShaktiSpace.xs,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: ShaktiColors.textHi,
                    foregroundColor: ShaktiColors.sosDeep,
                  ),
                  onPressed: () => _dial('112'),
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call 112'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: ShaktiColors.sos),
                  onPressed: () => ref.read(panicControllerProvider.notifier).trigger(TriggerSource.hudTap),
                  icon: const Icon(Icons.sos_rounded),
                  label: const Text('Send SOS'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ShaktiColors.textHi,
                    side: const BorderSide(color: ShaktiColors.textHi),
                  ),
                  onPressed: () => _dial('181'),
                  icon: const Icon(Icons.support_agent_rounded),
                  label: const Text('181 Women helpline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConcernCard extends StatelessWidget {
  const _ConcernCard({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: ShaktiSpace.sm),
      child: Container(
        padding: const EdgeInsets.all(ShaktiSpace.md),
        decoration: BoxDecoration(
          color: ShaktiColors.warn.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(ShaktiRadius.md),
          border: Border.all(color: ShaktiColors.warn.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: ShaktiColors.warn),
            const SizedBox(width: ShaktiSpace.sm),
            Expanded(
              child: Text(
                'You do not have to handle this alone. Tell someone you trust, and remember 181 is free and open all day.',
                style: t.bodyMedium?.copyWith(color: ShaktiColors.textHi),
              ),
            ),
            IconButton(onPressed: onDismiss, tooltip: 'Hide tip', icon: const Icon(Icons.close_rounded)),
          ],
        ),
      ),
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(ShaktiSpace.lg, ShaktiSpace.md, ShaktiSpace.lg, ShaktiSpace.lg),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GlassSurface(
            radius: ShaktiRadius.card,
            padding: const EdgeInsets.all(ShaktiSpace.md),
            color: ShaktiColors.ambient,
            child: const Icon(Icons.auto_awesome_rounded, color: ShaktiColors.lilac, size: 32),
          ),
        ),
        const SizedBox(height: ShaktiSpace.lg),
        Text('A calmer next step.', style: t.headlineLarge),
        const SizedBox(height: ShaktiSpace.xs),
        Text('Ask Guardian anything about staying safe', style: t.titleMedium),
        const SizedBox(height: ShaktiSpace.sm),
        Text(
          'Short, practical answers about your rights, routes and what to do right now. Not a replacement for 112.',
          style: t.bodyMedium,
        ),
        const SizedBox(height: ShaktiSpace.lg),
        for (final q in guardianSuggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: ShaktiSpace.xs),
            child: GlassSurface(
              onTap: () => onPick(q),
              semanticLabel: q,
              padding: const EdgeInsets.all(ShaktiSpace.md),
              radius: ShaktiRadius.md,
              child: Row(
                children: [
                  Expanded(
                    child: Text(q, style: t.bodyMedium?.copyWith(color: ShaktiColors.textHi)),
                  ),
                  const SizedBox(width: ShaktiSpace.sm),
                  const Icon(Icons.north_east_rounded, size: 20, color: ShaktiColors.lilac),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final mine = message.role == ChatRole.user;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.86),
        child: Container(
          margin: const EdgeInsets.only(bottom: ShaktiSpace.sm),
          padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.md, vertical: ShaktiSpace.sm),
          decoration: BoxDecoration(
            color: mine ? ShaktiColors.ambient : ShaktiColors.surface,
            border: Border.all(color: mine ? ShaktiColors.lilac.withValues(alpha: 0.4) : ShaktiColors.glassEdge),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(ShaktiRadius.card),
              topRight: const Radius.circular(ShaktiRadius.card),
              bottomLeft: Radius.circular(mine ? ShaktiRadius.card : ShaktiRadius.sm),
              bottomRight: Radius.circular(mine ? ShaktiRadius.sm : ShaktiRadius.card),
            ),
          ),
          child: Semantics(
            label: mine ? 'You said' : 'Guardian said',
            child: SelectableText(message.content, style: t.bodyLarge?.copyWith(color: ShaktiColors.textHi)),
          ),
        ),
      ),
    );
  }
}

class _Typing extends StatelessWidget {
  const _Typing();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Semantics(
        liveRegion: true,
        label: 'Guardian is typing',
        excludeSemantics: true,
        child: Container(
          key: const ValueKey('typing'),
          margin: const EdgeInsets.only(bottom: ShaktiSpace.sm),
          padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.md, vertical: ShaktiSpace.sm),
          decoration: BoxDecoration(
            color: ShaktiColors.surfaceHigh,
            borderRadius: BorderRadius.circular(ShaktiRadius.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!ShaktiMotion.reduced(context))
                const SizedBox.square(dimension: 14, child: CircularProgressIndicator(strokeWidth: 2)),
              if (!ShaktiMotion.reduced(context)) const SizedBox(width: ShaktiSpace.xs),
              Text('Guardian is typing…', style: t.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: ShaktiSpace.sm),
      padding: const EdgeInsets.all(ShaktiSpace.md),
      decoration: BoxDecoration(
        color: ShaktiColors.surface,
        borderRadius: BorderRadius.circular(ShaktiRadius.md),
        border: Border.all(color: ShaktiColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: ShaktiColors.warn),
              const SizedBox(width: ShaktiSpace.xs),
              Expanded(child: Text(message, style: t.titleSmall)),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ),
          const Divider(),
          const SizedBox(height: ShaktiSpace.xs),
          Text('Safety tips that work offline', style: t.labelMedium),
          const SizedBox(height: ShaktiSpace.xs),
          for (final tip in offlineSafetyTips)
            Padding(
              padding: const EdgeInsets.only(bottom: ShaktiSpace.xs),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(Icons.check_circle_outline_rounded, size: 16, color: ShaktiColors.safe),
                  ),
                  const SizedBox(width: ShaktiSpace.xs),
                  Expanded(child: Text(tip, style: t.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.busy, required this.onSend});

  final TextEditingController controller;
  final bool busy;
  final ValueChanged<String?> onSend;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ShaktiSpace.md,
        ShaktiSpace.xs,
        ShaktiSpace.md,
        keyboardOpen ? ShaktiSpace.sm : ShaktiSpace.dockClearance,
      ),
      child: GlassSurface(
        radius: ShaktiRadius.card,
        padding: const EdgeInsets.all(ShaktiSpace.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('chat-input'),
                controller: controller,
                minLines: 1,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Message Guardian',
                  labelText: null,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
            const SizedBox(width: ShaktiSpace.xs),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: IconButton.filled(
                onPressed: busy ? null : () => onSend(null),
                tooltip: 'Send message',
                style: IconButton.styleFrom(
                  backgroundColor: ShaktiColors.lilac,
                  foregroundColor: ShaktiColors.bg,
                  minimumSize: const Size(52, 52),
                ),
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
