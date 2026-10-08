import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/database/database.dart';
import '../../data/database/tables.dart';
import '../../data/seed/muscle_categories_seed.dart';
import '../../providers/exercise_providers.dart';

const _equipmentLabels = {
  EquipmentType.machine: 'Máquina',
  EquipmentType.freeWeight: 'Peso livre',
  EquipmentType.barbell: 'Barra',
  EquipmentType.dumbbell: 'Halter',
  EquipmentType.cable: 'Polia',
  EquipmentType.bodyweight: 'Peso corporal',
  EquipmentType.other: 'Outro',
};

class ExerciseLibraryScreen extends ConsumerWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedCategory = ref.watch(exerciseFilterCategoryProvider);
    final selectedEquipment = ref.watch(exerciseFilterEquipmentProvider);
    final favoritesOnly = ref.watch(exerciseFavoritesOnlyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblioteca de Exercícios'),
        actions: [
          IconButton(
            icon: Icon(favoritesOnly ? Icons.favorite : Icons.favorite_border),
            tooltip: 'Somente favoritos',
            onPressed: () => ref
                .read(exerciseFavoritesOnlyProvider.notifier)
                .state = !favoritesOnly,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar por nome, grupo ou equipamento...',
              ),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'Todos os grupos',
                  selected: selectedCategory == null,
                  onTap: () => ref
                      .read(exerciseFilterCategoryProvider.notifier)
                      .state = null,
                ),
                const SizedBox(width: 8),
                ...muscleCategorySeeds.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: c.name,
                        selected: selectedCategory == c.id,
                        onTap: () => ref
                            .read(exerciseFilterCategoryProvider.notifier)
                            .state = selectedCategory == c.id ? null : c.id,
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: EquipmentType.values.map((eq) {
                final selected = selectedEquipment == eq;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _FilterChip(
                    label: _equipmentLabels[eq]!,
                    selected: selected,
                    onTap: () => ref
                        .read(exerciseFilterEquipmentProvider.notifier)
                        .state = selected ? null : eq,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercises.isEmpty
                ? const Center(child: Text('Nenhum exercício encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: exercises.length,
                    itemBuilder: (context, index) {
                      final e = exercises[index];
                      return _ExerciseListTile(exercise: e);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ExerciseListTile extends ConsumerWidget {
  final Exercise exercise;
  const _ExerciseListTile({required this.exercise});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(exercise.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${exercise.muscleGroup} · ${_equipmentLabels[exercise.equipment]}'),
        trailing: IconButton(
          icon: Icon(
            exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: exercise.isFavorite
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () =>
              ref.read(exerciseRepositoryProvider).toggleFavorite(exercise),
        ),
        onTap: () => context.push('/library/${exercise.id}'),
      ),
    );
  }
}
