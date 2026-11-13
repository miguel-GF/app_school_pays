import 'package:flutter/material.dart';

import '../state/app_scope.dart';
import '../widgets/common.dart';

/// Se muestra encima de todo cuando la app se bloquea por inactividad.
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _unlock() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await AppScope.read(context).unlockWithBiometrics();
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (!ok) {
        _error = 'No se pudo verificar tu identidad';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SchoolLogo(config: state.config),
                const SizedBox(height: 24),
                Text(
                  'Sesión bloqueada',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  state.biometricEnabled
                      ? 'Por seguridad bloqueamos la app tras un tiempo sin uso.'
                      : 'Por seguridad bloqueamos la app tras un tiempo sin uso. '
                          'Vuelve a iniciar sesión, o activa la huella en tu perfil '
                          'para desbloquear más rápido.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (state.biometricEnabled)
                  FilledButton.icon(
                    onPressed: _busy ? null : _unlock,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.fingerprint),
                    label: const Text('Desbloquear con huella o Face ID'),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : state.logout,
                  child: const Text('Iniciar sesión con contraseña'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
