import 'package:drift/drift.dart';

enum EquipmentType { machine, freeWeight, barbell, dumbbell, cable, bodyweight, other }

enum Difficulty { beginner, intermediate, advanced }

class Workouts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();
  TextColumn get letter => text().withLength(min: 1, max: 2)();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class MuscleCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get muscleGroup => text()();
  TextColumn get equipment => textEnum<EquipmentType>()();
  TextColumn get description => text().withDefault(const Constant(''))();
  TextColumn get executionSteps => text().withDefault(const Constant(''))();
  TextColumn get commonMistakes => text().withDefault(const Constant(''))();
  TextColumn get breathingTip => text().withDefault(const Constant(''))();
  TextColumn get executionTips => text().withDefault(const Constant(''))();
  TextColumn get primaryMuscles => text().withDefault(const Constant(''))();
  TextColumn get secondaryMuscles => text().withDefault(const Constant(''))();
  TextColumn get difficulty =>
      textEnum<Difficulty>().withDefault(const Constant('intermediate'))();
  TextColumn get imageAsset => text().nullable()();
  TextColumn get animationPattern =>
      text().withDefault(const Constant('generic'))();
  TextColumn get videoId => text().nullable()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutExercises extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId =>
      text().references(Workouts, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get sets => integer().withDefault(const Constant(3))();
  IntColumn get reps => integer().withDefault(const Constant(10))();
  RealColumn get load => real().withDefault(const Constant(0))();
  IntColumn get restSeconds => integer().withDefault(const Constant(60))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class HistorySessions extends Table {
  TextColumn get id => text()();
  TextColumn get workoutId => text().nullable()();
  TextColumn get workoutName => text()();
  TextColumn get workoutLetter => text()();
  IntColumn get colorValue => integer().withDefault(const Constant(0xFF2196F3))();
  DateTimeColumn get date => dateTime()();
  IntColumn get durationSeconds => integer()();
  RealColumn get totalVolume => real()();
  IntColumn get totalSets => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class HistoryEntries extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(HistorySessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text()();
  TextColumn get exerciseName => text()();
  IntColumn get setNumber => integer()();
  IntColumn get reps => integer()();
  RealColumn get load => real()();

  @override
  Set<Column> get primaryKey => {id};
}
