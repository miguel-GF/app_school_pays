import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import '../state/app_scope.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final card = await AppScope.read(context).addCard(makeDefault: true);
      if (mounted) {
        Navigator.of(context).pop(card);
      }
    } on StripeException catch (error) {
      if (mounted && error.error.code != FailureCode.Canceled) {
        setState(() => _error = error.error.localizedMessage ?? 'No se pudo guardar la tarjeta.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar tarjeta')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 16),
          Text(
            'Stripe abrirá un formulario seguro para guardar tu tarjeta. '
            'Los datos de tarjeta no pasan ni se guardan en el API escolar.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            child: _saving
                ? const SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Continuar con Stripe'),
          ),
        ],
      ),
    );
  }
}
