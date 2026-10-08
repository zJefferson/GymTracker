import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/database.dart';
import '../../providers/workout_providers.dart';
import '../../widgets/workout_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Workout workout) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir treino'),
        content: Text(
            'Tem certeza que deseja excluir "${workout.name}"? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(workoutRepositoryProvider).deleteWorkout(workout.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('GymTracker')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/workout/new'),
        icon: const Icon(Icons.add),
        label: const Text('Criar novo treino'),
      ),
      body: workoutsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (workouts) {
          if (workouts.isEmpty) {
            return _EmptyState(onCreate: () => context.push('/workout/new'));
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: workouts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              final exercisesAsync =
                  ref.watch(workoutExercisesStreamProvider(workout.id));
              return WorkoutCard(
                workout: workout,
                exerciseCount: exercisesAsync.value?.length ?? 0,
                onTap: () => context.push('/workout/${workout.id}'),
                onEdit: () => context.push('/workout/${workout.id}/edit'),
                onDuplicate: () async {
                  await ref
                      .read(workoutRepositoryProvider)
                      .duplicateWorkout(workout);
                },
                onDelete: () => _confirmDelete(context, ref, workout),
              );
            },
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCreate;
  const _EmptyState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
            const SizedBox(height: 16),
            Text(
              'Nenhum treino cadastrado',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Crie seu primeiro treino (A, B, C...) e monte sua ficha do jeito que preferir.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('Criar novo treino'),
            ),
          ],
        ),
      ),
    );
  }
}
