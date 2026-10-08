import 'package:drift/drift.dart' show Value;

import '../database/database.dart';
import 'exercise_seed_data.dart';
import 'muscle_categories_seed.dart';

class Seeder {
  final AppDatabase db;
  Seeder(this.db);

  Future<void> seedIfNeeded() async {
    for (var i = 0; i < muscleCategorySeeds.length; i++) {
      final c = muscleCategorySeeds[i];
      await db.upsertMuscleCategory(MuscleCategoriesCompanion(
        id: Value(c.id),
        name: Value(c.name),
        iconCodePoint: Value(c.icon.codePoint),
        position: Value(i),
      ));
    }

    // Upsert on every launch (not just on first install) so that library
    // updates shipped in later app versions reach users who already have
    // the database seeded. This is safe: insertOnConflictUpdate only
    // touches the columns listed below, so isFavorite (user data) is left
    // untouched on existing rows.
    for (final e in exerciseSeedData) {
      await db.upsertExercise(ExercisesCompanion(
        id: Value(e.id),
        name: Value(e.name),
        muscleGroup: Value(e.muscleGroup),
        equipment: Value(e.equipment),
        description: Value(e.description),
        executionSteps: Value(e.steps.join('\n')),
        commonMistakes: Value(e.commonMistakes.join('\n')),
        breathingTip: Value(e.breathingTip),
        executionTips: Value(e.executionTips),
        primaryMuscles: Value(e.primaryMuscles.join(', ')),
        secondaryMuscles: Value(e.secondaryMuscles.join(', ')),
        difficulty: Value(e.difficulty),
        animationPattern: Value(e.animationPattern),
        videoId: Value(e.videoId),
        isCustom: const Value(false),
      ));
    }
  }
}
