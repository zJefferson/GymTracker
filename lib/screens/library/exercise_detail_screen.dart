import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/tables.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/history_providers.dart';
import '../../widgets/exercise_animation/exercise_animation_view.dart';
import '../../widgets/exercise_video_player.dart';

const _equipmentLabels = {
  EquipmentType.machine: 'Máquina',
  EquipmentType.freeWeight: 'Peso livre',
  EquipmentType.barbell: 'Barra',
  EquipmentType.dumbbell: 'Halter',
  EquipmentType.cable: 'Polia',
  EquipmentType.bodyweight: 'Peso corporal',
  EquipmentType.other: 'Outro',
};

const _difficultyLabels = {
  Difficulty.beginner: 'Iniciante',
  Difficulty.intermediate: 'Intermediário',
  Difficulty.advanced: 'Avançado',
};

class ExerciseDetailScreen extends ConsumerWidget {
  final String exerciseId;
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseByIdStreamProvider(exerciseId));

    return exerciseAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Erro: $err'))),
      data: (exercise) {
        if (exercise == null) {
          return const Scaffold(
              body: Center(child: Text('Exercício não encontrado')));
        }

        final steps = exercise.executionSteps
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();
        final mistakes = exercise.commonMistakes
            .split('\n')
            .where((s) => s.trim().isNotEmpty)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(exercise.name),
            actions: [
              IconButton(
                icon: Icon(
                  exercise.isFavorite ? Icons.favorite : Icons.favorite_border,
                ),
                onPressed: () => ref
                    .read(exerciseRepositoryProvider)
                    .toggleFavorite(exercise),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              if (exercise.videoId != null && exercise.videoId!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: ExerciseVideoPlayer(videoId: exercise.videoId!),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vídeo demonstrativo (requer conexão com a internet)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 200,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ExerciseAnimationView(patternId: exercise.animationPattern),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ainda sem vídeo cadastrado — ilustração do movimento',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(exercise.muscleGroup)),
                  Chip(label: Text(_equipmentLabels[exercise.equipment]!)),
                  Chip(label: Text(_difficultyLabels[exercise.difficulty]!)),
                ],
              ),
              const SizedBox(height: 20),
              _LastTimeCard(exerciseId: exerciseId),
              const SizedBox(height: 20),
              if (exercise.description.isNotEmpty) ...[
                _SectionTitle('Descrição'),
                Text(exercise.description),
                const SizedBox(height: 20),
              ],
              if (steps.isNotEmpty) ...[
                _SectionTitle('Passo a passo da execução'),
                ...steps.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            child: Text('${entry.key + 1}',
                                style: const TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
              ],
              if (exercise.breathingTip.isNotEmpty) ...[
                _SectionTitle('Respiração'),
                Text(exercise.breathingTip),
                const SizedBox(height: 20),
              ],
              if (mistakes.isNotEmpty) ...[
                _SectionTitle('Erros comuns'),
                ...mistakes.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.close, size: 18, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(child: Text(m)),
                        ],
                      ),
                    )),
                const SizedBox(height: 20),
              ],
              if (exercise.executionTips.isNotEmpty) ...[
                _SectionTitle('Dicas de execução'),
                Text(exercise.executionTips),
                const SizedBox(height: 20),
              ],
              if (exercise.primaryMuscles.isNotEmpty) ...[
                _SectionTitle('Músculos principais'),
                Text(exercise.primaryMuscles),
                const SizedBox(height: 12),
              ],
              if (exercise.secondaryMuscles.isNotEmpty) ...[
                _SectionTitle('Músculos secundários'),
                Text(exercise.secondaryMuscles),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
    );
  }
}

class _LastTimeCard extends ConsumerWidget {
  final String exerciseId;
  const _LastTimeCard({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastEntryAsync = ref.watch(lastEntryForExerciseProvider(exerciseId));
    final bestLoadAsync = ref.watch(bestLoadForExerciseProvider(exerciseId));

    return lastEntryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entry) {
        if (entry == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text(
                          'Você ainda não registrou este exercício em nenhum treino.')),
                ],
              ),
            ),
          );
        }
        final best = bestLoadAsync.value ?? entry.load;
        return Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Última vez',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(
                  '${entry.load.toStringAsFixed(entry.load % 1 == 0 ? 0 : 1)} kg · série ${entry.setNumber} · ${entry.reps} reps',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
                const SizedBox(height: 4),
                Text(
                  'Melhor carga registrada: ${best.toStringAsFixed(best % 1 == 0 ? 0 : 1)} kg',
                  style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.8),
                      fontSize: 13),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String formatRelativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays <= 0) return 'Hoje';
  if (diff.inDays == 1) return 'Ontem';
  if (diff.inDays < 30) return 'Há ${diff.inDays} dias';
  return DateFormat('dd/MM/yyyy').format(date);
}
