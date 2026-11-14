import 'models.dart';
import 'api_client.dart';

class AuthException implements Exception {
  const AuthException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Contrato con el backend escolar.
///
/// La app solo conoce esta interfaz. Hoy la implementa [MockSchoolApi];
/// cuando exista el backend real se escribe otra clase (por ejemplo
/// HttpSchoolApi) y se cambia en main.dart, sin tocar las pantallas.
abstract class SchoolApi {
  Future<Student> login({required String matricula, required String password});
  Future<void> logout();
  Future<List<Charge>> fetchCharges(String studentId);
  Future<List<Payment>> fetchPayments(String studentId);
  Future<List<Grade>> fetchGrades(String studentId);
}

/// Datos simulados en memoria. Se reinician al cerrar la app.
///
/// Devuelve siempre las mismas listas, así lo que se paga en la demo
/// sigue pagado al refrescar.
class MockSchoolApi implements SchoolApi {
  static const String demoPassword = 'demo1234';
  static const Duration _latency = Duration(milliseconds: 700);

  List<Charge>? _charges;
  List<Payment>? _payments;

  @override
  Future<Student> login({
    required String matricula,
    required String password,
  }) async {
    await Future<void>.delayed(_latency);
    if (matricula.trim().isEmpty || password != demoPassword) {
      throw const AuthException('Matrícula o contraseña incorrecta');
    }
    return Student(
      id: 'stu_${matricula.trim()}',
      matricula: matricula.trim(),
      name: 'Alumno Demo García',
      program: 'Ingeniería en Sistemas',
      semester: 5,
      email: 'alumno.demo@example.com',
      campus: 'Campus Central',
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<List<Charge>> fetchCharges(String studentId) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return _charges ??= [
      Charge(
        id: 'chg_3',
        concept: 'Colegiatura',
        period: 'Noviembre',
        amount: 4850,
        dueDate: DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 3)),
      ),
      Charge(
        id: 'chg_4',
        concept: 'Colegiatura',
        period: 'Diciembre',
        amount: 4850,
        dueDate:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 27)),
      ),
      Charge(
        id: 'chg_5',
        concept: 'Seguro estudiantil',
        period: 'Semestre actual',
        amount: 620,
        dueDate:
            DateTime(now.year, now.month, now.day).add(const Duration(days: 12)),
      ),
    ];
  }

  @override
  Future<List<Payment>> fetchPayments(String studentId) async {
    await Future<void>.delayed(_latency);
    final now = DateTime.now();
    return _payments ??= [
      Payment(
        id: 'pay_2',
        chargeId: 'chg_2',
        concept: 'Colegiatura · Octubre',
        amount: 4850,
        date: now.subtract(const Duration(days: 33)),
        method: 'Transferencia SPEI',
        gateway: 'SPEI',
        folio: 'F-000128',
      ),
      Payment(
        id: 'pay_1',
        chargeId: 'chg_1',
        concept: 'Colegiatura · Septiembre',
        amount: 4850,
        date: now.subtract(const Duration(days: 64)),
        method: 'Visa •••• 4242',
        gateway: 'Stripe',
        folio: 'F-000097',
      ),
    ];
  }

  @override
  Future<List<Grade>> fetchGrades(String studentId) async {
    await Future<void>.delayed(_latency);
    return const [
      Grade(subject: 'Bases de datos', credits: 8, score: 9.2),
      Grade(subject: 'Redes de computadoras', credits: 8, score: 8.5),
      Grade(subject: 'Ingeniería de software', credits: 6, score: 9.6),
      Grade(subject: 'Probabilidad y estadística', credits: 8, score: 7.8),
      Grade(subject: 'Inglés técnico', credits: 4, score: 9.0),
    ];
  }
}

class HttpSchoolApi implements SchoolApi {
  HttpSchoolApi(this.client);

  final ApiClient client;

  @override
  Future<Student> login({required String matricula, required String password}) async {
    try {
      final response = await client.post('/auth/login', {
        'matricula': matricula.trim(),
        'password': password,
      });
      await client.setToken(response['token'] as String);
      return _student(response['student'] as Map<String, dynamic>);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 422) {
        throw const AuthException('Matrícula o contraseña incorrecta');
      }
      rethrow;
    }
  }

  @override
  Future<List<Charge>> fetchCharges(String studentId) async => [];

  @override
  Future<List<Payment>> fetchPayments(String studentId) async {
    final response = await client.get('/payments');
    final items = response['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .where((item) => item['status'] == 'paid')
        .map((item) {
      final paidAt = DateTime.tryParse(item['paid_at']?.toString() ?? '') ??
          DateTime.tryParse(item['created_at']?.toString() ?? '') ??
          DateTime.now();
      final description = item['description']?.toString().trim() ?? '';
      return Payment(
        id: item['id'].toString(),
        chargeId: item['id'].toString(),
        concept: description.isEmpty ? 'Pago escolar' : description,
        amount: (item['amount_cents'] as num).toDouble() / 100,
        date: paidAt,
        method: _paymentMethodLabel(item['payment_method']?.toString()),
        gateway: _gatewayLabel(item['gateway']?.toString()),
        folio: item['folio']?.toString() ?? item['id'].toString(),
      );
    }).toList();
  }

  String _paymentMethodLabel(String? value) {
    if (value == null || value.isEmpty) {
      return 'Pago';
    }
    if (value == 'card') {
      return 'Tarjeta';
    }
    if (value == 'transfer' || value == 'spei') {
      return 'Transferencia SPEI';
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String? _gatewayLabel(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return switch (value.toLowerCase()) {
      'stripe' => 'Stripe',
      'spei' => 'SPEI',
      _ => '${value[0].toUpperCase()}${value.substring(1)}',
    };
  }

  @override
  Future<List<Grade>> fetchGrades(String studentId) async => [];

  @override
  Future<void> logout() async {
    try {
      await client.post('/auth/logout');
    } catch (_) {
    } finally {
      await client.clearToken();
    }
  }

  Student _student(Map<String, dynamic> item) => Student(
        id: item['id'].toString(),
        matricula: item['matricula']?.toString() ?? '',
        name: item['name']?.toString() ?? '',
        program: item['program']?.toString() ?? '',
        semester: (item['semester'] as num?)?.toInt() ?? 0,
        email: item['email']?.toString() ?? '',
        campus: item['campus']?.toString() ?? '',
      );
}
