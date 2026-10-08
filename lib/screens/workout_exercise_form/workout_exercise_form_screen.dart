import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../data/database/database.dart';
import '../../data/seed/muscle_categories_seed.dart';
import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';

const _uuid = Uuid();
const _restOptions = [30, 45, 60, 90, 120, 180];

class WorkoutExerciseFormScreen extends ConsumerStatefulWidget {
  final String workoutId;
  final String? linkId;

  const WorkoutExerciseFormScreen(
      {super.key, required this.workoutId, this.linkId});

  @override
  ConsumerState<WorkoutExerciseFormScreen> createState() =>
      _WorkoutExerciseFormScreenState();
}

class _WorkoutExerciseFormScreenState
    extends ConsumerState<WorkoutExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _setsController = TextEditingController(text: '3');
  final _repsController = TextEditingController(text: '10');
  final _loadController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  int _restSeconds = 60;
  Exercise? _selectedExercise;
  bool _loading = true;
  int? _existingOrder;

  bool get _isEditing => widget.linkId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else {
      _loading = false;
    }
  }

  Future<void> _loadExisting() async {
    final db = ref.read(databaseProvider);
    final link = await db.getWorkoutExerciseLink(widget.linkId!);
    if (link == null || !mounted) return;
    final exercise = await db.getExercise(link.exerciseId);
    setState(() {
      _selectedExercise = exercise;
      _setsController.text = link.sets.toString();
      _repsController.text = link.reps.toString();
      _loadController.text = link.load.toString();
      _restSeconds = link.restSeconds;
      _notesController.text = link.notes;
      _existingOrder = link.sortOrder;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _loadController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickExercise() async {
    final picked = await Navigator.of(context).push<Exercise>(
      MaterialPageRoute(builder: (_) => const _ExercisePickerScreen()),
    );
    if (picked != null && mounted) {
      setState(() => _selectedExercise = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedExercise == null) return;
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(workoutRepositoryProvider);
    await repo.addOrUpdateExerciseInWorkout(
      linkId: widget.linkId ?? _uuid.v4(),
      workoutId: widget.workoutId,
      exerciseId: _selectedExercise!.id,
      sets: int.parse(_setsController.text),
      reps: int.parse(_repsController.text),
      load: double.parse(_loadController.text.replaceAll(',', '.')),
      restSeconds: _restSeconds,
      notes: _notesController.text.trim(),
      order: _existingOrder,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Editar exercício' : 'Adicionar exercício')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            if (!_isEditing) ...[
              Text('Exercício', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickExercise,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.fitness_center,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedExercise?.name ??
                              'Selecionar da biblioteca',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
            ] else ...[
              Text(_selectedExercise?.name ?? '',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 28),
            ],
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Séries'),
                    validator: _requiredIntValidator,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Repetições'),
                    validator: _requiredIntValidator,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loadController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Carga (kg)'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Obrigatório';
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
                  return 'Valor inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Descanso entre séries',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _restOptions.map((s) {
                final selected = s == _restSeconds;
                return ChoiceChip(
                  label: Text('${s}s'),
                  selected: selected,
                  onSelected: (_) => setState(() => _restSeconds = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observações',
                hintText: 'Ex: Descer lentamente.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: _selectedExercise == null ? null : _save,
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  String? _requiredIntValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obrigatório';
    if (int.tryParse(v) == null) return 'Valor inválido';
    return null;
  }
}

class _ExercisePickerScreen extends ConsumerStatefulWidget {
  const _ExercisePickerScreen();

  @override
  ConsumerState<_ExercisePickerScreen> createState() =>
      _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<_ExercisePickerScreen> {
  String _query = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(exercisesStreamProvider);
    final exercises = exercisesAsync.value ?? const <Exercise>[];
    final query = _query.trim().toLowerCase();

    final filtered = exercises.where((e) {
      if (_selectedCategory != null && e.muscleGroup != _selectedCategory) {
        return false;
      }
      if (query.isNotEmpty &&
          !e.name.toLowerCase().contains(query) &&
          !e.muscleGroup.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    final grouped = <String, List<Exercise>>{};
    for (final e in filtered) {
      grouped.putIfAbsent(e.muscleGroup, () => []).add(e);
    }
    for (final list in grouped.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    final orderedCategoryIds = [
      ...muscleCategorySeeds.map((c) => c.id),
      ...grouped.keys.where(
          (id) => !muscleCategorySeeds.any((c) => c.id == id)),
    ].where(grouped.containsKey).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar exercício'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar exercício...',
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('Todos os grupos'),
                    selected: _selectedCategory == null,
                    onSelected: (_) =>
                        setState(() => _selectedCategory = null),
                  ),
                ),
                ...muscleCategorySeeds.map((c) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c.name),
                        selected: _selectedCategory == c.id,
                        onSelected: (_) => setState(() =>
                            _selectedCategory =
                                _selectedCategory == c.id ? null : c.id),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Nenhum exercício encontrado.'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: orderedCategoryIds.length,
                    itemBuilder: (context, sectionIndex) {
                      final categoryId = orderedCategoryIds[sectionIndex];
                      final categoryExercises = grouped[categoryId]!;
                      final categoryName = muscleCategorySeeds
                          .firstWhere(
                            (c) => c.id == categoryId,
                            orElse: () => MuscleCategorySeed(
                                categoryId, categoryId, Icons.fitness_center),
                          )
                          .name;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                            child: Text(
                              categoryName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          ...categoryExercises.map((e) => ListTile(
                                title: Text(e.name),
                                subtitle: Text(e.muscleGroup),
                                onTap: () => Navigator.of(context).pop(e),
                              )),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
