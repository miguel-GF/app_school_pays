import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart'
    show CardField, FailureCode, StripeException;

import '../core/format.dart';
import '../data/models.dart';
import '../data/payment_gateway.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'payment_success_screen.dart';

/// Pantalla de cobro con un layout propio (sin PaymentSheet de Stripe).
///
/// El alumno elige una tarjeta guardada o captura una nueva en el mismo lugar.
/// Los datos de tarjeta los captura [CardField] de forma nativa y segura.
class PayScreen extends StatefulWidget {
  const PayScreen({super.key, required this.charge});

  final Charge charge;

  @override
  State<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends State<PayScreen> {
  bool _paying = false;
  bool _preparing = true;
  bool _cardComplete = false;
  bool _useNewCard = false;
  String? _selectedCardId;
  String? _error;
  String? _prepareError;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    if (state.cards.isEmpty) {
      _useNewCard = true;
    } else {
      _selectedCardId = state.defaultCard?.id ?? state.cards.first.id;
    }
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await AppScope.read(context).gateway.prepare();
      if (mounted) {
        setState(() {
          _preparing = false;
          _prepareError = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _preparing = false;
          _prepareError = friendlyPaymentError(error);
        });
      }
    }
  }

  Future<void> _retryPrepare() async {
    setState(() {
      _preparing = true;
      _prepareError = null;
    });
    await _prepare();
  }

  void _selectCard(String id) {
    if (_paying) {
      return;
    }
    setState(() {
      _useNewCard = false;
      _selectedCardId = id;
      _error = null;
    });
  }

  void _selectNewCard() {
    if (_paying) {
      return;
    }
    setState(() {
      _useNewCard = true;
      _selectedCardId = null;
      _error = null;
    });
  }

  bool get _canPay {
    if (_paying || _preparing || _prepareError != null) {
      return false;
    }
    return _useNewCard ? _cardComplete : _selectedCardId != null;
  }

  Future<void> _pay() async {
    final state = AppScope.read(context);
    String? label;
    for (final card in state.cards) {
      if (card.id == _selectedCardId) {
        label = card.label;
        break;
      }
    }

    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      final payment = await state.payWithCard(
        widget.charge,
        cardId: _useNewCard ? null : _selectedCardId,
        cardLabel: label,
      );
      try {
        await state.refresh();
      } catch (_) {
        // El cobro ya se confirmó; el historial se actualiza al volver.
      }
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(builder: (_) => PaymentSuccessScreen(payment: payment)),
      );
    } on StripeException catch (error) {
      if (mounted && error.error.code != FailureCode.Canceled) {
        setState(() => _error = friendlyPaymentError(error));
      }
    } on PaymentDeclined catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = friendlyPaymentError(error));
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
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: !_paying,
      child: Scaffold(
        appBar: AppBar(title: const Text('Confirmar pago')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _PaymentSummary(
              charge: widget.charge,
              studentName: state.student?.name ?? '',
              configName: state.config.shortName,
            ),
            const SizedBox(height: 24),
            Text(
              '¿Con qué tarjeta pagas?',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selecciona una tarjeta guardada o captura una nueva.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final card in state.cards)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SavedCardOption(
                  card: card,
                  selected: !_useNewCard && card.id == _selectedCardId,
                  isDefault: card.id == state.defaultCardId,
                  onTap: () => _selectCard(card.id),
                ),
              ),
            _NewCardOption(
              selected: _useNewCard,
              onTap: _selectNewCard,
            ),
            if (_useNewCard) ...[
              const SizedBox(height: 12),
              _buildCardForm(context),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: scheme.outline),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pago procesado por Stripe. No guardamos el número ni el CVC de tu tarjeta.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: FilledButton(
              onPressed: _canPay ? _pay : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _paying
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, size: 18),
                        const SizedBox(width: 8),
                        Text('Pagar ${formatMoney(widget.charge.amount)}'),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm(BuildContext context) {
    final theme = Theme.of(context);

    if (_preparing) {
      return const SizedBox(
        height: 64,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_prepareError != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ErrorBanner(message: _prepareError!),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _retryPrepare,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Datos de la tarjeta',
            style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: CardField(
            enablePostalCode: false,
            onCardChanged: (details) {
              final complete = details?.complete ?? false;
              if (complete != _cardComplete) {
                setState(() => _cardComplete = complete);
              }
            },
            numberHintText: 'Número de tarjeta',
            expirationHintText: 'MM/AA',
            cvcHintText: 'CVC',
            style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurface),
            cursorColor: theme.colorScheme.primary,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }
}

/// Resumen compacto: concepto, periodo y total a pagar.
class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({
    required this.charge,
    required this.studentName,
    required this.configName,
  });

  final Charge charge;
  final String studentName;
  final String configName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        charge.concept,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${charge.period} · $configName',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (studentName.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                studentName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: scheme.outlineVariant),
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Total a pagar', style: theme.textTheme.bodyMedium),
                const Spacer(),
                Text(
                  formatMoney(charge.amount),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opción seleccionable para una tarjeta guardada.
class _SavedCardOption extends StatelessWidget {
  const _SavedCardOption({
    required this.card,
    required this.selected,
    required this.isDefault,
    required this.onTap,
  });

  final SavedCard card;
  final bool selected;
  final bool isDefault;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              CardBrandBadge(brand: card.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vence ${card.expiry}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDefault) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Predeterminada',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opción para capturar una tarjeta nueva en la misma pantalla.
class _NewCardOption extends StatelessWidget {
  const _NewCardOption({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.45)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_card, color: scheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nueva tarjeta',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Débito o crédito',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? scheme.primary : scheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
