import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app_theme.dart';
import '../../models/data_provider.dart';
import '../../services/interaction_logger.dart';
import '../../models/note.dart';
import 'note_form_screen.dart';

class NotesScreen extends StatelessWidget {
  final VoidCallback onBack;

  const NotesScreen({
    super.key,
    required this.onBack,
  });

  static const accentColor = Color(0xFF528265);
  static const decorationColor = Color.fromRGBO(141, 232, 150, 0.56);

  // Função que mostra o diálogo de confirmação antes de apagar
  void _showDeleteConfirmation(BuildContext context, Note note) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Nota'),
        content: Text('Tem a certeza que quer apagar a nota "${note.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final data = Provider.of<AppData>(context, listen: false);
              data.removeNote(note.id);
              Navigator.pop(ctx); // Fecha o diálogo
              InteractionLogger.log('Notas', 'NOTA_APAGADA', details: note.title);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Nota apagada.'),
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
  Widget build(BuildContext context) {
    final data = Provider.of<AppData>(context);
    final notes = List<Note>.from(data.notes);

    notes.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt;
      final bDate = b.updatedAt ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: const Text(
          'Notas',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'notes_fab',
        backgroundColor: accentColor,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () async {
          HapticFeedback.lightImpact();
          InteractionLogger.log('Notas', 'CRIAR_NOTA');

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NoteFormScreen(),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          // Círculos decorativos
          Positioned(top: -75, left: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(top: -65, left: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -75, right: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -65, right: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),

          notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.note_add_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhuma nota criada',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                )
              : _buildNotesGrid(context, notes),
        ],
      ),
    );
  }

  Widget _buildNotesGrid(BuildContext context, List<Note> notes) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.85,
        padding: const EdgeInsets.only(bottom: 16),
        children: notes.map((note) {
          return GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              InteractionLogger.log('Notas', 'NOTA_ABRIR', details: note.title);

              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NoteFormScreen(existingNote: note),
                ),
              );
            },
            // Usar Stack para por o icone de apagar por cima do cartão
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (note.imagePath != null)
                            const Padding(
                              padding: EdgeInsets.only(right: 6),
                              child: Icon(Icons.photo_outlined, size: 16, color: Color(0xFF10B981)),
                            ),
                          if (note.audioPath != null)
                            const Icon(Icons.mic_outlined, size: 16, color: Color(0xFF528265)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(note.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(note.textContent, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                      const SizedBox(height: 6),
                      Text(_formatDate(note.updatedAt ?? note.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                ),
                // BOTÃO APAGAR NO CANTO SUPERIOR DIREITO
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _showDeleteConfirmation(context, note),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}