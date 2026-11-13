import 'package:app_escolar/core/card_utils.dart';
import 'package:app_escolar/core/format.dart';
import 'package:app_escolar/data/models.dart';
import 'package:app_escolar/screens/grades_screen.dart';
import 'package:app_escolar/state/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('tarjetas', () {
    test('Luhn acepta tarjetas de prueba válidas', () {
      expect(luhnValid('4242 4242 4242 4242'), isTrue);
      expect(luhnValid('4000 0000 0000 0002'), isTrue);
      expect(luhnValid('5555 5555 5555 4444'), isTrue);
    });

    test('Luhn rechaza números inválidos', () {
      expect(luhnValid('4242 4242 4242 4241'), isFalse);
      expect(luhnValid('1234'), isFalse);
    });

    test('detecta la marca', () {
      expect(detectBrand('4242'), 'Visa');
      expect(detectBrand('5555'), 'Mastercard');
      expect(detectBrand('2223'), 'Mastercard');
      expect(detectBrand('3782'), 'American Express');
    });

    test('valida vigencia', () {
      final now = DateTime(2026, 11, 11);
      expect(validateExpiry('12/29', now), isNull);
      expect(validateExpiry('11/26', now), isNull);
      expect(validateExpiry('10/26', now), isNotNull);
      expect(validateExpiry('13/29', now), isNotNull);
      expect(validateExpiry('1/2', now), isNotNull);
    });
  });

  group('formato', () {
    test('dinero', () {
      expect(formatMoney(2000), r'$2,000.00');
      expect(formatMoney(4850.5), r'$4,850.50');
      expect(formatMoney(1234567.891), r'$1,234,567.89');
      expect(formatMoney(0), r'$0.00');
    });

    test('fecha', () {
      expect(formatDate(DateTime(2026, 11, 5)), '5 nov 2026');
    });
  });

  group('referencia SPEI', () {
    test('siempre tiene 7 dígitos', () {
      expect(studentReference('A0123456'), hasLength(7));
      expect(studentReference('12'), hasLength(7));
      expect(studentReference(''), hasLength(7));
    });

    test('es estable para la misma matrícula', () {
      expect(studentReference('123456'), studentReference('123456'));
      expect(studentReference('123456'), isNot(studentReference('123457')));
    });
  });

  test('promedio ponderado por créditos', () {
    const grades = [
      Grade(subject: 'A', credits: 8, score: 10),
      Grade(subject: 'B', credits: 2, score: 5),
    ];
    expect(weightedAverage(grades), closeTo(9.0, 1e-9));
    expect(weightedAverage(const []), 0);
  });
}
