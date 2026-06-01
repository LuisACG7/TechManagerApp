import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../theme/gym_theme.dart';

class CatalogCrudScreen extends StatefulWidget {
  const CatalogCrudScreen({Key? key}) : super(key: key);

  @override
  State<CatalogCrudScreen> createState() => _CatalogCrudScreenState();
}

class _CatalogCrudScreenState extends State<CatalogCrudScreen> {
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // Controladores para los formularios
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  // Cargar productos y categorías desde la base de datos
  Future<void> _refreshData() async {
    setState(() => _isLoading = true);
    final categoriesData = await DatabaseHelper.instance.getCategories();
    
    // Obtenemos todos los ítems haciendo una consulta directa
    final db = await DatabaseHelper.instance.database;
    final itemsData = await db.rawQuery('''
      SELECT items.*, categories.name as category_name 
      FROM items 
      INNER JOIN categories ON items.category_id = categories.id
    ''');

    setState(() {
      _categories = categoriesData;
      _items = itemsData;
      _isLoading = false;
    });
  }

  // Mostrar el Formulario para Agregar o Editar un Producto (CRUD)
  void _showFormModal(int? itemId, String? currentTitle, double? currentPrice, int? currentCatId) {
    if (itemId != null) {
      _titleController.text = currentTitle!;
      _priceController.text = currentPrice!.toString();
      _selectedCategoryId = currentCatId;
    } else {
      _titleController.clear();
      _priceController.clear();
      _selectedCategoryId = _categories.isNotEmpty ? _categories[0]['id'] : null;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GymTheme.surfaceDark,
      builder: (context) => StatefulBuilder( // Permite actualizar el Dropdown dentro del Modal
        builder: (BuildContext context, StateSetter setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20, left: 16, right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  itemId == null ? 'Agregar Nuevo Bien/Membresía' : 'Editar Bien',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Nombre del producto o servicio', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Precio (\$)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Categoría Relacionada:', style: TextStyle(color: GymTheme.textGrey)),
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
                    setModalState(() => _selectedCategoryId = val);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GymTheme.accentGreen,
                    minimumSize: const Size.fromHeight(45),
                  ),
                  onPressed: () async {
                    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _selectedCategoryId == null) return;

                    final db = await DatabaseHelper.instance.database;
                    final data = {
                      'category_id': _selectedCategoryId,
                      'title': _titleController.text,
                      'price': double.parse(_priceController.text),
                    };

                    if (itemId == null) {
                      // CREATE
                      await db.insert('items', data);
                    } else {
                      // UPDATE
                      await db.update('items', data, where: 'id = ?', whereArgs: [itemId]);
                    }

                    _refreshData();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    itemId == null ? 'GUARDAR' : 'ACTUALIZAR', 
                    style: const TextStyle(color: GymTheme.backgroundDark, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  // DELETE con validación real de Integridad Referencial (PRAGMA ON)
  Future<void> _deleteItem(int id) async {
    final db = await DatabaseHelper.instance.database;
    try {
      // Intentará borrar de la tabla 'items'
      await db.delete('items', where: 'id = ?', whereArgs: [id]);
      _refreshData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bien eliminado correctamente.')),
      );
    } catch (e) {
      // Al dispararse el error de llave foránea por restricción de SQLite cae en este bloque
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: GymTheme.statusCancel, // Color Rojo del Tema
          duration: Duration(seconds: 4),
          content: Text(
            '❌ Error de Integridad Referencial: No se puede eliminar este producto porque está vinculado a un servicio activo.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Bienes Gym'),
        backgroundColor: GymTheme.surfaceDark,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  color: GymTheme.surfaceDark,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Categoría: ${item['category_name']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('\$${item['price']}', style: const TextStyle(color: GymTheme.accentGreen, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.edit, color: GymTheme.primaryBlue),
                          onPressed: () => _showFormModal(item['id'], item['title'], item['price'], item['category_id']),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: GymTheme.statusCancel),
                          onPressed: () => _deleteItem(item['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: GymTheme.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showFormModal(null, null, null, null),
      ),
    );
  }
}