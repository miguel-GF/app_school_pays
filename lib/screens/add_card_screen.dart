import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart'
    show CardField, CardFieldInputDetails, FailureCode, StripeException;

import '../data/models.dart';
import '../data/payment_gateway.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';

/// Captura una tarjeta con el campo nativo de Stripe y una vista previa.
///
/// Sustituye al PaymentSheet predeterminado de Stripe: el formulario y la
/// vista previa son parte de la app; Stripe solo captura los datos.
class AddCardScreen extends StatefulWidget {
  const AddCardScreen({super.key});

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  bool _ready = false;
  bool _saving = false;
  bool _complete = false;
  String? _error;
  CardFieldInputDetails? _details;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await AppScope.read(context).gateway.prepare();
      if (mounted) {
        setState(() {
          _ready = true;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _ready = false;
          _error = friendlyPaymentError(error);
        });
      }
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _ready = false;
    });
    await _prepare();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final card = await AppScope.read(context).addCard(makeDefault: true);
      if (mounted) {
        Navigator.of(context).pop<SavedCard>(card);
      }
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
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(title: const Text('Agregar tarjeta')),
        body: !_ready
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ErrorBanner(message: _error!),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _retry,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'Guarda una tarjeta',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'La usarás para tus próximos pagos escolares.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _CardPreview(
                    details: _details,
                    holder: state.student?.name ?? '',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Datos de la tarjeta',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: CardField(
                      enablePostalCode: false,
                      onCardChanged: (details) {
                        setState(() {
                          _details = details;
                          _complete = details?.complete ?? false;
                        });
                      },
                      numberHintText: 'Número de tarjeta',
                      expirationHintText: 'MM/AA',
                      cvcHintText: 'CVC',
                      style: TextStyle(fontSize: 16, color: scheme.onSurface),
                      cursorColor: scheme.primary,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 16, color: scheme.outline),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Stripe cifra los datos. La escuela solo guarda la marca y los últimos 4 dígitos.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    ErrorBanner(message: _error!),
                  ],
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: _ready && _complete && !_saving ? _save : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _saving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Guardar tarjeta'),
            ),
          ),
        ),
      ),
    );
  }
}

/// Vista previa visual de la tarjeta mientras se captura.
class _CardPreview extends StatelessWidget {
  const _CardPreview({required this.details, required this.holder});

  final CardFieldInputDetails? details;
  final String holder;

  String get _brandLabel {
    final brand = details?.brand?.toLowerCase().replaceAll('_', ' ') ?? '';
    if (brand.isEmpty || brand == 'unknown') {
      return 'TARJETA';
    }
    return brand.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last4 = details?.last4 ?? '';
    final number = last4.isEmpty ? '•••• •••• •••• ••••' : '•••• •••• •••• $last4';
    final month = details?.expiryMonth;
    final year = details?.expiryYear;
    final expiry = month == null || year == null
        ? 'MM/AA'
        : '${month.toString().padLeft(2, '0')}/${(year % 100).toString().padLeft(2, '0')}';

    return Container(
      height: 184,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primary, scheme.primary.withValues(alpha: 0.65)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card, color: scheme.onPrimary, size: 26),
              const Spacer(),
              Text(
                _brandLabel,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            number,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITULAR',
                      style: TextStyle(
                        color: scheme.onPrimary.withValues(alpha: 0.65),
                        fontSize: 9,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      holder.isEmpty ? '—' : holder.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VENCE',
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.65),
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    expiry,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
