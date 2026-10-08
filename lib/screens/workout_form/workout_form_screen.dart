import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../theme/app_theme.dart';

const _uuid = Uuid();

class WorkoutFormScreen extends ConsumerStatefulWidget {
  final String? workoutId;
  const WorkoutFormScreen({super.key, this.workoutId});

  @override
  ConsumerState<WorkoutFormScreen> createState() => _WorkoutFormScreenState();
}

class _WorkoutFormScreenState extends ConsumerState<WorkoutFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _letterController = TextEditingController();
  Color _selectedColor = workoutColorPalette.first;
  IconData _selectedIcon = workoutIconPalette.first;
  bool _loaded = false;
  int? _existingPosition;

  bool get _isEditing => widget.workoutId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _loadExisting();
    } else {
      _loaded = true;
      _prefillNextLetter();
    }
  }

  Future<void> _prefillNextLetter() async {
    final db = ref.read(databaseProvider);
    final workouts = await db.watchWorkouts().first;
    const letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    final used = workouts.map((w) => w.letter).toSet();
    final next = letters.firstWhere((l) => !used.contains(l),
        orElse: () => letters.last);
    if (mounted) setState(() => _letterController.text = next);
  }

  Future<void> _loadExisting() async {
    final db = ref.read(databaseProvider);
    final workout = await db.getWorkout(widget.workoutId!);
    if (workout != null && mounted) {
      _nameController.text = workout.name;
      _letterController.text = workout.letter;
      _existingPosition = workout.position;
      setState(() {
        _selectedColor = Color(workout.colorValue);
        // ignore: non_const_argument_for_const_parameter
        _selectedIcon = IconData(workout.iconCodePoint, fontFamily: 'MaterialIcons');
        _loaded = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _letterController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final repo = ref.read(workoutRepositoryProvider);
    await repo.saveWorkout(
      id: widget.workoutId ?? _uuid.v4(),
      name: _nameController.text.trim(),
      letter: _letterController.text.trim().toUpperCase(),
      colorValue: _selectedColor.toARGB32(),
      iconCodePoint: _selectedIcon.codePoint,
      position: _existingPosition,
    );
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
          title: Text(_isEditing ? 'Editar treino' : 'Novo treino')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 90,
                  child: TextFormField(
                    controller: _letterController,
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                        labelText: 'Letra', counterText: ''),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Nome do treino',
                        hintText: 'Ex: Peito e Tríceps'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obrigatório' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Cor', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: workoutColorPalette.map((color) {
                final selected = color.toARGB32() == _selectedColor.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3)
                          : null,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            Text('Ícone', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: workoutIconPalette.map((icon) {
                final selected = icon.codePoint == _selectedIcon.codePoint;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIcon = icon),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: selected
                          ? _selectedColor.withValues(alpha: 0.25)
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                      border: selected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Icon(icon,
                        color: selected
                            ? _selectedColor
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 36),
            FilledButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Salvar alterações' : 'Criar treino'),
            ),
          ],
        ),
      ),
    );
  }
}
