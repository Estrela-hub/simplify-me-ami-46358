import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final int colorValue;

  CalendarEvent({
    String? id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.colorValue = 0xFF4A54E8,
  }) : id = id ?? const Uuid().v4();

  Color get color => Color(colorValue);

  static final List<int> eventColors = [
    0xFF528265,
    0xFF6C63FF,
    0xFFFF6B6B,
    0xFF4ECDC4,
    0xFFFFB347,
    0xFF45B7D1,
  ];
}