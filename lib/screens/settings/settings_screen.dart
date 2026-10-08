import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final weightUnit = ref.watch(weightUnitProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          const _SectionHeader('Aparência'),
          RadioListTile<ThemeMode>(
            title: const Text('Escuro'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Claro'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Automático (sistema)'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (v) =>
                ref.read(themeModeProvider.notifier).setThemeMode(v!),
          ),
          const Divider(height: 32),
          const _SectionHeader('Unidade de carga'),
          RadioListTile<WeightUnit>(
            title: const Text('Quilogramas (kg)'),
            value: WeightUnit.kg,
            groupValue: weightUnit,
            onChanged: (v) => ref.read(weightUnitProvider.notifier).setUnit(v!),
          ),
          RadioListTile<WeightUnit>(
            title: const Text('Libras (lb)'),
            value: WeightUnit.lb,
            groupValue: weightUnit,
            onChanged: (v) => ref.read(weightUnitProvider.notifier).setUnit(v!),
          ),
          const Divider(height: 32),
          const _SectionHeader('Sobre'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('GymTracker'),
            subtitle: Text('Versão 1.0.0 · MVP'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
