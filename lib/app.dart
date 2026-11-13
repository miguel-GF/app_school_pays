import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'state/app_scope.dart';
import 'state/app_state.dart';

/// Tiempo en segundo plano tras el cual la app se bloquea.
const Duration kBackgroundLockAfter = Duration(minutes: 2);

/// Tiempo sin tocar la pantalla tras el cual la app se bloquea.
const Duration kIdleLockAfter = Duration(minutes: 5);

class SchoolApp extends StatefulWidget {
  const SchoolApp({super.key, required this.state});

  final AppState state;

  @override
  State<SchoolApp> createState() => _SchoolAppState();
}

class _SchoolAppState extends State<SchoolApp> with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();
  Timer? _idleTimer;
  DateTime? _backgroundSince;
  bool _wasLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_onStateChanged);
    _idleTimer?.cancel();
    super.dispose();
  }

  void _onStateChanged() {
    final loggedIn = widget.state.isLoggedIn;
    if (loggedIn && !_wasLoggedIn) {
      _resetIdleTimer();
    }
    if (!loggedIn && _wasLoggedIn) {
      _idleTimer?.cancel();
      // Al cerrar sesión se descartan las pantallas abiertas.
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    _wasLoggedIn = loggedIn;
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    if (!widget.state.isLoggedIn) {
      return;
    }
    _idleTimer = Timer(kIdleLockAfter, widget.state.lock);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundSince ??= DateTime.now();
      case AppLifecycleState.resumed:
        final since = _backgroundSince;
        _backgroundSince = null;
        if (since != null &&
            DateTime.now().difference(since) >= kBackgroundLockAfter) {
          widget.state.lock();
        }
        _resetIdleTimer();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: widget.state.config.seedColor,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _resetIdleTimer(),
        child: MaterialApp(
          navigatorKey: _navigatorKey,
          title: widget.state.config.shortName,
          debugShowCheckedModeBanner: false,
          theme: _theme(Brightness.light),
          darkTheme: _theme(Brightness.dark),
          home: const _Root(),
          // La pantalla de bloqueo cubre todo, incluso pantallas abiertas.
          builder: (context, child) {
            final locked = AppScope.of(context).locked;
            return Stack(
              children: [
                child ?? const SizedBox.shrink(),
                if (locked) const Positioned.fill(child: LockScreen()),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return state.isLoggedIn ? const HomeShell() : const LoginScreen();
  }
}
