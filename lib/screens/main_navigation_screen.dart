import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:badges/badges.dart' as bg;
import 'dashboard_calendar_screen.dart';
import 'service_form_screen.dart';
import 'cart_summary_screen.dart';
import 'catalog_crud_screen.dart'; // Importación de la nueva pantalla CRUD
import '../theme/gym_theme.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({Key? key}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> shoppingCart = [];

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      shoppingCart.add(item);
    });
  }

  void clearCart() {
    setState(() {
      shoppingCart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      const DashboardCalendarScreen(),
      ServiceFormScreen(onItemAdded: addToCart, currentCart: shoppingCart),
      CartSummaryScreen(cartItems: shoppingCart, onOrderPlaced: clearCart),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alpha Gym Systems', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: GymTheme.surfaceDark,
        elevation: 0,
        actions: [
          // Botón de acceso al CRUD de Catálogo de Bienes
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: GymTheme.accentGreen),
            tooltip: 'Administrar Catálogo',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CatalogCrudScreen()),
              );
            },
          ),
          // Espaciado dinámico con la insignia del carrito
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8.0, left: 8.0),
            child: bg.Badge(
              badgeContent: Text(
                '${shoppingCart.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              badgeStyle: const bg.BadgeStyle(badgeColor: GymTheme.primaryBlue),
              child: IconButton(
                icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _currentIndex = 2; // Redirección directa a la vista del carrito
                  });
                },
              ),
            ),
          )
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        color: GymTheme.surfaceDark,
        child: SalomonBottomBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: [
            SalomonBottomBarItem(
              icon: const Icon(Icons.calendar_month),
              title: const Text("Calendario"),
              selectedColor: GymTheme.primaryBlue,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.add_box),
              title: const Text("Nueva Orden"),
              selectedColor: GymTheme.accentGreen,
            ),
            SalomonBottomBarItem(
              icon: const Icon(Icons.shopping_cart),
              title: const Text("Carrito"),
              selectedColor: Colors.purpleAccent,
            ),
          ],
        ),
      ),
    );
  }
}