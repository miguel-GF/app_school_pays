import 'package:flutter/material.dart';

import '../data/models.dart';
import '../state/app_scope.dart';
import '../widgets/common.dart';
import 'add_card_screen.dart';

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  Future<void> _confirmRemove(BuildContext context, SavedCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar tarjeta'),
        content: Text('¿Eliminar ${card.label}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.read(context).removeCard(card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis tarjetas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push<SavedCard>(
          MaterialPageRoute(builder: (_) => const AddCardScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
      body: state.cards.isEmpty
          ? const EmptyState(
              icon: Icons.credit_card_off_outlined,
              message: 'No tienes tarjetas guardadas.',
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                for (final card in state.cards)
                  ListTile(
                    leading: CardBrandBadge(brand: card.brand),
                    title: Text(card.label),
                    subtitle: Text(
                      'Vence ${card.expiry}'
                      '${card.id == state.defaultCardId ? ' · Predeterminada' : ''}',
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'default') {
                          state.setDefaultCard(card.id);
                        } else if (action == 'remove') {
                          _confirmRemove(context, card);
                        }
                      },
                      itemBuilder: (_) => [
                        if (card.id != state.defaultCardId)
                          const PopupMenuItem(
                            value: 'default',
                            child: Text('Usar como predeterminada'),
                          ),
                        const PopupMenuItem(
                          value: 'remove',
                          child: Text('Eliminar'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
