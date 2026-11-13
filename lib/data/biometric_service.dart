/// Contrato para huella / Face ID.
///
/// En producción se implementa con el paquete `local_auth`.
abstract class BiometricService {
  Future<bool> isAvailable();
  Future<bool> authenticate({required String reason});
}

/// Simulación: siempre disponible y siempre aprueba tras una pausa breve.
class MockBiometricService implements BiometricService {
  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<bool> authenticate({required String reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    return true;
  }
}
