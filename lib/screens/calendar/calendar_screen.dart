import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../models/data_provider.dart';
import '../../services/interaction_logger.dart';
import 'event_form_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  static const accentColor = Color(0xFF528265);
  static const decorationColor = Color.fromRGBO(141, 232, 150, 0.56);

  late DateTime _currentMonth;
  late DateTime _selectedDate;

  // Método de confirmação para apagar evento
  void _showDeleteEventConfirmation(BuildContext context, CalendarEvent event) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Evento'),
        content: Text('Tem a certeza que quer apagar o evento "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final data = Provider.of<AppData>(context, listen: false);
              data.removeEvent(event.id);
              Navigator.pop(ctx); // Fecha o diálogo
              InteractionLogger.log('Calendário', 'EVENTO_APAGADO', details: event.title);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Evento apagado.'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
            },
            child: const Text(
              'Apagar',
              style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _firstDayOfWeek(DateTime date) {
    return date.weekday - 1;
  }

  List<Widget> _buildCalendarDays(AppData data) {
    final days = <Widget>[];
    final daysInMonth = _daysInMonth(_currentMonth);
    final firstDay = _firstDayOfWeek(DateTime(_currentMonth.year, _currentMonth.month, 1));
    final today = DateTime.now();

    for (int i = 0; i < firstDay; i++) {
      days.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_currentMonth.year, _currentMonth.month, day);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      final isSelected = date.year == _selectedDate.year &&
          date.month == _selectedDate.month &&
          date.day == _selectedDate.day;
      final hasEvents = data.getEventsForDate(date).isNotEmpty;

      days.add(
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            InteractionLogger.log('Calendário', 'DIA_SELECIONADO',
                details: DateFormat('yyyy-MM-dd').format(date));
            setState(() => _selectedDate = date);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? accentColor
                  : isToday
                      ? accentColor.withAlpha(30)
                      : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: accentColor, width: 2)
                  : null,
            ),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontWeight: isToday || isSelected ? FontWeight.bold : null,
                    ),
                  ),
                  if (hasEvents && !isSelected)
                    Positioned(
                      bottom: -2,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 5,
                        width: 5,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return days;
  }

  void _changeMonth(int delta) {
    HapticFeedback.selectionClick();
    InteractionLogger.log('Calendário', 'MUDANCA_MES',
        details: delta > 0 ? 'Próximo' : 'Anterior');
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta);
    });
  }

  List<CalendarEvent> _sortByTime(List<CalendarEvent> events) {
    final sorted = List<CalendarEvent>.from(events);
    sorted.sort((a, b) {
      if (a.time.isEmpty && b.time.isEmpty) return 0;
      if (a.time.isEmpty) return 1;
      if (b.time.isEmpty) return -1;
      final aStart = a.time.split(' - ').first.trim();
      final bStart = b.time.split(' - ').first.trim();
      return aStart.compareTo(bStart);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<AppData>(context);
    final eventsForDay = _sortByTime(data.getEventsForDate(_selectedDate));
    final monthName = DateFormat('MMMM yyyy', 'pt_PT').format(_currentMonth);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () async {
          HapticFeedback.lightImpact();
          InteractionLogger.log('Calendário', 'CRIAR_EVENTO');
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventFormScreen(selectedDate: _selectedDate),
            ),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // Círculos decorativos canto inferior esquerdo
          Positioned(top: -75, left: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(top: -65, left: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -75, right: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -65, right: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),

          // Conteúdo principal
          Column(
            children: [
              // Cabeçalho do mês
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botão Mês Anterior com texto
                    InkWell(
                      onTap: () => _changeMonth(-1),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left),
                            Text(
                              'Mês Anterior ',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    Text(monthName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                    
                    // Botão Próximo Mês com texto
                    InkWell(
                      onTap: () => _changeMonth(1),
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_right),
                            Text(
                              'Mês Seguinte',
                              style: TextStyle(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dias da semana
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _WeekDayLabel('Seg'), _WeekDayLabel('Ter'), _WeekDayLabel('Qua'),
                    _WeekDayLabel('Qui'), _WeekDayLabel('Sex'), _WeekDayLabel('Sáb'), _WeekDayLabel('Dom'),
                  ],
                ),
              ),

              // Grelha de dias
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 280,
                  child: GridView.count(
                    crossAxisCount: 7,
                    childAspectRatio: 1,
                    children: _buildCalendarDays(data),
                  ),
                ),
              ),

              const Divider(height: 1),

              // Lista de eventos
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Eventos - ${DateFormat('dd/MM').format(_selectedDate)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Text('${eventsForDay.length} evento(s)', style: TextStyle(fontSize: 13, color: accentColor)),
                  ],
                ),
              ),

              Expanded(
                child: eventsForDay.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('Sem eventos neste dia', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: eventsForDay.length,
                        itemBuilder: (context, index) {
                          final event = eventsForDay[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: InkWell(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                InteractionLogger.log('Calendário', 'EVENTO_EDITAR', details: event.title);
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => EventFormScreen(event: event)),
                                );
                                if (result == true) {
                                  InteractionLogger.log('Calendário', 'EVENTO_EDITADO', details: event.title);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 40,
                                      decoration: BoxDecoration(color: event.color, borderRadius: BorderRadius.circular(2)),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(event.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 2),
                                            Text(event.time, style: TextStyle(color: accentColor, fontSize: 13, fontWeight: FontWeight.w500)),
                                            if (event.description.isNotEmpty)
                                              Text(event.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Chamar o diálogo de confirmação
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => _showDeleteEventConfirmation(context, event),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeekDayLabel extends StatelessWidget {
  final String label;
  const _WeekDayLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Center(
        child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
      ),
    );
  }
}