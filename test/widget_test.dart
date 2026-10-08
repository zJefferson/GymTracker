import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:gymtracker/data/database/database.dart';
import 'package:gymtracker/main.dart';
import 'package:gymtracker/providers/database_provider.dart';
import 'package:gymtracker/providers/settings_providers.dart';

void main() {
  testWidgets('App starts and shows the home screen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWith(
            (ref) => AppDatabase.forTesting(NativeDatabase.memory()),
          ),
        ],
        child: const GymTrackerApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('GymTracker'), findsOneWidget);

    // Unmount explicitly so Drift's internal stream-closing timer is
    // scheduled and flushed before the test framework's final invariant
    // check (it otherwise fires during automatic teardown, too late).
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(Duration.zero);
  });
}
