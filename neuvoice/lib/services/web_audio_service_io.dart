import 'dart:async';
import 'audio_service_interface.dart';

class WebAudioService extends AudioServiceInterface {
  bool _isInitialized = false;
  bool _isRecording = false;
  double _currentVolume = 0.0;
  StreamController<List<double>>? _audioStreamController;

  @override
  bool get isInitialized => _isInitialized;
  @override
  bool get isRecording => _isRecording;
  @override
  double get currentVolume => _currentVolume;
  @override
  Stream<List<double>>? get audioStream => _audioStreamController?.stream;

  @override
  Future<bool> initialize() async {
    _isInitialized = true;
    notifyListeners();
    return true;
  }

  @override
  Future<bool> startRecording() async {
    _audioStreamController?.close();
    _audioStreamController = StreamController<List<double>>.broadcast();
    _isRecording = true;
    notifyListeners();
    return true;
  }

  @override
  Future<List<double>?> stopRecording() async {
    _isRecording = false;
    final c = _audioStreamController;
    _audioStreamController = null;
    await c?.close();
    notifyListeners();
    return null;
  }

  @override
  Future<void> cleanup() async {
    await _audioStreamController?.close();
    _audioStreamController = null;
    _isInitialized = false;
    _isRecording = false;
    _currentVolume = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    cleanup();
    super.dispose();
  }
}
