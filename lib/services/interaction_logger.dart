import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Sistema de logging de interações para testes de usabilidade.
// Regista todas as ações do utilizador com timestamps para análise quantitativa.
class InteractionLog {
  final String userId;
  final DateTime timestamp;
  final String screen;
  final String action;
  final String? details;

  InteractionLog({
    required this.userId,
    required this.timestamp,
    required this.screen,
    required this.action,
    this.details,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'screen': screen,
        'action': action,
        'details': details,
      };

  @override
  String toString() =>
      '[$userId][${timestamp.toIso8601String()}] $screen | $action${details != null ? ' | $details' : ''}';
}

class InteractionLogger {
  static final List<InteractionLog> _logs = [];
  static final Map<String, DateTime> _taskStartTimes = {};
  static final Map<String, int> _taskTapCounts = {};
  static final Map<String, List<String>> _taskScreensVisited = {};

  static String _currentUserId = 'P1';

  // Define o ID do utilizador atual (ex: P1, P2)
  static void setUserId(String id) {
    _currentUserId = id;
  }

  // Regista interação
  static void log(String screen, String action, {String? details}) {
    final entry = InteractionLog(
      userId: _currentUserId,
      timestamp: DateTime.now(),
      screen: screen,
      action: action,
      details: details,
    );

    _logs.add(entry);

    _appendLogToFile(entry);

    for (final task in _taskStartTimes.keys) {
      _taskTapCounts[task] = (_taskTapCounts[task] ?? 0) + 1;
      _taskScreensVisited.putIfAbsent(task, () => []);
      if (!_taskScreensVisited[task]!.contains(screen)) {
        _taskScreensVisited[task]!.add(screen);
      }
    }
  }

  // Start task
  static void startTask(String taskName) {
    _taskStartTimes[taskName] = DateTime.now();
    _taskTapCounts[taskName] = 0;
    _taskScreensVisited[taskName] = [];
    log('Sistema', 'TAREFA_INICIADA', details: taskName);
  }

  // End task
  static void endTask(String taskName, {bool success = true}) {
    final start = _taskStartTimes[taskName];
    if (start == null) return;

    final duration = DateTime.now().difference(start);

    log(
      'Sistema',
      'TAREFA_CONCLUIDA',
      details:
          '$taskName | Sucesso: $success | Duração: ${duration.inSeconds}s | Taps: ${_taskTapCounts[taskName]} | Ecrãs visitados: ${_taskScreensVisited[taskName]?.length ?? 0}',
    );

    _taskStartTimes.remove(taskName);
  }

  // Logs em memória
  static List<InteractionLog> getLogs() => List.unmodifiable(_logs);

  // CSV 

  static Future<void> _appendLogToFile(InteractionLog logEntry) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/usability_logs.csv');

      final csv =
          '${logEntry.userId},${logEntry.timestamp.toIso8601String()},${logEntry.screen},${logEntry.action},"${logEntry.details ?? ''}"\n';

      if (!await file.exists()) {
        await file.writeAsString(
          'user_id,timestamp,screen,action,details\n',
        );
      }

      await file.writeAsString(csv, mode: FileMode.append);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Erro CSV log: $e');
      }
    }
  }

  static Future<File> getLogFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/usability_logs.csv');
  }

  //  STATS

  static List<Map<String, dynamic>> getTaskStatistics() {
    final result = <Map<String, dynamic>>[];

    final completed = _logs
        .where((l) => l.action == 'TAREFA_CONCLUIDA')
        .toList();

    for (final log in completed) {
      final parts = log.details?.split(' | ') ?? [];
      final task = parts.isNotEmpty ? parts[0] : 'Desconhecida';
      final success = parts.length > 1 && parts[1].contains('true');

      final duration = parts.length > 2
          ? int.tryParse(parts[2].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
          : 0;

      final taps = parts.length > 3
          ? int.tryParse(parts[3].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
          : 0;

      final screens = parts.length > 4
          ? int.tryParse(parts[4].replaceAll(RegExp(r'[^0-9]'), '')) ?? 0
          : 0;

      result.add({
        'task': task,
        'success': success,
        'duration_seconds': duration,
        'taps': taps,
        'screens_visited': screens,
        'timestamp': log.timestamp.toIso8601String(),
      });
    }

    return result;
  }

  static Map<String, Map<String, dynamic>> getAggregatedStats() {
    final grouped = <String, List<Map<String, dynamic>>>{};

    for (final t in getTaskStatistics()) {
      grouped.putIfAbsent(t['task'], () => []).add(t);
    }

    final result = <String, Map<String, dynamic>>{};

    for (final entry in grouped.entries) {
      final tasks = entry.value;

      final durations = tasks.map((e) => e['duration_seconds'] as int).toList();
      final taps = tasks.map((e) => e['taps'] as int).toList();

      final avg = durations.isEmpty
          ? 0.0
          : durations.reduce((a, b) => a + b) / durations.length;

      final variance = durations.isEmpty
          ? 0.0
          : durations
                  .map((d) => (d - avg) * (d - avg))
                  .reduce((a, b) => a + b) /
              durations.length;

      result[entry.key] = {
        'n_participants': tasks.length,
        'success_rate':
            tasks.where((t) => t['success'] == true).length / tasks.length,
        'avg_duration_seconds': avg,
        'std_dev_duration': sqrt(variance),
        'min_duration': durations.isEmpty ? 0 : durations.reduce(min),
        'max_duration': durations.isEmpty ? 0 : durations.reduce(max),
        'avg_taps': taps.isEmpty
            ? 0.0
            : taps.reduce((a, b) => a + b) / taps.length,
      };
    }

    return result;
  }

  static double sqrt(double x) {
    if (x <= 0) return 0;
    return _sqrt(x, x / 2, 0);
  }

  static double _sqrt(double x, double guess, int i) {
    if (i > 100) return guess;
    final next = (guess + x / guess) / 2;
    if ((next - guess).abs() < 0.0001) return next;
    return _sqrt(x, next, i + 1);
  }

  // Export logs
  static String exportLogs() {
    final buffer = StringBuffer();

    buffer.writeln('=== LOGS ===');
    for (final log in _logs) {
      buffer.writeln(log.toString());
    }

    return buffer.toString();
  }

  static void clear() {
    _logs.clear();
    _taskStartTimes.clear();
    _taskTapCounts.clear();
    _taskScreensVisited.clear();
  }
}