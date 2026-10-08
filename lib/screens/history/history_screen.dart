import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database/database.dart';
import '../../providers/database_provider.dart';
import '../../providers/history_providers.dart';

final _dateFormat = DateFormat('dd/MM/yyyy · HH:mm');

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.history,
                        size: 56,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5)),
                    const SizedBox(height: 16),
                    const Text('Nenhum treino registrado ainda.'),
                    const SizedBox(height: 4),
                    Text(
                      'Finalize um treino no modo treino para vê-lo aqui.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return _HistorySummary(sessions: sessions);
        },
      ),
    );
  }
}

class _HistorySummary extends StatelessWidget {
  final List<HistorySession> sessions;
  const _HistorySummary({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final totalVolume = sessions.fold<double>(0, (s, e) => s + e.totalVolume);
    final totalDuration =
        sessions.fold<int>(0, (s, e) => s + e.durationSeconds);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.event_available,
                label: 'Treinos',
                value: '${sessions.length}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.scale,
                label: 'Volume total',
                value: '${totalVolume.toStringAsFixed(0)} kg',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                icon: Icons.timer,
                label: 'Tempo total',
                value: '${(totalDuration / 60).round()} min',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ...sessions.map((s) => _SessionCard(session: s)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatTile(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _SessionCard extends ConsumerWidget {
  final HistorySession session;
  const _SessionCard({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Color(session.colorValue);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          foregroundColor: color,
          child: Text(session.workoutLetter),
        ),
        title: Text(session.workoutName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(_dateFormat.format(session.date)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${session.totalVolume.toStringAsFixed(0)} kg',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${(session.durationSeconds / 60).round()} min',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        children: [
          FutureBuilder<List<HistoryEntry>>(
            future:
                ref.read(databaseProvider).historyEntriesForSession(session.id),
            builder: (context, snapshot) {
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Sem detalhes de séries.'),
                );
              }
              final byExercise = <String, List<HistoryEntry>>{};
              for (final e in entries) {
                byExercise.putIfAbsent(e.exerciseName, () => []).add(e);
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: byExercise.entries.map((entry) {
                    final sets = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.key,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            sets
                                .map((s) =>
                                    '${s.reps}x${s.load.toStringAsFixed(s.load % 1 == 0 ? 0 : 1)}kg')
                                .join(' · '),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
