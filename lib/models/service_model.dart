class ServiceModel {
  final int? id;
  final String clientName;
  final String date;
  final String status; // 'En Proceso', 'Completado', 'Cancelado'
  final double total;
  final String reminderDate; // Alarma local programada con 2 días de anticipación

  ServiceModel({
    this.id,
    required this.clientName,
    required this.date,
    required this.status,
    required this.total,
    required this.reminderDate,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map) {
    return ServiceModel(
      id: map['id'],
      clientName: map['client_name'],
      date: map['date'],
      status: map['status'],
      total: (map['total'] as num).toDouble(),
      reminderDate: map['reminder_date'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'client_name': clientName,
      'date': date,
      'status': status,
      'total': total,
      'reminder_date': reminderDate,
    };
  }
}