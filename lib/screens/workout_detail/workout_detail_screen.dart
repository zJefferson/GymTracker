import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/database.dart';
import '../../providers/workout_providers.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final String workoutId;
  const WorkoutDetailScreen({super.key, required this.workoutId});

  Future<void> _confirmRemoveExercise(
      BuildContext context, WidgetRef ref, String linkId, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover exercício'),
        content: Text('Remover "$name" deste treino?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remover')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutRepositoryProvider).removeExerciseFromWorkout(linkId);
    }
  }

  void _showExerciseOptions(BuildContext context, String workoutId,
      WorkoutExerciseWithDetails item) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smart_display_outlined),
              title: const Text('Ver tutorial (vídeo)'),
              subtitle: Text(item.exercise.name),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/library/${item.exercise.id}');
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Editar séries, carga e descanso'),
              onTap: () {
                Navigator.pop(sheetContext);
                context.push(
                    '/workout/$workoutId/exercise/${item.link.id}/edit');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(workoutStreamProvider(workoutId));

    return workoutAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (workout) {
        final color =
            workout != null ? Color(workout.colorValue) : Colors.grey;

        final exercisesAsync =
            ref.watch(workoutExercisesStreamProvider(workoutId));

        return Scaffold(
          appBar: AppBar(
            title: Text(workout != null
                ? '${workout.letter} · ${workout.name}'
                : 'Treino'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push('/workout/$workoutId/edit'),
              ),
            ],
          ),
          body: exercisesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Erro: $err')),
            data: (items) {
              if (items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.playlist_add,
                            size: 56, color: color.withValues(alpha: 0.6)),
                        const SizedBox(height: 16),
                        const Text('Nenhum exercício neste treino ainda.'),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => context
                              .push('/workout/$workoutId/exercise/new'),
                          icon: const Icon(Icons.add),
                          label: const Text('Adicionar exercício'),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: items.length,
                      onReorder: (oldIndex, newIndex) async {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final reordered = [...items];
                        final moved = reordered.removeAt(oldIndex);
                        reordered.insert(newIndex, moved);
                        await ref.read(workoutRepositoryProvider).reorder(
                            reordered.map((e) => e.link.id).toList());
                      },
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Card(
                          key: ValueKey(item.link.id),
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color.withValues(alpha: 0.2),
                              foregroundColor: color,
                              child: Text('${index + 1}'),
                            ),
                            title: Text(item.exercise.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(
                                '${item.link.sets}x${item.link.reps} · ${item.link.load.toStringAsFixed(item.link.load % 1 == 0 ? 0 : 1)} kg · descanso ${item.link.restSeconds}s'),
                            onTap: () => _showExerciseOptions(
                                context, workoutId, item),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => _confirmRemoveExercise(context,
                                  ref, item.link.id, item.exercise.name),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context
                                .push('/workout/$workoutId/exercise/new'),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                context.push('/workout/$workoutId/session'),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Iniciar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
