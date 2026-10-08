import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/database/database.dart';
import 'database_provider.dart';

const _uuid = Uuid();

final historyStreamProvider = StreamProvider<List<HistorySession>>((ref) {
  return ref.watch(databaseProvider).watchHistory();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(ref.watch(databaseProvider));
});

class CompletedSetLog {
  final int setNumber;
  final int reps;
  final double load;
  CompletedSetLog(
      {required this.setNumber, required this.reps, required this.load});
}

class CompletedExerciseLog {
  final String exerciseId;
  final String exerciseName;
  final List<CompletedSetLog> sets;
  CompletedExerciseLog(
      {required this.exerciseId,
      required this.exerciseName,
      required this.sets});
}

class HistoryRepository {
  final AppDatabase db;
  HistoryRepository(this.db);

  Future<void> saveSession({
    required Workout workout,
    required Duration duration,
    required List<CompletedExerciseLog> logs,
  }) async {
    final completedLogs = logs.where((l) => l.sets.isNotEmpty).toList();
    if (completedLogs.isEmpty) return;

    final sessionId = _uuid.v4();
    final totalSets =
        completedLogs.fold<int>(0, (sum, l) => sum + l.sets.length);
    final totalVolume = completedLogs.fold<double>(
        0,
        (sum, l) =>
            sum + l.sets.fold<double>(0, (s, set) => s + set.load * set.reps));

    await db.insertHistorySession(HistorySessionsCompanion(
      id: Value(sessionId),
      workoutId: Value(workout.id),
      workoutName: Value(workout.name),
      workoutLetter: Value(workout.letter),
      colorValue: Value(workout.colorValue),
      date: Value(DateTime.now()),
      durationSeconds: Value(duration.inSeconds),
      totalVolume: Value(totalVolume),
      totalSets: Value(totalSets),
    ));

    final entries = <HistoryEntriesCompanion>[];
    for (final log in completedLogs) {
      for (final set in log.sets) {
        entries.add(HistoryEntriesCompanion(
          id: Value(_uuid.v4()),
          sessionId: Value(sessionId),
          exerciseId: Value(log.exerciseId),
          exerciseName: Value(log.exerciseName),
          setNumber: Value(set.setNumber),
          reps: Value(set.reps),
          load: Value(set.load),
        ));
      }
    }
    await db.insertHistoryEntries(entries);
  }
}

final lastEntryForExerciseProvider =
    FutureProvider.family<HistoryEntry?, String>((ref, exerciseId) {
  return ref.watch(databaseProvider).lastEntryForExercise(exerciseId);
});

final bestLoadForExerciseProvider =
    FutureProvider.family<double, String>((ref, exerciseId) {
  return ref.watch(databaseProvider).bestLoadForExercise(exerciseId);
});
