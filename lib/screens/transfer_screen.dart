import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'payment_success_screen.dart';

/// Datos para pagar por transferencia desde la app del banco.
class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key, required this.charge});

  final Charge charge;

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  bool _reported = false;

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label copiado')));
  }

  void _simulateArrival() {
    final payment =
        AppScope.read(context).simulateTransferArrival(widget.charge);
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute(builder: (_) => PaymentSuccessScreen(payment: payment)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final info = state.transferInstructions(widget.charge);
    final theme = Theme.of(context);

    Widget copyButton(String label, String value) => IconButton(
          tooltip: 'Copiar $label',
          icon: const Icon(Icons.copy),
          onPressed: () => _copy(label, value),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Pagar por transferencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Haz una transferencia SPEI desde la app de tu banco con estos datos:',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
              child: Column(
                children: [
                  InfoRow(
                    label: 'Monto exacto',
                    value: formatMoney(info.amount),
                    trailing: copyButton(
                      'Monto',
                      info.amount.toStringAsFixed(2),
                    ),
                  ),
                  InfoRow(
                    label: 'CLABE',
                    value: info.clabe,
                    trailing: copyButton('CLABE', info.clabe),
                  ),
                  InfoRow(label: 'Beneficiario', value: info.beneficiary),
                  InfoRow(label: 'Banco', value: info.bank),
                  InfoRow(
                    label: 'Referencia numérica',
                    value: info.reference,
                    trailing: copyButton('Referencia', info.reference),
                  ),
                  InfoRow(
                    label: 'Concepto',
                    value: info.concept,
                    trailing: copyButton('Concepto', info.concept),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Escribe la referencia y el concepto tal cual. '
              'Así identificamos tu pago automáticamente.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          const SectionTitle('¿Ya transferiste?'),
          if (!_reported)
            FilledButton.tonal(
              onPressed: () => setState(() => _reported = true),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Ya hice la transferencia'),
            )
          else ...[
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.hourglass_top),
              title: Text('Esperando tu pago'),
              subtitle: Text(
                'En cuanto llegue la transferencia, tu adeudo se marcará '
                'como pagado y recibirás una notificación.',
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _simulateArrival,
              icon: const Icon(Icons.science_outlined),
              label: const Text('Simular llegada del pago (demo)'),
            ),
          ],
        ],
      ),
    );
  }
}
