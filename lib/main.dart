import 'package:flutter/material.dart';

import 'app.dart';
import 'config/school_config.dart';
import 'data/api_client.dart';
import 'data/biometric_service.dart';
import 'data/payment_gateway.dart';
import 'data/school_api.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final client = ApiClient(SchoolConfig.current.apiBaseUrl);
  final state = AppState(
    config: SchoolConfig.current,
    api: HttpSchoolApi(client),
    gateway: StripePaymentGateway(client),
    biometrics: MockBiometricService(),
  );
  runApp(SchoolApp(state: state));
}
