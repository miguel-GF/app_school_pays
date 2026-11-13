import 'package:flutter/foundation.dart';

import '../config/school_config.dart';
import '../core/card_utils.dart';
import '../data/biometric_service.dart';
import '../data/models.dart';
import '../data/payment_gateway.dart';
import '../data/school_api.dart';

/// Estado global de la sesión. Las pantallas lo leen con AppScope.
class AppState extends ChangeNotifier {
  AppState({
    required this.config,
    required this.api,
    required this.gateway,
    required this.biometrics,
  });

  final SchoolConfig config;
  final SchoolApi api;
  final PaymentGateway gateway;
  final BiometricService biometrics;

  Student? student;
  List<Charge> charges = [];
  List<Payment> payments = [];
  List<Grade> grades = [];
  final List<SavedCard> cards = [];
  String? defaultCardId;

  bool loading = false;
  bool locked = false;
  bool biometricAvailable = false;
  bool biometricEnabled = false;
  int testAmountCents = 1000;

  int _folioSequence = 500;

  bool get isLoggedIn => student != null;

  List<Charge> get pendingCharges {
    final list = charges.where((c) => !c.paid).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  double get balance =>
      pendingCharges.fold<double>(0, (sum, c) => sum + c.amount);

  Charge get testPayment => Charge(
        id: 'test-payment',
        concept: 'Pago de prueba',
        period: 'Demo',
        amount: testAmountCents / 100,
        dueDate: DateTime.now(),
      );

  SavedCard? get defaultCard {
    for (final card in cards) {
      if (card.id == defaultCardId) {
        return card;
      }
    }
    return cards.isEmpty ? null : cards.first;
  }

  // ---------- Sesión ----------

  Future<void> login(String matricula, String password) async {
    student = await api.login(matricula: matricula, password: password);
    biometricAvailable = await biometrics.isAvailable();
    locked = false;
    try {
      testAmountCents = await gateway.fetchTestAmountCents();
    } catch (_) {
      testAmountCents = 1000;
    }
    cards
      ..clear()
      ..addAll(await gateway.fetchCards());
    defaultCardId = cards.isEmpty ? null : cards.first.id;
    notifyListeners();
    await refresh();
  }

  Future<void> logout() async {
    await api.logout();
    student = null;
    charges = [];
    payments = [];
    grades = [];
    cards.clear();
    defaultCardId = null;
    locked = false;
    biometricEnabled = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    final current = student;
    if (current == null) {
      return;
    }
    loading = true;
    notifyListeners();
    try {
      final chargesFuture = api.fetchCharges(current.id);
      final paymentsFuture = api.fetchPayments(current.id);
      final gradesFuture = api.fetchGrades(current.id);
      charges = await chargesFuture;
      payments = await paymentsFuture;
      grades = await gradesFuture;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  // ---------- Bloqueo por inactividad ----------

  void lock() {
    if (isLoggedIn && !locked) {
      locked = true;
      notifyListeners();
    }
  }

  Future<bool> unlockWithBiometrics() async {
    final ok = await biometrics.authenticate(
      reason: 'Confirma tu identidad para continuar',
    );
    if (ok) {
      locked = false;
      notifyListeners();
    }
    return ok;
  }

  /// Activar biometría pide autenticarse primero.
  Future<bool> setBiometricEnabled(bool enabled) async {
    if (enabled) {
      final ok = await biometrics.authenticate(
        reason: 'Activa el acceso con huella o Face ID',
      );
      if (!ok) {
        return false;
      }
    }
    biometricEnabled = enabled;
    notifyListeners();
    return true;
  }

  // ---------- Tarjetas ----------

  Future<SavedCard> addCard({bool makeDefault = false}) async {
    final card = await gateway.tokenizeCard(makeDefault: makeDefault);
    cards
      ..clear()
      ..addAll(await gateway.fetchCards());
    final savedCard = cards.firstWhere((item) => item.id == card.id, orElse: () => card);
    if (makeDefault || cards.length == 1) {
      defaultCardId = savedCard.id;
    }
    notifyListeners();
    return savedCard;
  }

  Future<void> removeCard(String id) async {
    await gateway.removeCard(id);
    cards.removeWhere((c) => c.id == id);
    if (defaultCardId == id) {
      defaultCardId = cards.isEmpty ? null : cards.first.id;
    }
    notifyListeners();
  }

  void setDefaultCard(String id) {
    defaultCardId = id;
    notifyListeners();
  }

  // ---------- Pagos ----------

  Future<Payment> payWithCard(Charge charge) async {
    final result = await gateway.chargeCard(
      amount: charge.amount,
      description: '${charge.concept} · ${charge.period}',
    );
    return _registerPayment(
      charge,
      method: 'Tarjeta',
      folio: result.folio,
      date: result.date,
    );
  }

  TransferInstructions transferInstructions(Charge charge) {
    return TransferInstructions(
      beneficiary: config.name,
      bank: config.bankName,
      clabe: config.demoClabe,
      reference: studentReference(student?.matricula ?? ''),
      concept: '${student?.matricula ?? ''} ${charge.period}'.trim(),
      amount: charge.amount,
    );
  }

  /// En producción esto ocurre solo: la pasarela avisa al backend por
  /// webhook cuando llega la transferencia. En la demo se simula.
  Payment simulateTransferArrival(Charge charge) {
    _folioSequence++;
    return _registerPayment(
      charge,
      method: 'Transferencia SPEI',
      folio: 'F-${_folioSequence.toString().padLeft(6, '0')}',
      date: DateTime.now(),
    );
  }

  Payment _registerPayment(
    Charge charge, {
    required String method,
    required String folio,
    required DateTime date,
  }) {
    charge.paid = true;
    final payment = Payment(
      id: 'pay_${date.microsecondsSinceEpoch}',
      chargeId: charge.id,
      concept: '${charge.concept} · ${charge.period}',
      amount: charge.amount,
      date: date,
      method: method,
      folio: folio,
    );
    // Se inserta en la misma lista que entregó la API para que la demo
    // conserve el pago al refrescar. Con backend real, el pago lo registra
    // el servidor y aquí solo se vuelve a consultar.
    payments.insert(0, payment);
    notifyListeners();
    return payment;
  }
}

/// Referencia numérica de 7 dígitos (campo "Referencia" de SPEI):
/// 6 dígitos de la matrícula + 1 dígito verificador.
String studentReference(String matricula) {
  var digits = onlyDigits(matricula);
  if (digits.isEmpty) {
    digits = '0';
  }
  if (digits.length > 6) {
    digits = digits.substring(digits.length - 6);
  }
  final base = digits.padLeft(6, '0');
  var sum = 0;
  for (var i = 0; i < base.length; i++) {
    final d = int.parse(base[i]);
    sum += d * (i.isEven ? 3 : 1);
  }
  final check = (10 - sum % 10) % 10;
  return '$base$check';
}
