import 'package:flutter/material.dart';
import '../services/interaction_logger.dart';

class TestControlOverlay extends StatefulWidget {
  const TestControlOverlay({super.key});

  @override
  State<TestControlOverlay> createState() => _TestControlOverlayState();
}

class _TestControlOverlayState extends State<TestControlOverlay> {
  static const _taskNames = ['Calendário', 'Rotina', 'Temporizador', 'Notas'];
  
  // Variável para guardar o participante selecionado
  String _selectedParticipant = 'P1';

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 70,
      right: 8,
      child: FloatingActionButton.small(
        onPressed: () => _showControlPanel(context),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.science, size: 18),
      ),
    );
  }

  void _showControlPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite ao BottomSheet ocupar mais espaço se necessário
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              // Envolvido em SingleChildScrollView para nunca cortar o Dropdown
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Painel de Testes de Usabilidade',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Dropdown para selecionar o participante
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Text('Participante Atual: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          Expanded(
                            child: DropdownButton<String>(
                              value: _selectedParticipant,
                              isExpanded: true,
                              underline: const SizedBox(), // Remove a linha por baixo
                              items: const [
                                DropdownMenuItem(value: 'P1', child: Text('P1')),
                                DropdownMenuItem(value: 'P2', child: Text('P2')),
                                DropdownMenuItem(value: 'P3', child: Text('P3')),
                                DropdownMenuItem(value: 'P4', child: Text('P4')),
                                DropdownMenuItem(value: 'P5', child: Text('P5')),
                                DropdownMenuItem(value: 'P6', child: Text('P6')),
                              ],
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  InteractionLogger.setUserId(newValue);
                                  setSheetState(() {
                                    _selectedParticipant = newValue;
                                  });
                                  setState(() {
                                    _selectedParticipant = newValue;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Lista de Tarefas
                    ..._taskNames.map((task) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(task,
                                    style: const TextStyle(fontWeight: FontWeight.w500)),
                              ),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    InteractionLogger.startTask(task);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('▶ $task iniciada para $_selectedParticipant'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: const Text('Iniciar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    InteractionLogger.endTask(task);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('⏹ $task concluída para $_selectedParticipant'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                  ),
                                  child: const Text('Terminar', style: TextStyle(fontSize: 12)),
                                ),
                              ),
                            ],
                          ),
                        )),
                    
                    const Divider(),
                    
                    // Botões de controlo inferiores
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              InteractionLogger.clear();
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logs limpos')),
                              );
                            },
                            child: const Text('Limpar Tudo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              final stats = InteractionLogger.getAggregatedStats();
                              Navigator.pop(ctx);
                              _showStatsDialog(context, stats);
                            },
                            child: const Text('Ver Stats'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8), // Espaçamento final de segurança
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showStatsDialog(BuildContext context, Map<String, Map<String, dynamic>> stats) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estatísticas Agregadas'),
        content: SizedBox(
          width: double.maxFinite,
          child: stats.isEmpty
              ? const Text('Sem dados.')
              : ListView(
                  shrinkWrap: true,
                  children: stats.entries.map((entry) {
                    final s = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            _StatRow('Participantes', '${s['n_participants']}'),
                            _StatRow('Taxa sucesso', ((s['success_rate'] as double) * 100).toStringAsFixed(0)),
                            _StatRow('Duração média', (s['avg_duration_seconds'] as double).toStringAsFixed(1)),
                            _StatRow('Desvio padrão', (s['std_dev_duration'] as double).toStringAsFixed(1)),
                            _StatRow('Min-Max', '${s['min_duration']}s - ${s['max_duration']}s'),
                            _StatRow('Taps médios', (s['avg_taps'] as double).toStringAsFixed(1)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          )
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}