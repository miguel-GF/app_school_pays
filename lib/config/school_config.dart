import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;

/// Configuración de una escuela (un "flavor").
///
/// La escuela se elige al compilar:
///   flutter run --flavor norte
///   flutter run --dart-define=SCHOOL=valle   (sin flavors nativos)
///
/// Para agregar una escuela nueva basta con añadir una entrada a [all].
class SchoolConfig {
  const SchoolConfig({
    required this.id,
    required this.name,
    required this.shortName,
    required this.seedColor,
    required this.icon,
    required this.apiBaseUrl,
    required this.supportEmail,
    required this.bankName,
    required this.demoClabe,
  });

  /// Identificador local de la escuela, reflejado en el flavor compilado.
  final String id;
  final String name;
  final String shortName;

  /// Color base; de aquí se genera toda la paleta de la app.
  final Color seedColor;

  /// Ícono usado como logo provisional. Cámbialo por un asset por escuela.
  final IconData icon;

  /// URL del API desplegado para esta escuela; nunca incluye credenciales.
  final String apiBaseUrl;
  final String supportEmail;

  /// Datos de ejemplo para la pantalla de transferencia.
  final String bankName;
  final String demoClabe;

  /// Prioridad: --dart-define=SCHOOL, luego el flavor nativo
  /// (--flavor norte), y por último la primera escuela de la lista.
  static String get _selected {
    const fromDefine = String.fromEnvironment('SCHOOL');
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return appFlavor ?? 'norte';
  }

  static const Map<String, SchoolConfig> all = {
    'norte': SchoolConfig(
      id: 'norte',
      name: 'Universidad Demo Norte',
      shortName: 'UD Norte',
      seedColor: Color(0xFF1E3A8A),
      icon: Icons.school,
      apiBaseUrl: String.fromEnvironment('NORTE_API_URL'),
      supportEmail: 'pagos@norte.example.com',
      bankName: 'Banco de ejemplo',
      demoClabe: '000000000000000001',
    ),
    'valle': SchoolConfig(
      id: 'valle',
      name: 'Instituto Demo Valle',
      shortName: 'ID Valle',
      seedColor: Color(0xFF0F766E),
      icon: Icons.account_balance,
      apiBaseUrl: String.fromEnvironment('VALLE_API_URL'),
      supportEmail: 'caja@valle.example.com',
      bankName: 'Banco de ejemplo',
      demoClabe: '000000000000000002',
    ),
  };

  static SchoolConfig get current => all[_selected] ?? all.values.first;
}
