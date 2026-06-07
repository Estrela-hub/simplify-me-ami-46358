import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../models/data_provider.dart';
import '../../services/interaction_logger.dart';

class EventFormScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final CalendarEvent? event;

  const EventFormScreen({super.key, this.selectedDate, this.event});

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Controladores para os campos de hora
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _selectedColorIndex = 0;
  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate ?? DateTime.now();

    if (_isEditing) {
      _titleController.text = widget.event!.title;
      _descriptionController.text = widget.event!.description;
      _selectedDate = widget.event!.date;
      _selectedColorIndex =
          CalendarEvent.eventColors.indexOf(widget.event!.colorValue);
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;

      final timeStr = widget.event!.time;
      if (timeStr.isNotEmpty) {
        final parts = timeStr.split(' - ');
        if (parts.isNotEmpty && parts[0].contains(':')) {
          final sp = parts[0].trim().split(':');
          _startTime = TimeOfDay(
            hour: int.tryParse(sp[0]) ?? 9,
            minute: int.tryParse(sp[1]) ?? 0,
          );
          // Preencher o controlador ao carregar o evento
          _startTimeController.text = _formatTime(_startTime!);
        }
        if (parts.length == 2 && parts[1].contains(':')) {
          final ep = parts[1].trim().split(':');
          _endTime = TimeOfDay(
            hour: int.tryParse(ep[0]) ?? 9,
            minute: int.tryParse(ep[1]) ?? 0,
          );
          _endTimeController.text = _formatTime(_endTime!);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickDate() async {
    HapticFeedback.selectionClick();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      locale: const Locale('pt', 'PT'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context)
                .colorScheme
                .copyWith(primary: const Color(0xFF528265)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    HapticFeedback.selectionClick();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Atualizar o controlador ao selecionar
        _startTimeController.text = _formatTime(picked);
      });
    }
  }

  Future<void> _pickEndTime() async {
    HapticFeedback.selectionClick();

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? (_startTime ?? TimeOfDay.now()),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: true,
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
        _endTimeController.text = _formatTime(picked);
      });
    }
  }

  void _saveEvent() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      InteractionLogger.log(
          'Criar Evento', _isEditing ? 'EVENTO_ATUALIZADO' : 'EVENTO_GUARDADO',
          details: _titleController.text);

      final data = Provider.of<AppData>(context, listen: false);

      String timeStr = _formatTime(_startTime!);
      if (_endTime != null) {
        timeStr += ' - ${_formatTime(_endTime!)}';
      }

      if (_isEditing) {
        data.updateEvent(CalendarEvent(
          id: widget.event!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate,
          time: timeStr,
          colorValue: CalendarEvent.eventColors[_selectedColorIndex],
        ));
      } else {
        data.addEvent(CalendarEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          date: _selectedDate,
          time: timeStr,
          colorValue: CalendarEvent.eventColors[_selectedColorIndex],
        ));
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Evento atualizado com sucesso!'
              : 'Evento criado com sucesso!'),
          backgroundColor: const Color(0xFF528265),
        ),
      );
    }
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    InteractionLogger.log('Criar Evento', 'EVENTO_CANCELADO',
        details: 'Título preenchido: ${_titleController.text.isNotEmpty}');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _cancel,
        ),
        title: Text(_isEditing ? 'Editar Evento' : 'Novo Evento'),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('Cancelar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do evento *',
                prefixIcon: Icon(Icons.title_outlined),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Insira um título' : null,
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Data
            InkWell(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Data',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd/MM/yyyy', 'pt_PT').format(_selectedDate),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Hora de início usando TextFormField para validação visual
            TextFormField(
              controller: _startTimeController,
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              onTap: _pickStartTime,
              decoration: const InputDecoration(
                labelText: 'Hora de início *',
                prefixIcon: Icon(Icons.access_time_outlined),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Selecione a hora de início' : null,
            ),
            const SizedBox(height: 12),

            // Hora de fim (opcional)
            TextFormField(
              controller: _endTimeController,
              readOnly: true,
              showCursor: false,
              enableInteractiveSelection: false,
              onTap: _pickEndTime,
              decoration: InputDecoration(
                labelText: 'Hora de fim',
                prefixIcon: const Icon(Icons.access_time_filled_outlined),
                suffixIcon: _endTime != null
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            _endTime = null;
                            _endTimeController.clear(); // Limpar o controlador também
                          });
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            // Seletor de cor
            const Text(
              'Cor do evento',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                CalendarEvent.eventColors.length,
                (index) => GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedColorIndex = index);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(CalendarEvent.eventColors[index]),
                      border: _selectedColorIndex == index
                          ? Border.all(
                              color: Color(CalendarEvent.eventColors[index]).withAlpha(80),
                              width: 4)
                          : null,
                      boxShadow: _selectedColorIndex == index
                          ? [
                              BoxShadow(
                                color: Color(CalendarEvent.eventColors[index]).withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    child: _selectedColorIndex == index
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Botão guardar
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF528265),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveEvent,
              child: Text(_isEditing ? 'Guardar Alterações' : 'Guardar Evento'),
            ),
            const SizedBox(height: 12),

            // Botão cancelar
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancelar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}