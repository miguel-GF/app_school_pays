import 'package:flutter_test/flutter_test.dart';

import 'package:app_escolar/app.dart';
import 'package:app_escolar/config/school_config.dart';
import 'package:app_escolar/data/biometric_service.dart';
import 'package:app_escolar/data/payment_gateway.dart';
import 'package:app_escolar/data/school_api.dart';
import 'package:app_escolar/state/app_state.dart';

void main() {
  testWidgets('shows the selected school login screen', (WidgetTester tester) async {
    final state = AppState(
      config: SchoolConfig.all['norte']!,
      api: MockSchoolApi(),
      gateway: MockPaymentGateway(),
      biometrics: MockBiometricService(),
    );

    await tester.pumpWidget(SchoolApp(state: state));

    expect(find.text('Universidad Demo Norte'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
