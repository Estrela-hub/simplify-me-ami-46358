import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/routine_task.dart';
import '../../models/data_provider.dart';
import '../../services/interaction_logger.dart';
import 'task_form_screen.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  static const accentColor = Color(0xFF528265);
  static const decorationColor = Color.fromRGBO(141, 232, 150, 0.56);

  // Método de confirmação para apagar tarefa
  void _showDeleteTaskConfirmation(BuildContext context, RoutineTask task) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Tarefa'),
        content: Text('Tem a certeza que quer apagar a tarefa "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final data = Provider.of<AppData>(context, listen: false);
              data.removeTask(task.id);
              Navigator.pop(ctx); // Fecha o diálogo
              InteractionLogger.log('Rotina', 'TAREFA_APAGADA', details: task.title);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tarefa apagada.'),
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

  List<RoutineTask> _sortByTime(List<RoutineTask> tasks) {
    final sorted = List<RoutineTask>.from(tasks);
    sorted.sort((a, b) {
      if (a.startTime.isEmpty && b.startTime.isEmpty) return 0;
      if (a.startTime.isEmpty) return 1;
      if (b.startTime.isEmpty) return -1;
      final aStart = a.startTime.split(' - ').first.trim();
      final bStart = b.startTime.split(' - ').first.trim();
      return aStart.compareTo(bStart);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final data = Provider.of<AppData>(context);
    final progress = data.progress;
    final completedCount = data.tasks.where((t) => t.completed).length;
    final sortedTasks = _sortByTime(data.tasks);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      floatingActionButton: FloatingActionButton(
        heroTag: 'routine_fab',
        onPressed: () async {
          HapticFeedback.lightImpact();
          InteractionLogger.log('Rotina', 'ADICIONAR_TAREFA');
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TaskFormScreen()),
          );
        },
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Stack(
        children: [
          // Círculos decorativos
          Positioned(top: -75, left: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(top: -65, left: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -75, right: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -65, right: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),

          // Conteúdo principal
          Column(
            children: [
              const SizedBox(height: 80),

              // Barra de progresso
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Progresso Diário', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        Text('$completedCount/${data.tasks.length} tarefas', style: TextStyle(fontSize: 13, color: accentColor, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: data.tasks.isEmpty ? 0 : progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(progress >= 1.0 ? const Color(0xFF10B981) : accentColor),
                      ),
                    ),
                    if (progress >= 1.0 && data.tasks.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(Icons.celebration, size: 18, color: Color(0xFFF59E0B)),
                            SizedBox(width: 6),
                            Text('Parabéns! Todas as tarefas concluídas!', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Lista de tarefas
              Expanded(
                child: sortedTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.checklist_outlined, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 8),
                            Text('Nenhuma tarefa na rotina', style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80),
                        itemCount: sortedTasks.length,
                        itemBuilder: (context, index) {
                          final task = sortedTasks[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: InkWell(
                              onTap: () async {
                                HapticFeedback.lightImpact();
                                InteractionLogger.log('Rotina', 'TAREFA_EDITAR', details: task.title);
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TaskFormScreen(task: task)),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 48,
                                      decoration: BoxDecoration(color: Color(task.colorValue), borderRadius: BorderRadius.circular(2)),
                                    ),
                                    const SizedBox(width: 12),
                                    Checkbox(
                                      value: task.completed,
                                      activeColor: accentColor,
                                      shape: const CircleBorder(),
                                      onChanged: (_) {
                                        HapticFeedback.selectionClick();
                                        InteractionLogger.log('Rotina', task.completed ? 'TAREFA_DESMARCAR' : 'TAREFA_MARCAR', details: task.title);
                                        data.toggleTask(task.id);
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            task.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              decoration: task.completed ? TextDecoration.lineThrough : null,
                                              color: task.completed ? Colors.grey : const Color(0xFF1A1A2E),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            task.startTime,
                                            style: TextStyle(
                                              color: accentColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              decoration: task.completed ? TextDecoration.lineThrough : null,
                                            ),
                                          ),
                                          if (task.description.isNotEmpty)
                                            Text(
                                              task.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: task.completed ? Colors.grey : const Color(0xFF6B7280),
                                                decoration: task.completed ? TextDecoration.lineThrough : null,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Chamar o diálogo de confirmação
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      onPressed: () => _showDeleteTaskConfirmation(context, task),
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