import 'package:flutter/foundation.dart';

abstract class AudioServiceInterface extends ChangeNotifier {
  bool get isInitialized;
  bool get isRecording;
  double get currentVolume;

  Future<bool> initialize();
  Future<bool> startRecording();
  Future<List<double>?> stopRecording();
  Future<void> cleanup();
  Stream<List<double>>? get audioStream;
}
