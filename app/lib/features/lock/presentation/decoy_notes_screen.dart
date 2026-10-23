import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/router/gate.dart';
import '../../../core/theme/tokens.dart';

class _Note {
  _Note(this.title, this.body, this.edited);
  String title;
  String body;
  DateTime edited;
}

/// A plain, believable notes app shown after the duress PIN. Nothing here
/// mentions safety or Shakti. Hidden exit: hold the "Notes" title for 3 s.
class DecoyNotesScreen extends ConsumerStatefulWidget {
  const DecoyNotesScreen({super.key});

  @override
  ConsumerState<DecoyNotesScreen> createState() => _DecoyNotesScreenState();
}

class _DecoyNotesScreenState extends ConsumerState<DecoyNotesScreen> {
  static const _exitHold = Duration(seconds: 3);
  Timer? _hold;

  late final List<_Note> _notes = () {
    final now = DateTime.now();
    return [
      _Note(
        'Groceries',
        'Milk 1L\nTomatoes\nCoriander\nAtta 5kg\nCurd\nBananas',
        now.subtract(const Duration(hours: 2)),
      ),
      _Note(
        'Class timings',
        'Mon  9:00  DBMS\nMon 11:15  Maths lab\nTue 10:00  Networks\nWed  2:00  Project review\nFri  9:00  OS',
        now.subtract(const Duration(days: 1)),
      ),
      _Note(
        'Birthday gift ideas',
        'Kurti from the Jayanagar shop\nPlant pot\nPhoto frame',
        now.subtract(const Duration(days: 4)),
      ),
      _Note(
        'Recharge',
        'Plan ends on 12th. 299 pack.',
        now.subtract(const Duration(days: 9)),
      ),
    ];
  }();

  @override
  void dispose() {
    _hold?.cancel();
    super.dispose();
  }

  void _startHold() {
    _hold?.cancel();
    _hold = Timer(
      _exitHold,
      () => ref.read(appGateProvider.notifier).set(AppGate.locked),
    );
  }

  void _endHold() {
    _hold?.cancel();
    _hold = null;
  }

  static String _when(DateTime d) {
    final now = DateTime.now();
    if (now.difference(d).inHours < 24 && now.day == d.day) {
      return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    }
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  Future<void> _open([_Note? note]) async {
    final saved = await Navigator.of(
      context,
    ).push<_Note>(MaterialPageRoute(builder: (_) => _NoteEditor(note: note)));
    if (!mounted || saved == null) return;
    setState(() {
      if (note == null) {
        if (saved.title.trim().isNotEmpty || saved.body.trim().isNotEmpty) {
          _notes.insert(0, saved);
        }
      } else {
        _notes
          ..remove(note)
          ..insert(0, note);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final theme = _stealthTheme(base);
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: ShaktiColors.stealthBg,
        appBar: AppBar(
          backgroundColor: ShaktiColors.stealthBg,
          foregroundColor: ShaktiColors.stealthInk,
          title: GestureDetector(
            key: const ValueKey('decoy-title'),
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _startHold(),
            onTapUp: (_) => _endHold(),
            onTapCancel: _endHold,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: ShaktiSpace.xs),
              child: Text('Notes'),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.md),
              child: Center(
                child: Text(
                  '${_notes.length}',
                  semanticsLabel: '${_notes.length} notes',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _open,
          tooltip: 'New note',
          backgroundColor: ShaktiColors.lightSurface,
          foregroundColor: ShaktiColors.stealthInk,
          child: const Icon(Icons.edit_outlined),
        ),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            ShaktiSpace.md,
            ShaktiSpace.md,
            ShaktiSpace.md,
            96,
          ),
          itemCount: _notes.length,
          separatorBuilder: (_, _) => const SizedBox(height: ShaktiSpace.sm),
          itemBuilder: (context, i) {
            final n = _notes[i];
            return Material(
              color: ShaktiColors.lightSurface,
              borderRadius: BorderRadius.circular(ShaktiRadius.md),
              child: InkWell(
                borderRadius: BorderRadius.circular(ShaktiRadius.md),
                onTap: () => _open(n),
                child: Padding(
                  padding: const EdgeInsets.all(ShaktiSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n.title.isEmpty ? 'Untitled' : n.title,
                        style: theme.textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: ShaktiSpace.xxs),
                      Text(
                        n.body.replaceAll('\n', ', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: ShaktiSpace.sm),
                      Text(_when(n.edited), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

ThemeData _stealthTheme(ThemeData base) {
  const ink = ShaktiColors.stealthInk;
  final text = base.textTheme.apply(
    bodyColor: ink,
    displayColor: ink,
    fontFamily: ShaktiFonts.body,
  );
  return base.copyWith(
    brightness: Brightness.light,
    scaffoldBackgroundColor: ShaktiColors.stealthBg,
    colorScheme: base.colorScheme.copyWith(
      brightness: Brightness.light,
      primary: ink,
      onPrimary: ShaktiColors.stealthBg,
      surface: ShaktiColors.stealthBg,
      onSurface: ink,
      onSurfaceVariant: ShaktiColors.lightTextMid,
    ),
    textTheme: text.copyWith(
      titleLarge: text.titleLarge?.copyWith(
        fontFamily: ShaktiFonts.body,
        fontWeight: FontWeight.w700,
      ),
      bodySmall: text.bodySmall?.copyWith(color: ShaktiColors.lightTextLo),
      bodyMedium: text.bodyMedium?.copyWith(color: ShaktiColors.lightTextMid),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: ShaktiColors.stealthBg,
      foregroundColor: ink,
      titleTextStyle: text.titleLarge?.copyWith(
        fontFamily: ShaktiFonts.body,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: InputBorder.none,
      filled: false,
    ),
  );
}

class _NoteEditor extends StatefulWidget {
  const _NoteEditor({this.note});

  final _Note? note;

  @override
  State<_NoteEditor> createState() => _NoteEditorState();
}

class _NoteEditorState extends State<_NoteEditor> {
  late final _title = TextEditingController(text: widget.note?.title ?? '');
  late final _body = TextEditingController(text: widget.note?.body ?? '');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  _Note _result() {
    final n = widget.note;
    if (n == null) return _Note(_title.text, _body.text, DateTime.now());
    return n
      ..title = _title.text
      ..body = _body.text
      ..edited = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final theme = _stealthTheme(Theme.of(context));
    return Theme(
      data: theme,
      child: PopScope<_Note>(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) Navigator.of(context).pop(_result());
        },
        child: Scaffold(
          backgroundColor: ShaktiColors.stealthBg,
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Back',
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(_result()),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ShaktiSpace.md),
            child: Column(
              children: [
                TextField(
                  controller: _title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: ShaktiFonts.body,
                  ),
                  decoration: const InputDecoration(hintText: 'Title'),
                ),
                Expanded(
                  child: TextField(
                    controller: _body,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: theme.textTheme.bodyLarge,
                    decoration: const InputDecoration(hintText: 'Note'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
