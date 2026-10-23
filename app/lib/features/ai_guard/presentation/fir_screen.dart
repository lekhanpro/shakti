import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../core/di/providers.dart';
import '../../../core/result.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../domain/engines/fir_template.dart';
import '../../../domain/entities/entities.dart';
import '../application/fir_pdf.dart';

final _incidentsProvider = StreamProvider.autoDispose<List<Incident>>(
  (ref) => ref.watch(incidentRepositoryProvider).watchAll(),
);

String _stamp(DateTime t) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.day)}/${two(t.month)}/${t.year}, ${two(t.hour)}:${two(t.minute)}';
}

class FirScreen extends ConsumerStatefulWidget {
  const FirScreen({this.incidentId, super.key});

  /// Pre-selects an incident (from History).
  final String? incidentId;

  @override
  ConsumerState<FirScreen> createState() => _FirScreenState();
}

class _FirScreenState extends ConsumerState<FirScreen> {
  final _name = TextEditingController();
  final _narrative = TextEditingController();
  final _accused = TextEditingController();
  final _draft = TextEditingController();
  final _form = GlobalKey<FormState>();
  String? _incidentId;
  bool _drafting = false;
  bool _exporting = false;
  bool _aiConsent = false;
  String? _note;

  @override
  void initState() {
    super.initState();
    _incidentId = widget.incidentId;
    ref
        .read(settingsRepositoryProvider)
        .load()
        .then((s) {
          if (mounted && _name.text.isEmpty) _name.text = s.userName;
        })
        .catchError((_) {});
  }

  @override
  void dispose() {
    for (final c in [_name, _narrative, _accused, _draft]) {
      c.dispose();
    }
    super.dispose();
  }

  Incident _manualIncident() => Incident(
    id: 'manual',
    source: TriggerSource.hudTap,
    status: IncidentStatus.resolved,
    createdAt: ref.read(clockProvider).now(),
    shareToken: '',
  );

  Future<FirInput> _input(List<Incident> incidents) async {
    final match = incidents.where((i) => i.id == _incidentId);
    final incident = match.isEmpty ? _manualIncident() : match.first;
    var crumbs = const <Breadcrumb>[];
    if (match.isNotEmpty) {
      try {
        crumbs = await ref
            .read(incidentRepositoryProvider)
            .breadcrumbs(incident.id);
      } catch (_) {}
    }
    return FirInput(
      incident: incident,
      breadcrumbs: crumbs,
      complainantName: _name.text.trim(),
      narrative: _narrative.text.trim(),
      accusedDescription: _accused.text.trim(),
    );
  }

