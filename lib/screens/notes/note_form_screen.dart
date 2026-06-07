import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:simplify_me/models/data_provider.dart';
import 'package:simplify_me/models/note.dart';

import '../../services/interaction_logger.dart';
import '../../services/audio_service.dart';

class NoteFormScreen extends StatefulWidget {
  final Note? existingNote;

  const NoteFormScreen({super.key, this.existingNote});

  @override
  State<NoteFormScreen> createState() => _NoteFormScreenState();
}

class _NoteFormScreenState extends State<NoteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();

  String? _imagePath;
  String? _audioPath;

  bool _isRecording = false;
  bool _imageLoading = false;
  bool _isPlaying = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool get _isEditing => widget.existingNote != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      final note = widget.existingNote!;
      _titleController.text = note.title;
      _textController.text = note.textContent;
      _imagePath = note.imagePath;
      _audioPath = note.audioPath;
    }

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        if (state.processingState == ProcessingState.completed) {
          // O stop() corta a reprodução de vez e rebobina automaticamente ao segundo 0
          _audioPlayer.stop();
          setState(() => _isPlaying = false);
        } else {
          // Para pausar/retomar normal
          setState(() => _isPlaying = state.playing);
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    _audioPlayer.dispose();
    if (_isRecording) {
      AudioService.stopRecording();
    }
    super.dispose();
  }

  void _viewFullImage(BuildContext context, String path) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _capturePhoto() async {
    HapticFeedback.lightImpact();
    InteractionLogger.log('Criar Nota', 'CÂMARA_ABRIR');

    setState(() => _imageLoading = true);

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo != null) {
        InteractionLogger.log('Criar Nota', 'FOTO_CAPTURADA', details: photo.path);
        setState(() => _imagePath = photo.path);
        HapticFeedback.mediumImpact();
      } else {
        InteractionLogger.log('Criar Nota', 'CÂMARA_CANCELADA');
      }
    } catch (e) {
      InteractionLogger.log('Criar Nota', 'CÂMARA_ERRO', details: e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao aceder à câmara: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _imageLoading = false);
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      HapticFeedback.lightImpact();
      InteractionLogger.log('Criar Nota', 'GRAVACAO_INICIAR');

      final path = await AudioService.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _audioPath = null; 
        });
        InteractionLogger.log('Criar Nota', 'GRAVACAO_ATIVA', details: path);
      } else {
        InteractionLogger.log('Criar Nota', 'GRAVACAO_PERMISSAO_NEGADA');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissão de microfone negada. Ative nas definições.')),
          );
        }
      }
    } else {
      HapticFeedback.mediumImpact();
      final path = await AudioService.stopRecording();
      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
      InteractionLogger.log('Criar Nota', 'GRAVACAO_PARADA', details: 'Ficheiro: $path');

      if (path != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nota de voz gravada!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    }
  }

  Future<void> _togglePlayAudio() async {
    if (_audioPath == null) return;

    HapticFeedback.selectionClick();

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      try {
        await _audioPlayer.setFilePath(_audioPath!);
        await _audioPlayer.play();
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Erro ao reproduzir áudio: $e')),
           );
         }
      }
    }
  }

  void _removeImage() {
    HapticFeedback.selectionClick();
    InteractionLogger.log('Criar Nota', 'IMAGEM_REMOVIDA');
    setState(() => _imagePath = null);
  }

  void _removeAudio() {
    HapticFeedback.selectionClick();
    InteractionLogger.log('Criar Nota', 'AUDIO_REMOVIDO');
    _audioPlayer.stop();
    setState(() => _audioPath = null);
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      InteractionLogger.log('Criar Nota', 'NOTA_GUARDADA',
          details: 'Título: ${_titleController.text} | Imagem: ${_imagePath != null} | Áudio: ${_audioPath != null}');

      final data = Provider.of<AppData>(context, listen: false);

      if (_isEditing) {
        final updatedNote = widget.existingNote!.copyWith(
          title: _titleController.text,
          textContent: _textController.text,
          imagePath: _imagePath,
          audioPath: _audioPath,
          updatedAt: DateTime.now(),
        );
        data.updateNote(updatedNote);
      } else {
        data.addNote(Note(
          title: _titleController.text,
          textContent: _textController.text,
          imagePath: _imagePath,
          audioPath: _audioPath,
        ));
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nota guardada com sucesso!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    }
  }

  void _cancel() {
    HapticFeedback.lightImpact();
    InteractionLogger.log('Criar Nota', 'NOTA_CANCELADA',
        details: 'Título preenchido: ${_titleController.text.isNotEmpty} | Imagem: ${_imagePath != null} | Áudio: ${_audioPath != null}');
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
        title: Text(_isEditing ? 'Editar Nota' : 'Nova Nota'),
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
                labelText: 'Título da nota',
                prefixIcon: Icon(Icons.title_outlined),
              ),
              validator: (value) => value?.isEmpty ?? true ? 'Insira um título' : null,
              onChanged: (_) => InteractionLogger.log('Criar Nota', 'PREENCHER_TITULO'),
            ),
            const SizedBox(height: 16),

            // Texto da nota
            TextFormField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Escreva a sua nota...',
                prefixIcon: Icon(Icons.edit_note_outlined),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              onChanged: (_) => InteractionLogger.log('Criar Nota', 'PREENCHER_TEXTO'),
            ),
            const SizedBox(height: 24),

            // Separador: Anexos
            const Text(
              'Anexos',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 12),

            // Botão Câmara
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF10B981)),
                ),
                title: const Text('Adicionar fotografia'),
                subtitle: const Text('Capturar imagem com a câmara', style: TextStyle(fontSize: 12)),
                trailing: _imageLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                    : null,
                onTap: _imageLoading ? null : _capturePhoto,
              ),
            ),

            // Preview da imagem
            if (_imagePath != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => _viewFullImage(context, _imagePath!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 180,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white, size: 20),
                          onPressed: _removeImage,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: const Color(0xFF10B981), borderRadius: BorderRadius.circular(8)),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('Toque para ver inteira', style: TextStyle(color: Colors.white, fontSize: 11)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Botão Gravar Áudio
            Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _isRecording ? const Color(0xFFEF4444).withAlpha(20) : const Color(0xFF4A54E8).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _isRecording ? Icons.mic : Icons.mic_none_outlined,
                    color: _isRecording ? const Color(0xFFEF4444) : const Color(0xFF4A54E8),
                  ),
                ),
                title: Text(
                  _isRecording ? 'A gravar...' : 'Gravar nota de voz',
                  style: TextStyle(
                    color: _isRecording ? const Color(0xFFEF4444) : null,
                    fontWeight: _isRecording ? FontWeight.w600 : null,
                  ),
                ),
                subtitle: Text(
                  _isRecording ? 'Toque para parar a gravação' : 'Registar uma nota de áudio',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: _isRecording ? const Icon(Icons.stop, color: Color(0xFFEF4444)) : null,
                onTap: _toggleRecording,
              ),
            ),

            // Indicador de gravação ativa
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFEF4444).withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      _RecordingIndicator(),
                      const SizedBox(height: 12),
                      const Expanded(
                        child: Text(
                          'Gravação em curso...',
                          style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Preview do áudio gravado
            if (_audioPath != null && !_isRecording)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A54E8).withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF4A54E8).withAlpha(30)),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _togglePlayAudio,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF4A54E8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Nota de voz gravada',
                          style: TextStyle(color: Color(0xFF4A54E8), fontWeight: FontWeight.w500),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFF4A54E8), size: 20),
                        onPressed: _removeAudio,
                      ),
                    ],
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
              onPressed: _saveNote,
              child: Text(_isEditing ? 'Guardar Alterações' : 'Guardar Nota'),
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

class _RecordingIndicator extends StatefulWidget {
  @override
  State<_RecordingIndicator> createState() => _RecordingIndicatorState();
}

class _RecordingIndicatorState extends State<_RecordingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 12 + _controller.value * 6,
          height: 12 + _controller.value * 6,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFFEF4444),
          ),
        );
      },
    );
  }
}