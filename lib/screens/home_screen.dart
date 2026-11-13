import 'package:flutter/material.dart';

import '../core/format.dart';
import '../data/models.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'pay_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final student = state.student;
    final pending = state.pendingCharges;
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(state.config.shortName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SchoolLogo(config: state.config, size: 32),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: state.refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Text(
                'Hola, ${student?.firstName ?? ''}',
                style: theme.textTheme.headlineSmall,
              ),
            ),
            _BalanceCard(
              balance: state.balance,
              next: pending.isEmpty ? null : pending.first,
              loading: state.loading && state.charges.isEmpty,
              testPayment: state.testPayment,
            ),
            const SectionTitle('Pendientes de pago'),
            if (state.loading && state.charges.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (pending.isEmpty)
              const EmptyState(
                icon: Icons.check_circle_outline,
                message: 'Estás al corriente. No tienes pagos pendientes.',
              )
            else
              for (final charge in pending)
                _ChargeTile(charge: charge, overdue: charge.isOverdue(now)),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.next,
    required this.loading,
    required this.testPayment,
  });

  final double balance;
  final Charge? next;
  final bool loading;
  final Charge testPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saldo pendiente',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              loading ? '—' : formatMoney(balance),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (next != null) ...[
              const SizedBox(height: 12),
              Text(
                'Próximo vencimiento: ${next!.concept} ${next!.period}, '
                '${formatDate(next!.dueDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PayScreen(charge: testPayment),
                ),
              ),
              child: Text('Pagar prueba ${formatMoney(testPayment.amount)}'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChargeTile extends StatelessWidget {
  const _ChargeTile({required this.charge, required this.overdue});

  final Charge charge;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
        title: Text('${charge.concept} · ${charge.period}'),
        subtitle: Text(
          overdue
              ? 'Vencido el ${formatDate(charge.dueDate)}'
              : 'Vence el ${formatDate(charge.dueDate)}',
          style: TextStyle(color: overdue ? scheme.error : null),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatMoney(charge.amount),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              'Pagar',
              style: TextStyle(color: scheme.primary, fontSize: 13),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => PayScreen(charge: charge)),
        ),
      ),
    );
  }
}
