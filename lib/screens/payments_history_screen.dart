import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

class PaymentsHistoryScreen extends StatelessWidget {
  const PaymentsHistoryScreen({super.key});

  void _showDetail(BuildContext context, Payment payment) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Comprobante de pago',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              InfoRow(label: 'Monto', value: formatMoney(payment.amount)),
              InfoRow(label: 'Concepto', value: payment.concept),
              InfoRow(label: 'Método', value: payment.method),
              InfoRow(label: 'Folio', value: payment.folio),
              InfoRow(label: 'Fecha', value: formatDateTime(payment.date)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final payments = state.payments;
    final total = payments.fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis pagos')),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: payments.isEmpty
            ? ListView(
                children: [
                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      message: 'Aún no tienes pagos registrados.',
                    ),
                ],
              )
            : ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Total pagado: ${formatMoney(total)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  for (final payment in payments)
                    ListTile(
                      leading: CircleAvatar(
                        child: Icon(
                          payment.method.startsWith('Transferencia')
                              ? Icons.account_balance
                              : Icons.credit_card,
                        ),
                      ),
                      title: Text(payment.concept),
                      subtitle: Text(
                        '${formatDate(payment.date)} · ${payment.method}',
                      ),
                      trailing: Text(
                        formatMoney(payment.amount),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onTap: () => _showDetail(context, payment),
                    ),
                ],
              ),
      ),
    );
  }
}
