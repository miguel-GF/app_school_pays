import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../widgets/common.dart';

/// Comprobante después de pagar.
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key, required this.payment});

  final Payment payment;

  void _done(BuildContext context) =>
      Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _done(context);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: scheme.primaryContainer,
                  child: Icon(
                    Icons.check,
                    size: 44,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¡Pago realizado!',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                formatMoney(payment.amount),
                textAlign: TextAlign.center,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      InfoRow(label: 'Concepto', value: payment.concept),
                      InfoRow(label: 'Método', value: payment.method),
                      if (payment.gateway != null)
                        InfoRow(label: 'Pasarela', value: payment.gateway!),
                      InfoRow(label: 'Folio', value: payment.folio),
                      InfoRow(
                        label: 'Fecha',
                        value: formatDateTime(payment.date),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Puedes consultar este comprobante en "Mis pagos".',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _done(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                ),
                child: const Text('Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
