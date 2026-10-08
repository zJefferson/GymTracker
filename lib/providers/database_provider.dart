import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import '../data/seed/seeder.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final seedProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await Seeder(db).seedIfNeeded();
});
