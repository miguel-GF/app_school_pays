import 'package:flutter/widgets.dart';

import 'app_state.dart';

/// Hace disponible [AppState] a todo el árbol y reconstruye
/// las pantallas cuando cambia.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  /// Lee el estado y se suscribe a cambios (usar en build).
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol');
    return scope!.notifier!;
  }

  /// Lee el estado sin suscribirse (usar en callbacks).
  static AppState read(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope no encontrado en el árbol');
    return scope!.notifier!;
  }
}
