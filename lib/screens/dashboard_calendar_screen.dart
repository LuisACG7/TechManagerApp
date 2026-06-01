import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:animate_do/animate_do.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../theme/gym_theme.dart';

class DashboardCalendarScreen extends StatefulWidget {
  const DashboardCalendarScreen({Key? key}) : super(key: key);

  @override
  State<DashboardCalendarScreen> createState() => _DashboardCalendarScreenState();
}

class _DashboardCalendarScreenState extends State<DashboardCalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _filteredServices = [];
  String _currentFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadServices();
  }

  Future<void> _loadServices() async {
    final data = await DatabaseHelper.instance.getServices();
    setState(() {
      _allServices = data;
      _applyFilter(_currentFilter);
    });
  }

  void _applyFilter(String filter) {
    _currentFilter = filter;
    if (filter == 'Todos') {
      _filteredServices = _allServices;
    } else {
      _filteredServices = _allServices.where((s) => s['status'] == filter).toList();
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    String formattedDay = DateFormat('yyyy-MM-dd').format(day);
    return _allServices.where((s) => s['date'] == formattedDay).toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'En Proceso': return GymTheme.accentGreen;
      case 'Cancelado': return GymTheme.statusCancel;
      case 'Completado': return Colors.white;
      default: return Colors.grey;
    }
  }

  // REQUERIMIENTO: Modal de pantalla completa de eventos del día seleccionado
  void _showDayEventsModal(DateTime day) {
    final dayEvents = _getEventsForDay(day);
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cerrar',
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: GymTheme.backgroundDark,
          appBar: AppBar(
            title: Text('Servicios - ${DateFormat('dd MMMM').format(day)}'),
            backgroundColor: GymTheme.surfaceDark,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: dayEvents.isEmpty 
            ? const Center(child: Text('No hay eventos programados para este día.'))
            : ListView.builder(
                itemCount: dayEvents.length,
                itemBuilder: (context, index) {
                  final event = dayEvents[index];
                  return Card(
                    color: GymTheme.surfaceDark,
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text(event['client_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Total: \$${event['total']} | Recordatorio: ${event['reminder_date']}'),
                      trailing: DropdownButton<String>(
                        value: event['status'],
                        dropdownColor: GymTheme.surfaceDark,
                        items: ['En Proceso', 'Completado', 'Cancelado'].map((String val) {
                          return DropdownMenuItem<String>(value: val, child: Text(val));
                        }).toList(),
                        onChanged: (newStatus) async {
                          if (newStatus != null) {
                            await DatabaseHelper.instance.updateServiceStatus(event['id'], newStatus);
                            _loadServices();
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int completedCount = _allServices.where((s) => s['status'] == 'Completado').length;
    double progressPercent = _allServices.isEmpty ? 0.0 : completedCount / _allServices.length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Widget Nuevo 1: Panel de Progreso Gráfico superior
          SliverToBoxAdapter(
            child: FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GymTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    CircularPercentIndicator(
                      radius: 40.0,
                      lineWidth: 8.0,
                      percent: progressPercent,
                      center: Text("${(progressPercent * 100).toStringAsFixed(0)}%"),
                      progressColor: GymTheme.accentGreen,
                      backgroundColor: Colors.grey.shade800,
                    ),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rendimiento Global', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('Control operativo de servicios', style: TextStyle(color: GymTheme.textGrey, fontSize: 12)),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
          // Bloque del Calendario
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: GymTheme.surfaceDark,
                borderRadius: BorderRadius.circular(16)
              ),
              child: TableCalendar(
                firstDay: DateTime.utc(2025, 1, 1),
                lastDay: DateTime.utc(2027, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _showDayEventsModal(selectedDay);
                },
                eventLoader: _getEventsForDay,
                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(color: GymTheme.primaryBlue, shape: BoxShape.circle),
                  selectedDecoration: BoxDecoration(color: GymTheme.accentGreen, shape: BoxShape.circle),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return const SizedBox();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.map((event) {
                        final ev = event as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getStatusColor(ev['status']),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
          // Segmentación de Filtros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['Todos', 'En Proceso', 'Completado', 'Cancelado'].map((f) {
                  return ChoiceChip(
                    label: Text(f, style: const TextStyle(fontSize: 11)),
                    selected: _currentFilter == f,
                    selectedColor: GymTheme.primaryBlue,
                    onSelected: (selected) {
                      if (selected) setState(() => _applyFilter(f));
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          // Render de Listas mediante Slivers
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _filteredServices[index];
                return FadeInLeft(
                  duration: Duration(milliseconds: 200 * index),
                  child: Card(
                    color: GymTheme.surfaceDark,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: Icon(Icons.fitness_center, color: _getStatusColor(item['status'])),
                      title: Text(item['client_name']),
                      subtitle: Text('Fecha: ${item['date']} | Alarma: ${item['reminder_date']}'),
                      trailing: Text('\$${item['total']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              },
              childCount: _filteredServices.length,
            ),
          )
        ],
      ),
    );
  }
}