import 'package:drift/drift.dart';

import 'connection.dart' as impl;
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Workouts,
  MuscleCategories,
  Exercises,
  WorkoutExercises,
  HistorySessions,
  HistoryEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.connect());
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(exercises, exercises.animationPattern);
          }
          if (from < 3) {
            await m.addColumn(exercises, exercises.videoId);
          }
        },
      );

  // ---------------- Workouts ----------------

  Stream<List<Workout>> watchWorkouts() {
    return (select(workouts)..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  Future<Workout?> getWorkout(String id) {
    return (select(workouts)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<Workout?> watchWorkout(String id) {
    return (select(workouts)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> upsertWorkout(WorkoutsCompanion entry) {
    return into(workouts).insertOnConflictUpdate(entry);
  }

  Future<void> deleteWorkout(String id) {
    return (delete(workouts)..where((t) => t.id.equals(id))).go();
  }

  Future<int> nextWorkoutPosition() async {
    final rows = await select(workouts).get();
    if (rows.isEmpty) return 0;
    return rows.map((w) => w.position).reduce((a, b) => a > b ? a : b) + 1;
  }

  // ---------------- Muscle categories ----------------

  Stream<List<MuscleCategory>> watchMuscleCategories() {
    return (select(muscleCategories)
          ..orderBy([(t) => OrderingTerm.asc(t.position)]))
        .watch();
  }

  Future<void> upsertMuscleCategory(MuscleCategoriesCompanion entry) {
    return into(muscleCategories).insertOnConflictUpdate(entry);
  }

  // ---------------- Exercises (library) ----------------

  Stream<List<Exercise>> watchAllExercises() {
    return (select(exercises)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Exercise?> getExercise(String id) {
    return (select(exercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<Exercise?> watchExercise(String id) {
    return (select(exercises)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> upsertExercise(ExercisesCompanion entry) {
    return into(exercises).insertOnConflictUpdate(entry);
  }

  Future<void> deleteExercise(String id) {
    return (delete(exercises)..where((t) => t.id.equals(id))).go();
  }

  Future<void> setFavorite(String id, bool isFavorite) {
    return (update(exercises)..where((t) => t.id.equals(id)))
        .write(ExercisesCompanion(isFavorite: Value(isFavorite)));
  }

  // ---------------- Workout <-> Exercise link ----------------

  Stream<List<WorkoutExerciseWithDetails>> watchWorkoutExercises(
      String workoutId) {
    final query = select(workoutExercises).join([
      innerJoin(exercises,
          exercises.id.equalsExp(workoutExercises.exerciseId)),
    ])
      ..where(workoutExercises.workoutId.equals(workoutId))
      ..orderBy([OrderingTerm.asc(workoutExercises.sortOrder)]);

    return query.watch().map((rows) {
      return rows
          .map((row) => WorkoutExerciseWithDetails(
                link: row.readTable(workoutExercises),
                exercise: row.readTable(exercises),
              ))
          .toList();
    });
  }

  Future<WorkoutExercise?> getWorkoutExerciseLink(String id) {
    return (select(workoutExercises)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<int> nextExerciseOrder(String workoutId) async {
    final rows = await (select(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId)))
        .get();
    if (rows.isEmpty) return 0;
    return rows.map((e) => e.sortOrder).reduce((a, b) => a > b ? a : b) + 1;
  }

  Future<void> upsertWorkoutExercise(WorkoutExercisesCompanion entry) {
    return into(workoutExercises).insertOnConflictUpdate(entry);
  }

  Future<void> deleteWorkoutExercise(String id) {
    return (delete(workoutExercises)..where((t) => t.id.equals(id))).go();
  }

  Future<void> reorderWorkoutExercises(List<String> orderedLinkIds) async {
    await batch((b) {
      for (var i = 0; i < orderedLinkIds.length; i++) {
        b.update(
          workoutExercises,
          WorkoutExercisesCompanion(sortOrder: Value(i)),
          where: (t) => t.id.equals(orderedLinkIds[i]),
        );
      }
    });
  }

  Future<int> countWorkoutsUsingExercise(String exerciseId) async {
    final rows = await (select(workoutExercises)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
    return rows.length;
  }

  // ---------------- History ----------------

  Stream<List<HistorySession>> watchHistory() {
    return (select(historySessions)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .watch();
  }

  Future<void> insertHistorySession(HistorySessionsCompanion session) {
    return into(historySessions).insert(session);
  }

  Future<void> insertHistoryEntries(List<HistoryEntriesCompanion> entries) {
    return batch((b) => b.insertAll(historyEntries, entries));
  }

  Future<List<HistoryEntry>> historyEntriesForSession(String sessionId) {
    return (select(historyEntries)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }

  Future<HistorySession?> lastSessionForWorkout(String workoutId) {
    return (select(historySessions)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm.desc(t.date)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<HistoryEntry?> lastEntryForExercise(String exerciseId) async {
    final query = select(historyEntries).join([
      innerJoin(historySessions,
          historySessions.id.equalsExp(historyEntries.sessionId)),
    ])
      ..where(historyEntries.exerciseId.equals(exerciseId))
      ..orderBy([OrderingTerm.desc(historySessions.date)])
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(historyEntries);
  }

  Future<double> bestLoadForExercise(String exerciseId) async {
    final rows = await (select(historyEntries)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
    if (rows.isEmpty) return 0;
    return rows.map((e) => e.load).reduce((a, b) => a > b ? a : b);
  }
}

class WorkoutExerciseWithDetails {
  final WorkoutExercise link;
  final Exercise exercise;

  WorkoutExerciseWithDetails({required this.link, required this.exercise});
}
