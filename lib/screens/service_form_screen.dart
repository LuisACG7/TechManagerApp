import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/gym_theme.dart';

class ServiceFormScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onItemAdded;
  final List<Map<String, dynamic>> currentCart;

  const ServiceFormScreen({Key? key, required this.onItemAdded, required this.currentCart}) : super(key: key);

  @override
  State<ServiceFormScreen> createState() => _ServiceFormScreenState();
}

class _ServiceFormScreenState extends State<ServiceFormScreen> {
  final _clientController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Map<String, dynamic>> _categories = [];
  int? _selectedCategoryId;
  List<Map<String, dynamic>> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await DatabaseHelper.instance.getCategories();
    setState(() {
      _categories = cats;
      if (cats.isNotEmpty) {
        _selectedCategoryId = cats[0]['id'];
        _loadItems(_selectedCategoryId!);
      }
    });
  }

  Future<void> _loadItems(int catId) async {
    final items = await DatabaseHelper.instance.getItemsByCategory(catId);
    setState(() {
      _availableItems = items;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Registrar Orden de Servicio Gym', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _clientController,
              decoration: const InputDecoration(
                labelText: 'Nombre Completo del Atleta',
                filled: true,
                fillColor: GymTheme.surfaceDark,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              tileColor: GymTheme.surfaceDark,
              title: Text("Fecha Evento: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}"),
              trailing: const Icon(Icons.calendar_today, color: GymTheme.primaryBlue),
              onTap: () async {
                DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2025),
                  lastDate: DateTime(2027),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
            ),
            const SizedBox(height: 20),
            const Text('Paso 2: Selecciona Categorías de Bienes', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedCategoryId,
              isExpanded: true,
              dropdownColor: GymTheme.surfaceDark,
              items: _categories.map((cat) {
                return DropdownMenuItem<int>(
                  value: cat['id'],
                  child: Text(cat['name']),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategoryId = val);
                  _loadItems(val);
                }
              },
            ),
            const SizedBox(height: 16),
            const Text('Bienes disponibles en esta categoría:', style: TextStyle(color: GymTheme.textGrey)),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableItems.length,
              itemBuilder: (context, idx) {
                final item = _availableItems[idx];
                return Card(
                  color: GymTheme.surfaceDark,
                  child: ListTile(
                    title: Text(item['title']),
                    trailing: Text('\$${item['price']}'),
                    leading: IconButton(
                      icon: const Icon(Icons.add_circle, color: GymTheme.accentGreen),
                      onPressed: () {
                        if (_clientController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Escribe primero el nombre del cliente')),
                          );
                          return;
                        }
                        widget.onItemAdded({
                          'client': _clientController.text,
                          'date': DateFormat('yyyy-MM-dd').format(_selectedDate),
                          'item_id': item['id'],
                          'title': item['title'],
                          'price': item['price']
                        });
                      },
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}