import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/providers.dart';
import '../../../core/theme/tokens.dart';
import '../../../domain/entities/entities.dart';

final savedPlacesProvider = StreamProvider<List<SafePlace>>(
    (ref) => ref.watch(safePlaceRepositoryProvider).watchAll());

class SafePlacesScreen extends ConsumerStatefulWidget {
  const SafePlacesScreen({super.key});
  @override
  ConsumerState<SafePlacesScreen> createState() => _SafePlacesState();
}
class _SafePlacesState extends ConsumerState<SafePlacesScreen> {
  bool _busy = false;
  Future<void> _add() async {
    final name = TextEditingController();
    final label = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Save your current location'),
      content: TextField(controller: name, maxLength: 60, decoration: const InputDecoration(labelText: 'Place name, e.g. Home')),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(onPressed: () { if (name.text.trim().isNotEmpty) Navigator.pop(ctx, name.text.trim()); }, child: const Text('Use current location'))]));
    name.dispose();
    if (label == null || !mounted) return;
    setState(() => _busy = true);
    try {
      final location = ref.read(locationServiceProvider);
      if (!await location.ensurePermission()) throw StateError('Location permission denied');
      final fix = (await location.currentFix()).valueOrNull;
      if (fix == null || ref.read(clockProvider).now().difference(fix.at).abs() > const Duration(minutes: 2)) {
        throw StateError('A recent location fix is required');
      }
      await ref.read(safePlaceRepositoryProvider).upsert(SafePlace(id: const Uuid().v4(), name: label, point: fix.point));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save this place. Enable location and try again.')));
    } finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _remove(SafePlace place) async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: Text('Remove ${place.name}?'), content: const Text('This place will no longer be available for arrival checks.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Remove'))]));
    if (ok != true || !mounted) return;
    try { await ref.read(safePlaceRepositoryProvider).delete(place.id); }
    catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not remove the place.'))); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Safe places')),
    floatingActionButton: FloatingActionButton.extended(onPressed: _busy ? null : _add,
      icon: const Icon(Icons.add_location_alt_outlined), label: Text(_busy ? 'Locating...' : 'Add current place')),
    body: ref.watch(savedPlacesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Could not load places.')),
      data: (places) => ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 100), children: [
        const Padding(padding: EdgeInsets.only(bottom: ShaktiSpace.md),
          child: Text('During Walk With Me, entering a 150 m radius prompts a PIN-protected arrival check. A saved place is not a guarantee of safety.')),
        if (places.isEmpty) const Text('No places saved. Add Home, College or another destination.'),
        for (final p in places) Card(child: ListTile(title: Text(p.name), subtitle: Text('${p.radiusM.toInt()} m arrival radius'),
          trailing: IconButton(tooltip: 'Remove ${p.name}', icon: const Icon(Icons.delete_outline), onPressed: () => _remove(p)))),
      ]),
    ));
}
