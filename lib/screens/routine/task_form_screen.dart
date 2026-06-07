import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/routine_task.dart';
import '../../models/data_provider.dart';
import '../../services/interaction_logger.dart';

class TaskFormScreen extends StatefulWidget {
  final RoutineTask? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Controladores para os campos de hora
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  int _selectedColorIndex = 0;
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedColorIndex = RoutineTask.taskColors.indexOf(widget.task!.colorValue);
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;

      if (widget.task!.startTime.isNotEmpty) {
        final parts = widget.task!.startTime.split(' - ');
        if (parts[0].contains(':')) {
          final sp = parts[0].trim().split(':');
          _startTime = TimeOfDay(
            hour: int.tryParse(sp[0]) ?? 9,
            minute: int.tryParse(sp[1]) ?? 0,
          );
          // Preencher o controlador ao carregar a tarefa
          _startTimeController.text = _formatTime(_startTime!);
        }
        if (parts.length == 2 && parts[1].contains(':')) {
          final ep = parts[1].trim().split(':');
          _endTime = TimeOfDay(
            hour: int.tryParse(ep[0]) ?? 9,
            minute: int.tryParse(ep[1]) ?? 0,
          );
          // Preencher o controlador ao carregar a tarefa
          _endTimeController.text = _formatTime(_endTime!);
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // Limpar os novos controladores
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
        // Atualizar o texto do controlador
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
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
        // Atualizar o texto do controlador
        _endTimeController.text = _formatTime(picked);
      });
    }
  }

  void _saveTask() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      InteractionLogger.log(
          'Criar Tarefa', _isEditing ? 'TAREFA_ATUALIZADA' : 'TAREFA_GUARDADA',
          details: _titleController.text);

      final data = Provider.of<AppData>(context, listen: false);

      String timeStr = _formatTime(_startTime!);
      if (_endTime != null) {
        timeStr += ' - ${_formatTime(_endTime!)}';
      }

      if (_isEditing) {
        data.updateTask(RoutineTask(
          id: widget.task!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          completed: widget.task!.completed,
          startTime: timeStr,
          endTime: _endTime != null ? _formatTime(_endTime!) : '',
          colorValue: RoutineTask.taskColors[_selectedColorIndex],
        ));
      } else {
        data.addTask(RoutineTask(
          title: _titleController.text,
          description: _descriptionController.text,
          startTime: timeStr,
          endTime: _endTime != null ? _formatTime(_endTime!) : '',
          colorValue: RoutineTask.taskColors[_selectedColorIndex],
        ));
      }

      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing
              ? 'Tarefa atualizada com sucesso!'
              : 'Tarefa adicionada à rotina!'),
          backgroundColor: const Color(0xFF528265),
        ),
      );
    }
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    InteractionLogger.log('Criar Tarefa', 'TAREFA_CANCELADA',
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
        title: Text(_isEditing ? 'Editar Tarefa' : 'Nova Tarefa'),
        actions: [
          TextButton(onPressed: _cancel, child: const Text('Cancelar')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ícone decorativo
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF528265).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.task_alt_outlined,
                    size: 32, color: Color(0xFF528265)),
              ),
            ),
            const SizedBox(height: 24),

            // Título
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Nome da tarefa *',
                prefixIcon: Icon(Icons.label_outlined),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Insira o nome da tarefa' : null,
            ),
            const SizedBox(height: 16),

            // Descrição
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Hora de início usando TextFormField (igual ao EventForm)
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

            // Hora de fim usando TextFormField para ser consistente
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
              'Cor da tarefa',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(
                RoutineTask.taskColors.length,
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
                      color: Color(RoutineTask.taskColors[index]),
                      border: _selectedColorIndex == index
                          ? Border.all(
                              color: Color(RoutineTask.taskColors[index])
                                  .withAlpha(80),
                              width: 4)
                          : null,
                      boxShadow: _selectedColorIndex == index
                          ? [
                              BoxShadow(
                                color: Color(RoutineTask.taskColors[index])
                                    .withAlpha(60),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveTask,
              child: Text(_isEditing ? 'Guardar Alterações' : 'Adicionar à Rotina'),
            ),
            const SizedBox(height: 12),

            // Botão cancelar
            OutlinedButton(
              onPressed: _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEF4444),
                side: const BorderSide(color: Color(0xFFEF4444)),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
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