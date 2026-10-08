import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/history/history_screen.dart';
import '../screens/library/exercise_detail_screen.dart';
import '../screens/library/exercise_library_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/session/workout_session_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/workout_detail/workout_detail_screen.dart';
import '../screens/workout_exercise_form/workout_exercise_form_screen.dart';
import '../screens/workout_form/workout_form_screen.dart';
import '../widgets/app_scaffold.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                path: 'workout/new',
                builder: (context, state) => const WorkoutFormScreen(),
              ),
              GoRoute(
                path: 'workout/:id',
                builder: (context, state) => WorkoutDetailScreen(
                  workoutId: state.pathParameters['id']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => WorkoutFormScreen(
                      workoutId: state.pathParameters['id'],
                    ),
                  ),
                  GoRoute(
                    path: 'exercise/new',
                    builder: (context, state) => WorkoutExerciseFormScreen(
                      workoutId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'exercise/:linkId/edit',
                    builder: (context, state) => WorkoutExerciseFormScreen(
                      workoutId: state.pathParameters['id']!,
                      linkId: state.pathParameters['linkId'],
                    ),
                  ),
                  GoRoute(
                    path: 'session',
                    builder: (context, state) => WorkoutSessionScreen(
                      workoutId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/library',
            builder: (context, state) => const ExerciseLibraryScreen(),
            routes: [
              GoRoute(
                path: ':exerciseId',
                builder: (context, state) => ExerciseDetailScreen(
                  exerciseId: state.pathParameters['exerciseId']!,
                ),
              ),
            ],
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/history',
            builder: (context, state) => const HistoryScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ]),
      ],
    ),
  ],
);