  Future<void> _generate(List<Incident> incidents, {required bool ai}) async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _drafting = true;
      _note = null;
    });
    final input = await _input(incidents);
    if (!mounted) return;
    String text;
    String? note;
    if (ai) {
      final res = await ref
          .read(aiServiceProvider)
          .draftFir(input)
          .catchError((Object e) => Err<String>('$e'));
      text = res.when(
        ok: (v) => v,
        err: (_) =>
            FirTemplate.render(input, now: ref.read(clockProvider).now()),
      );
      if (!res.isOk) {
        note = 'AI drafting is unavailable, so the offline template was used.';
      }
    } else {
      text = FirTemplate.render(input, now: ref.read(clockProvider).now());
    }
    if (!mounted) return;
    setState(() {
      _draft.text = text;
      _drafting = false;
      _note = note;
    });
  }

  Future<void> _export(List<Incident> incidents) async {
    setState(() => _exporting = true);
    try {
      final match = incidents.where((i) => i.id == _incidentId);
      final bytes = await buildFirPdf(
        body: _draft.text,
        complainant: _name.text.trim(),
        date: ref.read(clockProvider).now(),
        place: match.isEmpty ? null : match.first.address,
      );
      await Printing.sharePdf(bytes: bytes, filename: 'shakti-fir-draft.pdf');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create the PDF. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final incidents = ref.watch(_incidentsProvider);
    final aiConfigured = ref.watch(aiBackendConfiguredProvider);
    final list = incidents.value ?? const <Incident>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Draft an FIR')),
      body: ShaktiBackdrop(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              ShaktiSpace.lg,
              0,
              ShaktiSpace.lg,
              ShaktiSpace.xxl,
            ),
            children: [
              const ShaktiPageHeader(
                title: 'Build your statement',
                subtitle:
                    'Your words, clearly recorded. Review before sharing.',
              ),
              _Disclaimer(),
              const SectionHeader('Incident'),
              incidents.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => Text(
                  'Could not load incidents. You can still write one manually.',
                  style: t.bodyMedium,
                ),
                data: (items) => DropdownButtonFormField<String?>(
                  initialValue: items.any((i) => i.id == _incidentId)
                      ? _incidentId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Link to a recorded incident',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No incident, write manually'),
                    ),
                    for (final i in items)
                      DropdownMenuItem<String?>(
                        value: i.id,
                        child: Text(
                          '${_stamp(i.createdAt)}, ${i.source.label}${i.address != null ? ', ${i.address}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _incidentId = v),
                ),
              ),
              const SectionHeader('Your statement'),
              GlassSurface(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Your full name',
                      ),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Enter your name as it should appear on the FIR'
                          : null,
                    ),
                    const SizedBox(height: ShaktiSpace.sm),
                    TextFormField(
                      controller: _narrative,
                      minLines: 4,
                      maxLines: 10,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'What happened',
                        alignLabelWithHint: true,
                        helperText: 'Where, when, and what was said or done, in your own words.',
                        helperMaxLines: 4,
                      ),
                      validator: (v) => (v ?? '').trim().length < 10
                          ? 'Describe what happened in a sentence or two'
                          : null,
                    ),
                    const SizedBox(height: ShaktiSpace.sm),
                    TextFormField(
                      controller: _accused,
                      minLines: 2,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Accused description (optional)',
                        alignLabelWithHint: true,
                        helperText: 'Height, clothes, vehicle number, anything you remember.',
                        helperMaxLines: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: ShaktiSpace.lg),
              if (aiConfigured)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Use AI for this statement'),
                  subtitle: const Text(
                    'Sends your statement, name and linked incident details to the online AI service to create a draft.',
                  ),
                  value: _aiConsent,
                  onChanged: _drafting
                      ? null
                      : (value) => setState(() => _aiConsent = value ?? false),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: ShaktiSpace.md),
                  child: Text(
                    'Online AI is not configured. You can create and edit an offline draft on this phone.',
                    style: t.bodyMedium,
                  ),
                ),
              Wrap(
                spacing: ShaktiSpace.sm,
                runSpacing: ShaktiSpace.sm,
                children: [
                  if (aiConfigured)
                    FilledButton.icon(
                      onPressed: _drafting || !_aiConsent
                          ? null
                          : () => _generate(list, ai: true),
                      icon: _drafting
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Draft with AI'),
                    ),
                  OutlinedButton.icon(
                    onPressed: _drafting
                        ? null
                        : () => _generate(list, ai: false),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Use offline template'),
                  ),
                ],
              ),
              if (_note != null) ...[
                const SizedBox(height: ShaktiSpace.sm),
                Semantics(
                  liveRegion: true,
                  child: GlassSurface(
                    borderColor: context.shakti.warn.withValues(alpha: 0.5),
                    child: Text(_note!, style: t.bodyMedium),
                  ),
                ),
              ],
              if (_draft.text.isNotEmpty) ...[
                const SectionHeader('Draft (you can edit it)'),
                TextField(
                  key: const ValueKey('fir-draft'),
                  controller: _draft,
                  minLines: 10,
                  maxLines: null,
                  style: t.bodyMedium?.copyWith(
                    color: context.shakti.textHi,
                    height: 1.55,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'FIR draft',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: ShaktiSpace.md),
                FilledButton.icon(
                  onPressed: _exporting ? null : () => _export(list),
                  icon: _exporting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Export PDF'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return GlassSurface(
      borderColor: context.shakti.lilac.withValues(alpha: 0.35),
      color: context.shakti.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.gavel_rounded, color: context.shakti.lilac),
          const SizedBox(width: ShaktiSpace.sm),
          Expanded(
            child: Text(
              '$firDisclaimer Police must register an FIR for a cognisable offence. If they refuse, you can send it to the Superintendent of Police.',
              style: t.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
