import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:uuid/uuid.dart';

import 'api_client.dart';
import 'models.dart';

class PaymentDeclined implements Exception {
  const PaymentDeclined(this.message);
  final String message;

  @override
  String toString() => message;
}

class ChargeResult {
  const ChargeResult({required this.folio, required this.date});
  final String folio;
  final DateTime date;
}

/// Contrato de la pasarela de pagos.
///
/// La interfaz usa [CardField] de Stripe (el campo nativo y seguro) como
/// fuente de los datos de tarjeta. Ningún PAN/CVC pasa por Dart ni por el API
/// escolar: Stripe los captura y solo devuelve el método de pago tokenizado.
abstract class PaymentGateway {
  /// Deja lista la pasarela (llave publicable y configuración) antes de
  /// mostrar un formulario de tarjeta.
  Future<void> prepare();

  Future<int> fetchTestAmountCents();

  Future<List<SavedCard>> fetchCards();

  /// Guarda la tarjeta capturada en el [CardField] visible.
  Future<SavedCard> tokenizeCard({bool makeDefault = false});

  Future<void> removeCard(String id);

  /// Cobra con la tarjeta guardada [paymentMethodId]. Si se omite, usa el
  /// [CardField] visible para cobrar una tarjeta nueva.
  Future<ChargeResult> chargeCard({
    required double amount,
    required String description,
    String? paymentMethodId,
  });
}

class StripePaymentGateway implements PaymentGateway {
  StripePaymentGateway(this.client);

  final ApiClient client;
  static final _uuid = Uuid();
  bool _configured = false;
  Map<String, dynamic>? _paymentConfig;

  @override
  Future<void> prepare() => _configure();

  @override
  Future<int> fetchTestAmountCents() async {
    _paymentConfig ??= await client.get('/payment-config');
    return (_paymentConfig!['amount_cents'] as num).toInt();
  }

  @override
  Future<List<SavedCard>> fetchCards() async {
    final response = await client.get('/payment-methods');
    final data = response['data'] as List<dynamic>? ?? [];
    return data.whereType<Map<String, dynamic>>().map((item) {
      return SavedCard(
        id: item['id'].toString(),
        brand: _titleCase(item['brand']?.toString() ?? 'Tarjeta'),
        last4: item['last4']?.toString() ?? '',
        expMonth: (item['exp_month'] as num?)?.toInt() ?? 1,
        expYear: (item['exp_year'] as num?)?.toInt() ?? DateTime.now().year,
        holder: '',
        token: item['id'].toString(),
      );
    }).toList();
  }

  @override
  Future<SavedCard> tokenizeCard({bool makeDefault = false}) async {
    await _configure();
    final setup = await client.post('/payment-methods/setup-intent');
    await Stripe.instance.confirmSetupIntent(
      paymentIntentClientSecret: setup['setup_intent_client_secret'] as String,
      params: PaymentMethodParams.card(
        paymentMethodData: PaymentMethodData(),
      ),
    );
    final cards = await fetchCards();
    if (cards.isEmpty) {
      throw const PaymentDeclined('Stripe no devolvió la tarjeta guardada.');
    }
    return cards.first;
  }

  @override
  Future<void> removeCard(String id) async {
    await client.delete('/payment-methods/$id');
  }

  @override
  Future<ChargeResult> chargeCard({
    required double amount,
    required String description,
    String? paymentMethodId,
  }) async {
    await _configure();
    final requestId = _uuid.v4();
    final payment = await client.post('/payments', {'request_id': requestId});
    final clientSecret = payment['client_secret']?.toString();
    if (clientSecret == null || clientSecret.isEmpty) {
      throw const PaymentDeclined('El servidor no pudo iniciar el pago.');
    }

    final params = paymentMethodId == null
        ? PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          )
        : PaymentMethodParams.cardFromMethodId(
            paymentMethodData: PaymentMethodDataCardFromMethod(
              paymentMethodId: paymentMethodId,
            ),
          );
    await Stripe.instance.confirmPayment(
      paymentIntentClientSecret: clientSecret,
      data: params,
    );

    final confirmed = await client.post('/payments/${payment['folio']}/confirm');
    if (confirmed['status'] != 'paid') {
      throw const PaymentDeclined('El pago sigue pendiente de confirmación.');
    }
    return ChargeResult(
      folio: confirmed['folio']?.toString() ?? payment['folio'].toString(),
      date: DateTime.tryParse(confirmed['paid_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Future<void> _configure() async {
    if (_configured) {
      return;
    }
    final config = _paymentConfig ??= await client.get('/payment-config');
    if (config['gateway'] != 'stripe') {
      throw const PaymentDeclined('La pasarela de pago de esta escuela no está disponible en la app.');
    }
    final key = config['publishable_key']?.toString() ?? '';
    if (key.isEmpty) {
      throw const PaymentDeclined('Stripe no está configurado en el servidor de esta escuela.');
    }
    Stripe.publishableKey = key;
    await Stripe.instance.applySettings();
    _configured = true;
  }

  String _titleCase(String value) => value.isEmpty
      ? 'Tarjeta'
      : '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

/// Traduce los errores de Stripe a mensajes claros para el alumno.
String friendlyPaymentError(Object error) {
  if (error is StripeException) {
    final stripe = error.error;
    return switch (stripe.stripeErrorCode) {
      'card_declined' => 'Tu banco rechazó el pago. Prueba con otra tarjeta.',
      'expired_card' => 'La tarjeta está vencida. Usa otra tarjeta.',
      'incorrect_cvc' => 'El código de seguridad no es correcto.',
      'incorrect_number' => 'El número de tarjeta no es válido.',
      'processing_error' => 'No se pudo procesar el pago. Inténtalo de nuevo.',
      _ => stripe.localizedMessage ??
          stripe.message ??
          'No se pudo procesar el pago.',
    };
  }
  if (error is PaymentDeclined) {
    return error.message;
  }
  return error.toString();
}

class MockPaymentGateway implements PaymentGateway {
  int _sequence = 200;
  final List<SavedCard> _cards = [];

  @override
  Future<void> prepare() async {}

  @override
  Future<int> fetchTestAmountCents() async => 1000;

  @override
  Future<List<SavedCard>> fetchCards() async => List.of(_cards);

  @override
  Future<SavedCard> tokenizeCard({bool makeDefault = false}) async {
    throw const PaymentDeclined('La pasarela de prueba no está habilitada.');
  }

  @override
  Future<void> removeCard(String id) async {
    _cards.removeWhere((card) => card.id == id);
  }

  @override
  Future<ChargeResult> chargeCard({
    required double amount,
    required String description,
    String? paymentMethodId,
  }) async {
    _sequence++;
    return ChargeResult(
      folio: 'F-${_sequence.toString().padLeft(6, '0')}',
      date: DateTime.now(),
    );
  }
}
