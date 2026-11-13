import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'cards_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _initials(String name) {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return (first + second).toUpperCase();
  }

  Future<void> _toggleBiometrics(BuildContext context, bool enabled) async {
    final ok = await AppScope.read(context).setBiometricEnabled(enabled);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo activar la biometría')),
      );
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir de tu cuenta?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      AppScope.read(context).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final student = state.student;
    final theme = Theme.of(context);

    if (student == null) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              child: Text(
                _initials(student.name),
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            student.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          Text(
            'Matrícula ${student.matricula}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SectionTitle('Datos académicos'),
          ListTile(
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(student.program),
            subtitle: Text('${student.semester}° semestre'),
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: Text(student.campus),
            subtitle: Text(state.config.name),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(student.email),
          ),
          const SectionTitle('Pagos'),
          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text('Mis tarjetas'),
            subtitle: Text(
              state.cards.isEmpty
                  ? 'Sin tarjetas guardadas'
                  : '${state.cards.length} guardada(s)',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const CardsScreen()),
            ),
          ),
          const SectionTitle('Seguridad'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint),
            title: const Text('Desbloquear con huella o Face ID'),
            subtitle: Text(
              state.biometricAvailable
                  ? 'La app se bloquea tras unos minutos sin uso'
                  : 'No disponible en este dispositivo',
            ),
            value: state.biometricEnabled,
            onChanged: state.biometricAvailable
                ? (v) => _toggleBiometrics(context, v)
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.lock_clock_outlined),
            title: const Text('Bloquear ahora'),
            subtitle: const Text('Para probar la pantalla de bloqueo'),
            onTap: state.lock,
          ),
          const SectionTitle('Ayuda'),
          ListTile(
            leading: const Icon(Icons.support_agent),
            title: const Text('Soporte de pagos'),
            subtitle: Text(state.config.supportEmail),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                foregroundColor: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Escuela: ${state.config.id} · v0.1.0 (demo)',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
