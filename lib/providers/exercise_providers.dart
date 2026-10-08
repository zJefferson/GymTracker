import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../data/database/database.dart';
import '../data/database/tables.dart';
import 'database_provider.dart';

final exercisesStreamProvider = StreamProvider<List<Exercise>>((ref) {
  return ref.watch(databaseProvider).watchAllExercises();
});

final exerciseByIdStreamProvider =
    StreamProvider.family<Exercise?, String>((ref, exerciseId) {
  return ref.watch(databaseProvider).watchExercise(exerciseId);
});

final muscleCategoriesStreamProvider =
    StreamProvider<List<MuscleCategory>>((ref) {
  return ref.watch(databaseProvider).watchMuscleCategories();
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');
final exerciseFilterCategoryProvider = StateProvider<String?>((ref) => null);
final exerciseFilterEquipmentProvider =
    StateProvider<EquipmentType?>((ref) => null);
final exerciseFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

final filteredExercisesProvider = Provider<List<Exercise>>((ref) {
  final exercisesAsync = ref.watch(exercisesStreamProvider);
  final query = ref.watch(exerciseSearchQueryProvider).trim().toLowerCase();
  final category = ref.watch(exerciseFilterCategoryProvider);
  final equipment = ref.watch(exerciseFilterEquipmentProvider);
  final favoritesOnly = ref.watch(exerciseFavoritesOnlyProvider);

  final list = exercisesAsync.value ?? const <Exercise>[];
  return list.where((e) {
    if (favoritesOnly && !e.isFavorite) return false;
    if (category != null && e.muscleGroup != category) return false;
    if (equipment != null && e.equipment != equipment) return false;
    if (query.isNotEmpty &&
        !e.name.toLowerCase().contains(query) &&
        !e.muscleGroup.toLowerCase().contains(query)) {
      return false;
    }
    return true;
  }).toList();
});

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository(ref.watch(databaseProvider));
});

class ExerciseRepository {
  final AppDatabase db;
  ExerciseRepository(this.db);

  Future<void> toggleFavorite(Exercise exercise) =>
      db.setFavorite(exercise.id, !exercise.isFavorite);

  Future<void> saveExercise(ExercisesCompanion entry) => db.upsertExercise(entry);

  Future<bool> deleteExercise(String id) async {
    final usageCount = await db.countWorkoutsUsingExercise(id);
    if (usageCount > 0) return false;
    await db.deleteExercise(id);
    return true;
  }
}
