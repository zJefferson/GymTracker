import 'package:flutter/material.dart';

class MuscleCategorySeed {
  final String id;
  final String name;
  final IconData icon;
  const MuscleCategorySeed(this.id, this.name, this.icon);
}

const List<MuscleCategorySeed> muscleCategorySeeds = [
  MuscleCategorySeed('peito', 'Peito', Icons.accessibility_new),
  MuscleCategorySeed('costas', 'Costas', Icons.table_rows),
  MuscleCategorySeed('ombros', 'Ombros', Icons.sports_gymnastics),
  MuscleCategorySeed('biceps', 'Bíceps', Icons.fitness_center),
  MuscleCategorySeed('triceps', 'Tríceps', Icons.fitness_center),
  MuscleCategorySeed('pernas', 'Pernas', Icons.directions_walk),
  MuscleCategorySeed('gluteos', 'Glúteos', Icons.airline_seat_legroom_extra),
  MuscleCategorySeed('panturrilhas', 'Panturrilhas', Icons.directions_run),
  MuscleCategorySeed('abdomen', 'Abdômen', Icons.self_improvement),
  MuscleCategorySeed('cardio', 'Cardio', Icons.favorite),
];
