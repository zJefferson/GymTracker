import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/history_providers.dart';
import '../../services/notification_service.dart';

class _SetState {
  final TextEditingController repsController;
  final TextEditingController loadController;
  bool completed = false;

  _SetState({
    required int reps,
    required double load,
  })  : repsController = TextEditingController(text: reps.toString()),
        loadController = TextEditingController(
            text: load.toStringAsFixed(load % 1 == 0 ? 0 : 1));

  void dispose() {
    repsController.dispose();
    loadController.dispose();
  }
}

class _ExerciseSessionState {
  final WorkoutExerciseWithDetails details;
  final List<_SetState> sets;
  _ExerciseSessionState({required this.details, required this.sets});
}

class WorkoutSessionScreen extends ConsumerStatefulWidget {
  final String workoutId;
  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  bool _loading = true;
  Workout? _workout;
  List<_ExerciseSessionState> _exercises = [];
  late DateTime _startedAt;

  Timer? _elapsedTicker;
  Duration _elapsed = Duration.zero;

  Timer? _restTimer;
  int _restRemaining = 0;
  int _restTotal = 0;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    NotificationService.instance.init();
    _elapsedTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final workout = await db.getWorkout(widget.workoutId);
    final links = await db.watchWorkoutExercises(widget.workoutId).first;
    if (!mounted) return;
    setState(() {
      _workout = workout;
      _exercises = links
          .map((l) => _ExerciseSessionState(
                details: l,
                sets: List.generate(
                  l.link.sets,
                  (_) => _SetState(reps: l.link.reps, load: l.link.load),
                ),
              ))
          .toList();
      _loading = false;
    });
  }

  @override
  void dispose() {
    _elapsedTicker?.cancel();
    _restTimer?.cancel();
    for (final ex in _exercises) {
      for (final s in ex.sets) {
        s.dispose();
      }
    }
    super.dispose();
  }

  void _startRest(int seconds) {
    _restTimer?.cancel();
    if (seconds <= 0) return;
    setState(() {
      _restTotal = seconds;
      _restRemaining = seconds;
    });
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted) return;
      if (_restRemaining <= 1) {
        timer.cancel();
        setState(() => _restRemaining = 0);
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.vibrate();
        await NotificationService.instance.showRestFinished();
      } else {
        setState(() => _restRemaining -= 1);
      }
    });
  }

  void _skipRest() {
    _restTimer?.cancel();
    setState(() => _restRemaining = 0);
  }

  void _toggleSet(_ExerciseSessionState exercise, _SetState set) {
    setState(() => set.completed = !set.completed);
    if (set.completed) {
      _startRest(exercise.details.link.restSeconds);
    }
  }

  Future<void> _finishWorkout() async {
    _elapsedTicker?.cancel();
    _restTimer?.cancel();

    final logs = _exercises.map((ex) {
      final completedSets = <CompletedSetLog>[];
      for (var i = 0; i < ex.sets.length; i++) {
        final s = ex.sets[i];
        if (!s.completed) continue;
        completedSets.add(CompletedSetLog(
          setNumber: i + 1,
          reps: int.tryParse(s.repsController.text) ?? ex.details.link.reps,
          load: double.tryParse(s.loadController.text.replaceAll(',', '.')) ??
              ex.details.link.load,
        ));
      }
      return CompletedExerciseLog(
        exerciseId: ex.details.exercise.id,
        exerciseName: ex.details.exercise.name,
        sets: completedSets,
      );
    }).toList();

    final totalCompletedSets =
        logs.fold<int>(0, (sum, l) => sum + l.sets.length);

    if (_workout != null && totalCompletedSets > 0) {
      await ref.read(historyRepositoryProvider).saveSession(
            workout: _workout!,
            duration: DateTime.now().difference(_startedAt),
            logs: logs,
          );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(totalCompletedSets > 0
            ? 'Treino concluído! $totalCompletedSets séries registradas.'
            : 'Treino finalizado sem séries registradas.'),
      ),
    );
    context.go('/workout/${widget.workoutId}');
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final color =
        _workout != null ? Color(_workout!.colorValue) : Colors.grey;

    return Scaffold(
      appBar: AppBar(
        title: Text(_workout != null
            ? 'Treino ${_workout!.letter} · ${_formatDuration(_elapsed)}'
            : 'Treino'),
        actions: [
          TextButton(
            onPressed: _finishWorkout,
            child: const Text('Finalizar'),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16, _restRemaining > 0 ? 120 : 24),
            itemCount: _exercises.length,
            itemBuilder: (context, index) {
              final ex = _exercises[index];
              final allDone = ex.sets.every((s) => s.completed);
              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ex.details.exercise.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (allDone)
                            Icon(Icons.check_circle, color: color),
                        ],
                      ),
                      Text(
                        'Descanso: ${ex.details.link.restSeconds}s',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (ex.details.link.notes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            ex.details.link.notes,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontStyle: FontStyle.italic),
                          ),
                        ),
                      const SizedBox(height: 12),
                      ...ex.sets.asMap().entries.map((entry) {
                        final setIndex = entry.key;
                        final set = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text('${setIndex + 1}ª',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: set.repsController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'Reps',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: set.loadController,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  textAlign: TextAlign.center,
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    labelText: 'kg',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: Icon(
                                  set.completed
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: set.completed ? color : null,
                                ),
                                onPressed: () => _toggleSet(ex, set),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_restRemaining > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Material(
                elevation: 8,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Descansando...',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _restTotal == 0
                                  ? 0
                                  : _restRemaining / _restTotal,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_restRemaining}s',
                        style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color:
                                Theme.of(context).colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _skipRest,
                        child: const Text('Pular'),
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
