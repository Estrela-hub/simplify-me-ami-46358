import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/audio_service.dart';
import '../../services/interaction_logger.dart';

enum TimerState { setup, running, paused }

class TimerScreen extends StatefulWidget {
  final VoidCallback onBack;
  const TimerScreen({required this.onBack, super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  TimerState _state = TimerState.setup;
  
  int _selectedHours = 0;
  int _selectedMinutes = 5;
  int _selectedSeconds = 0;
  
  int _remainingSeconds = 300;
  Timer? _timer;
  bool _sessionCompleted = false;
  
  static const decorationColor = Color.fromRGBO(141, 232, 150, 0.56);
  String _selectedSound = 'Nenhum';
  double _volume = 0.5;

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.stopAudio();
    super.dispose();
  }

  String _formatDuration(int totalSeconds) {
    if (_sessionCompleted) {
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      final s = totalSeconds % 60;
      return '+${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    } else {
      final h = totalSeconds ~/ 3600;
      final m = (totalSeconds % 3600) ~/ 60;
      final s = totalSeconds % 60;
      if (h > 0) {
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }
      return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
  }

  String _getSetupDurationText() {
    String h = _selectedHours.toString().padLeft(2, '0');
    String m = _selectedMinutes.toString().padLeft(2, '0');
    String s = _selectedSeconds.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  // Timer Control
  void _startTimer() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    
    _remainingSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;
    _sessionCompleted = false;

    if (_selectedSound != 'Nenhum') {
      AudioService.playAmbientSound(_selectedSound);
      AudioService.setAmbientVolume(_volume);
    }

    InteractionLogger.log(
      'Temporizador', 'INICIAR',
      details: 'Duração: ${_getSetupDurationText()} | Som: $_selectedSound | Volume: $_volume',
    );

    setState(() => _state = TimerState.running);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_sessionCompleted) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          // Atingiu o zero! Objetivo concluído.
          setState(() => _sessionCompleted = true);
          AudioService.playCompletionSound(); // O GONGO TOCA AQUI E SÓ AQUI
          HapticFeedback.vibrate();
          InteractionLogger.log('Temporizador', 'OBJETIVO_CONCLUIDO');
        }
      } else {
        setState(() => _remainingSeconds++);
      }
    });
  }

  void _pauseTimer() {
    HapticFeedback.lightImpact();
    _timer?.cancel();
    _timer = null;
    AudioService.pauseAmbientAudio();
    InteractionLogger.log('Temporizador', 'PAUSAR', details: 'Tempo restante: $_remainingSeconds');
    setState(() => _state = TimerState.paused);
  }

  void _resumeTimer() {
    HapticFeedback.lightImpact();
    AudioService.resumeAmbientAudio();
    InteractionLogger.log('Temporizador', 'RETOMAR', details: 'Tempo restante: $_remainingSeconds');
    setState(() => _state = TimerState.running);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_sessionCompleted) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          setState(() => _sessionCompleted = true);
          AudioService.playCompletionSound(); // O GONGO TOCA AQUI E SÓ AQUI
          HapticFeedback.vibrate();
        }
      } else {
        setState(() => _remainingSeconds++);
      }
    });
  }

  // Termina a sessão de forma limpa, sem soar o gongo
  void _endSession() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();
    _timer = null;
    
    AudioService.stopAudio(); // Corta todo o som (ambiente e efeitos)
    
    InteractionLogger.log('Temporizador', 'SESSAO_TERMINADA');
    
    setState(() {
      _state = TimerState.setup;
      _sessionCompleted = false;
      _remainingSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;
    });
  }

  // Popup de confirmação
  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Cancelar Temporizador', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Tens a certeza que queres cancelar a sessão?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), // Fecha o popup
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop(); // Fecha o popup
                _endSession(); // Executa o cancelamento limpo
              },
              child: const Text('Sim', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _handleBack() {
    switch (_state) {
      case TimerState.setup:
        widget.onBack();
        break;
      case TimerState.running:
      case TimerState.paused:
        _showCancelConfirmation(); // Mostra o popup em vez de cancelar logo
        break;
    }
  }

  // User interface
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        title: const Text(
          'Temporizador',
          style: TextStyle(color: Color(0xFF1A1A2E), fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -75, left: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(top: -65, left: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -75, right: -75, child: Container(width: 160, height: 160, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          Positioned(bottom: -65, right: 20, child: Container(width: 140, height: 140, decoration: const BoxDecoration(shape: BoxShape.circle, color: decorationColor))),
          
          _buildCurrentScreen(),
        ],
      ),
    );
  }

  Widget _buildCurrentScreen() {
    switch (_state) {
      case TimerState.setup:
        return _buildSetupScreen();
      case TimerState.running:
        return _buildTimerView(
          // Se já completou, para diretamente. Se não, mostra popup.
          button1: _buildCircleActionButton(
            icon: Icons.stop, 
            label: 'Parar', 
            onTap: _sessionCompleted ? _endSession : _showCancelConfirmation
          ),
          button2: _buildCircleActionButton(icon: Icons.pause, label: 'Pausa', onTap: _pauseTimer),
        );
      case TimerState.paused:
        return _buildTimerView(
          // Em pausa, nunca completou, logo mostra sempre popup.
          button1: _buildCircleActionButton(
            icon: Icons.stop, 
            label: 'Parar', 
            onTap: _showCancelConfirmation
          ),
          button2: _buildCircleActionButton(icon: Icons.play_arrow, label: 'Retomar', onTap: _resumeTimer),
        );
    }
  }

  Widget _buildSetupScreen() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          const Spacer(flex: 2),
          _buildOptionButton(text: 'Duração (${_getSetupDurationText()})', onTap: _showDurationSelector),
          const SizedBox(height: 48),
          _buildOptionButton(text: 'Som ambiente ($_selectedSound)', onTap: _showSoundSelector),
          const SizedBox(height: 48),
          _buildOptionButton(text: 'Volume ambiente', onTap: _showVolumeSelector),
          const SizedBox(height: 48),
          _buildPlayButton(),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTimerView({required Widget button1, required Widget button2}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_sessionCompleted)
          const Padding(
            padding: EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Parabéns! Objetivo concluído.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
              textAlign: TextAlign.center,
            ),
          ),
        
        Text(
          _formatDuration(_remainingSeconds),
          style: const TextStyle(
            fontSize: 54,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        
        const SizedBox(height: 50),
        
        Row(
          mainAxisAlignment: _sessionCompleted ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
          children: [
            button1,
            if (!_sessionCompleted) button2,
          ],
        ),
      ],
    );
  }

  // Helpers
  Widget _buildOptionButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(foregroundColor: Colors.black54),
        child: Text(text, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildPlayButton() {
    return GestureDetector(
      onTap: _startTimer,
      child: Column(
        children: const [
          Icon(Icons.play_circle_outline, size: 72, color: Color(0xFF1A1A2E)),
          SizedBox(height: 8),
          Text('Iniciar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(width: 2, color: Colors.black54),
            ),
            child: Icon(icon, size: 36, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ],
      ),
    );
  }


  // Bottom sheets para seleção de duração, som e volume

  void _showDurationSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          height: 300,
          color: Colors.white,
          child: CupertinoTheme(
            data: const CupertinoThemeData(brightness: Brightness.light),
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hms,
              initialTimerDuration: Duration(
                hours: _selectedHours,
                minutes: _selectedMinutes,
                seconds: _selectedSeconds,
              ),
              onTimerDurationChanged: (Duration changedDuration) {
                setState(() {
                  _selectedHours = changedDuration.inHours;
                  _selectedMinutes = changedDuration.inMinutes % 60;
                  _selectedSeconds = changedDuration.inSeconds % 60;
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _showSoundSelector() {
    final sounds = ['Nenhum', 'Chuva', 'Floresta', 'Oceano', 'Rio', 'Universo', 'Caminhada'];
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: sounds.map((sound) {
            return ListTile(
              title: Text(sound),
              onTap: () {
                setState(() => _selectedSound = sound);
                Navigator.pop(context);
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showVolumeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Volume do Som Ambiente', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    onChanged: (value) {
                      setModalState(() => _volume = value);
                      setState(() {});
                      AudioService.setAmbientVolume(value); 
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}