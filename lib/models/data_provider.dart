import 'package:flutter/material.dart';
import '../models/calendar_event.dart';
import '../models/routine_task.dart';
import '../models/note.dart';

class AppData extends ChangeNotifier {
  final List<CalendarEvent> _events = [];
  final List<RoutineTask> _tasks = [];
  final List<Note> _notes = [];

  // Eventos 
  List<CalendarEvent> get events => _events;

  List<CalendarEvent> getEventsForDate(DateTime date) {
    return _events
        .where((e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day)
        .toList();
  }

  void addEvent(CalendarEvent event) {
    _events.add(event);
    notifyListeners();
  }

  void removeEvent(String id) {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void updateEvent(CalendarEvent updatedEvent) {
    final index = _events.indexWhere((e) => e.id == updatedEvent.id);
    if (index != -1) {
      _events[index] = updatedEvent;
      notifyListeners();
    }
  }

  // Tarefas de Rotina
  List<RoutineTask> get tasks => _tasks;

  double get progress {
    if (_tasks.isEmpty) return 0;
    return _tasks.where((t) => t.completed).length / _tasks.length;
  }

  void addTask(RoutineTask task) {
    _tasks.add(task);
    notifyListeners();
  }

  void toggleTask(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(completed: !_tasks[index].completed);
      notifyListeners();
    }
  }

  void updateTask(RoutineTask updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void removeTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Notas
  List<Note> get notes => _notes;

  void addNote(Note note) {
    _notes.add(note);
    notifyListeners();
  }

  void removeNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  void updateNote(Note updatedNote) {
    final index = _notes.indexWhere((n) => n.id == updatedNote.id);

    if (index != -1) {
      _notes[index] = updatedNote;
      notifyListeners();
    }
  }
}