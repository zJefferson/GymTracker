import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'database_provider.dart';

final workoutsStreamProvider = StreamProvider<List<Workout>>((ref) {
  return ref.watch(databaseProvider).watchWorkouts();
});

final workoutStreamProvider =
    StreamProvider.family<Workout?, String>((ref, workoutId) {
  return ref.watch(databaseProvider).watchWorkout(workoutId);
});

final workoutExercisesStreamProvider =
    StreamProvider.family<List<WorkoutExerciseWithDetails>, String>(
        (ref, workoutId) {
  return ref.watch(databaseProvider).watchWorkoutExercises(workoutId);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

class WorkoutRepository {
  final AppDatabase db;
  WorkoutRepository(this.db);

  Future<void> saveWorkout({
    required String id,
    required String name,
    required String letter,
    required int colorValue,
    required int iconCodePoint,
    int? position,
  }) async {
    final pos = position ?? await db.nextWorkoutPosition();
    await db.upsertWorkout(WorkoutsCompanion(
      id: Value(id),
      name: Value(name),
      letter: Value(letter),
      colorValue: Value(colorValue),
      iconCodePoint: Value(iconCodePoint),
      position: Value(pos),
    ));
  }

  Future<void> deleteWorkout(String id) => db.deleteWorkout(id);

  Future<void> addOrUpdateExerciseInWorkout({
    required String linkId,
    required String workoutId,
    required String exerciseId,
    required int sets,
    required int reps,
    required double load,
    required int restSeconds,
    required String notes,
    int? order,
  }) async {
    final ord = order ?? await db.nextExerciseOrder(workoutId);
    await db.upsertWorkoutExercise(WorkoutExercisesCompanion(
      id: Value(linkId),
      workoutId: Value(workoutId),
      exerciseId: Value(exerciseId),
      sortOrder: Value(ord),
      sets: Value(sets),
      reps: Value(reps),
      load: Value(load),
      restSeconds: Value(restSeconds),
      notes: Value(notes),
    ));
  }

  Future<void> removeExerciseFromWorkout(String linkId) =>
      db.deleteWorkoutExercise(linkId);

  Future<void> reorder(List<String> orderedLinkIds) =>
      db.reorderWorkoutExercises(orderedLinkIds);

  Future<Workout?> duplicateWorkout(Workout source) async {
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await saveWorkout(
      id: newId,
      name: '${source.name} (cópia)',
      letter: source.letter,
      colorValue: source.colorValue,
      iconCodePoint: source.iconCodePoint,
    );
    final exercises = await db.watchWorkoutExercises(source.id).first;
    for (final ex in exercises) {
      await addOrUpdateExerciseInWorkout(
        linkId: '${newId}_${ex.link.exerciseId}_${ex.link.sortOrder}',
        workoutId: newId,
        exerciseId: ex.link.exerciseId,
        sets: ex.link.sets,
        reps: ex.link.reps,
        load: ex.link.load,
        restSeconds: ex.link.restSeconds,
        notes: ex.link.notes,
        order: ex.link.sortOrder,
      );
    }
    return db.getWorkout(newId);
  }
}
