import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/gym_theme.dart';

class CartSummaryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> cartItems;
  final VoidCallback onOrderPlaced;

  const CartSummaryScreen({Key? key, required this.cartItems, required this.onOrderPlaced}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalSum = cartItems.fold(0, (sum, item) => sum + item['price']);

    return Scaffold(
      body: cartItems.isEmpty
          ? const Center(
              child: Text(
                'El carrito de bienes está vacío.',
                style: TextStyle(color: GymTheme.textGrey, fontSize: 16),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final uiItem = cartItems[index];
                      return ListTile(
                        title: Text(uiItem['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Atleta: ${uiItem['client']}'),
                        trailing: Text(
                          '\$${uiItem['price']}',
                          style: const TextStyle(color: GymTheme.accentGreen, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: GymTheme.surfaceDark,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monto Final:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('\$$totalSum', style: const TextStyle(fontSize: 18, color: GymTheme.accentGreen, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GymTheme.primaryBlue,
                          minimumSize: const Size.fromHeight(50),
                        ),
                        onPressed: () async {
                          if (cartItems.isEmpty) return;

                          try {
                            final baseInfo = cartItems[0];
                            DateTime serviceDate = DateTime.parse(baseInfo['date']);
                            
                            // REQUERIMIENTO LÓGICO: Programar alarma con 2 días de anticipación
                            DateTime reminderDate = serviceDate.subtract(const Duration(days: 2));
                            String formattedReminder = DateFormat('yyyy-MM-dd').format(reminderDate);

                            // CORRECCIÓN: Llamada al método transaccional unificado
                            await DatabaseHelper.instance.saveCompleteService(
                              clientName: baseInfo['client'],
                              date: baseInfo['date'],
                              status: 'En Proceso',
                              total: totalSum,
                              reminderDate: formattedReminder,
                              cartItems: cartItems, // El Helper se encarga de desglosar los detalles
                            );

                            // Vaciar el carrito y actualizar el estado global de la app
                            onOrderPlaced();

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Servicio guardado con alarma programada local.'),
                              ),
                            );
                          } catch (e) {
                            // Captura de errores por si algo falla en la inserción
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: GymTheme.statusCancel,
                                content: Text('❌ Error al registrar el servicio: $e'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          'TERMINAR DE REGISTRAR SERVICIO', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}