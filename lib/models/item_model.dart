class ItemModel {
  final int? id;
  final int categoryId;
  final String title;
  final double price;

  // CORREGIDO: Se quitaron los paréntesis que causaban el error
  ItemModel({
    this.id, 
    required this.categoryId, 
    required this.title, 
    required this.price,
  });

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      categoryId: map['category_id'],
      title: map['title'],
      price: (map['price'] as num).toDouble(), // Evita errores si SQLite devuelve un int
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'title': title,
      'price': price,
    };
  }
}