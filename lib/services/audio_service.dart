import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:record/record.dart';

class AudioService {
  // Separar players para evitar conflitos entre o temporizador e as notas de voz
  static final AudioPlayer _ambientPlayer = AudioPlayer();
  static final AudioPlayer _voicePlayer = AudioPlayer();
  static final AudioPlayer _effectPlayer = AudioPlayer();
  
  static final AudioRecorder _recorder = AudioRecorder();
  static bool _isRecording = false;
  static String? _currentRecordingPath;

  static bool get isRecording => _isRecording;
  static String? get currentRecordingPath => _currentRecordingPath;

  // Controlo de volume específico para o ambiente
  static Future<void> setAmbientVolume(double volume) async {
    await _ambientPlayer.setVolume(volume);
  }

  // Inicia a gravação de áudio.
  static Future<String?> startRecording() async {
    try {
      if (!await _recorder.hasPermission()) return null;
      
      final dir = await getTemporaryDirectory();
      _currentRecordingPath = '${dir.path}/nota_voz_${const Uuid().v4()}.m4a';
      
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      await _recorder.start(config, path: _currentRecordingPath!);
      _isRecording = true;
      return _currentRecordingPath;
    } catch (e) {
      return null;
    }
  }

  // Para a gravação e retorna o caminho do ficheiro.
  static Future<String?> stopRecording() async {
    try {
      _isRecording = false;
      final path = await _recorder.stop();
      return path ?? _currentRecordingPath;
    } catch (e) {
      return _currentRecordingPath;
    }
  }

  // Reproduz um ficheiro de áudio (Notas de Voz - usa o _voicePlayer).
  static Future<void> playAudio(String path) async {
    try {
      await _voicePlayer.stop();
      await _voicePlayer.setFilePath(path);
      await _voicePlayer.play();
    } catch (_) {}
  }

  // Para todos os áudios de forma abrupta (usado ao fechar o ecrã ou sair da app).
  static Future<void> stopAudio() async {
    try {
      await _ambientPlayer.stop();
      await _voicePlayer.stop();
      await _effectPlayer.stop();
    } catch (_) {}
  }

  // Pausa o áudio ambiente (usado no botão de Pausa do Timer).
  static Future<void> pauseAmbientAudio() async {
    await _ambientPlayer.pause();
  }

  // Retoma o áudio ambiente (usado no botão de Retomar do Timer).
  static Future<void> resumeAmbientAudio() async {
    await _ambientPlayer.play();
  }

  // Toca sons de fundo para meditação (usa o _ambientPlayer).
  static Future<void> playAmbientSound(String sound) async {
    try {
      await _ambientPlayer.stop();
      switch (sound) {
        case 'Chuva':
          await _ambientPlayer.setAsset('assets/rain.mp3');
          break;
        case 'Floresta':
          await _ambientPlayer.setAsset('assets/forest.mp3');
          break;
        case 'Oceano':
          await _ambientPlayer.setAsset('assets/ocean.mp3');
          break;
        case 'Rio':
          await _ambientPlayer.setAsset('assets/river.mp3');
          break;
        case 'Universo':
          await _ambientPlayer.setAsset('assets/universe.mp3');
          break;
        case 'Caminhada':
          await _ambientPlayer.setAsset('assets/walking.mp3');
          break;
        default:
          return;
      }
      await _ambientPlayer.setLoopMode(LoopMode.one);
      await _ambientPlayer.play();
    } catch (_) {}
  }

  // Toca o som de conclusão/gongo (usa o _effectPlayer).
  static Future<void> playCompletionSound() async {
    try {
      await _effectPlayer.stop();
      await _effectPlayer.setAsset('assets/bell.mp3');
      await _effectPlayer.play();
    } catch (_) {}
  }

  // Liberta recursos.
  static void dispose() {
    _ambientPlayer.dispose();
    _voicePlayer.dispose();
    _effectPlayer.dispose();
    _recorder.dispose();
  }
}