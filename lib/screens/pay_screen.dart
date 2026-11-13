import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' show FailureCode, StripeException;

import '../core/format.dart';
import '../data/models.dart';
import '../data/payment_gateway.dart';
import '../state/app_scope.dart';
import 'add_card_screen.dart';
import 'payment_success_screen.dart';

class PayScreen extends StatefulWidget {
  const PayScreen({super.key, required this.charge});

  final Charge charge;

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  bool _paying = false;
  String? _error;

  Future<void> _addCard() async {
    await Navigator.of(context).push<SavedCard>(
      MaterialPageRoute(builder: (_) => const AddCardScreen()),
    );
  }

  Future<void> _pay() async {
    final state = AppScope.read(context);
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final payment = await state.payWithCard(widget.charge);
      await state.refresh();
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(payment: payment)),
      );
    } on StripeException catch (error) {
      if (mounted && error.error.code != FailureCode.Canceled) {
        setState(() => _error = error.error.localizedMessage ?? 'No se pudo procesar el pago.');
      }
    } on PaymentDeclined catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _paying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_paying,
      child: Scaffold(
        appBar: AppBar(title: const Text('Pago de prueba')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.charge.concept, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Text('Total de prueba')),
                        Text(
                          formatMoney(widget.charge.amount),
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Tarjetas guardadas', style: theme.textTheme.titleMedium),
            if (state.cards.isEmpty)
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.credit_card_off_outlined),
                title: Text('Aún no tienes tarjetas guardadas'),
              )
            else
              for (final card in state.cards)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.credit_card),
                  title: Text(card.label),
                  subtitle: Text('Vence ${card.expiry}'),
                ),
            OutlinedButton.icon(
              onPressed: _paying ? null : _addCard,
              icon: const Icon(Icons.add_card),
              label: const Text('Guardar otra tarjeta'),
            ),
            const SizedBox(height: 16),
            Text(
              'La pantalla segura de Stripe permite elegir una tarjeta guardada '
              'o ingresar una nueva. El cargo se confirma en el API de la escuela.',
              style: theme.textTheme.bodySmall,
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _paying ? null : _pay,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: _paying
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Continuar al pago de ${formatMoney(widget.charge.amount)}'),
            ),
          ),
        ),
      ),
    );
  }
}
