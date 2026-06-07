import 'package:uuid/uuid.dart';

class RoutineTask {
  final String id;
  final String title;
  final String description;
  final bool completed;
  final String startTime;
  final String endTime;
  final int colorValue;

  static final List<int> taskColors = [
    0xFF528265,
    0xFF6C63FF,
    0xFFFF6B6B,
    0xFF4ECDC4,
    0xFFFFB347,
    0xFF45B7D1,
  ];

  RoutineTask({
    String? id,
    required this.title,
    required this.description,
    this.completed = false,
    this.startTime = '',
    this.endTime = '',
    this.colorValue = 0xFF528265,
  }) : id = id ?? const Uuid().v4();

  RoutineTask copyWith({bool? completed}) {
    return RoutineTask(
      id: id,
      title: title,
      description: description,
      completed: completed ?? this.completed,
      startTime: startTime,
      endTime: endTime,
      colorValue: colorValue,
    );
  }
}