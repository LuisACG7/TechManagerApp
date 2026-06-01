import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('gym_services.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);
    
    return await openDatabase(
      path, 
      version: 1, 
      onCreate: _createDB,
      // Activa el soporte de integridad referencial en cada apertura de conexión
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _createDB(Database db, int version) async {
    // Tablas de Categorías
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Tabla de Bienes / Productos / Membresías
    await db.execute('''
      CREATE TABLE items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        price REAL NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
      )
    ''');

    // Tabla de Ventas / Servicios (Recordatorios automáticos incluidos)
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_name TEXT NOT NULL,
        date TEXT NOT NULL,
        status TEXT NOT NULL, -- 'En Proceso', 'Completado', 'Cancelado'
        total REAL NOT NULL,
        reminder_date TEXT NOT NULL -- 2 días antes del servicio para alarmas locales
      )
    ''');

    // Tabla Detalle de la Venta (N a N entre Servicios e Items)
    await db.execute('''
      CREATE TABLE service_details (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_id INTEGER NOT NULL,
        item_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        FOREIGN KEY (service_id) REFERENCES services (id) ON DELETE RESTRICT,
        FOREIGN KEY (item_id) REFERENCES items (id) ON DELETE RESTRICT
      )
    ''');

    // Inserción de datos iniciales (Seeders de prueba)
    await db.insert('categories', {'name': 'Entrenamientos'});
    await db.insert('categories', {'name': 'Nutrición / Suplementos'});

    await db.insert('items', {'category_id': 1, 'title': 'Coach Personal Mensual', 'price': 1200.0});
    await db.insert('items', {'category_id': 1, 'title': 'Rutina HIIT Guiada', 'price': 350.0});
    await db.insert('items', {'category_id': 2, 'title': 'Proteína Whey Isolate', 'price': 850.0});
  }

  // --- MÉTODOS CRUD ---

  /// Guarda de forma transaccional un Servicio junto con todos sus artículos del carrito
  Future<void> saveCompleteService({
    required String clientName,
    required String date,
    required String status,
    required double total,
    required String reminderDate,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    final db = await instance.database;

    // La transacción asegura la atomicidad: o se guarda todo con sus detalles o no se guarda nada
    await db.transaction((txn) async {
      // 1. Insertar la cabecera en la tabla 'services'
      final serviceId = await txn.insert('services', {
        'client_name': clientName,
        'date': date,
        'status': status,
        'total': total,
        'reminder_date': reminderDate,
      });

      // 2. Recorrer el carrito e insertar cada producto en 'service_details'
      for (var item in cartItems) {
        // Busca el ID bajo 'id' o bajo 'item_id' por si acaso
        final realItemId = item['id'] ?? item['item_id'];

        if (realItemId == null) {
          throw Exception("Error crítico: El producto '${item['title']}' no tiene un ID válido en el carrito.");
        }

        await txn.insert('service_details', {
          'service_id': serviceId,
          'item_id': realItemId, // Ahora sí aseguramos el ID correcto de la tabla 'items'
          'quantity': 1,
        });
      }
    });
  }

  Future<List<Map<String, dynamic>>> getServices() async {
    final db = await instance.database;
    return await db.query('services', orderBy: 'date ASC');
  }

  Future<int> updateServiceStatus(int id, String status) async {
    final db = await instance.database;
    return await db.update(
      'services',
      {'status': status},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await instance.database;
    return await db.query('categories');
  }

  Future<List<Map<String, dynamic>>> getItemsByCategory(int categoryId) async {
    final db = await instance.database;
    return await db.query('items', where: 'category_id = ?', whereArgs: [categoryId]);
  }
}