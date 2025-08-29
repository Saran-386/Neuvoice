import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
// [NOTE] This code uses the 'onnxruntime' package API
import 'package:onnxruntime/onnxruntime.dart';
import '../utils/audio_utils.dart';
import '../services/backend_service.dart';

class MobileAudioService extends ChangeNotifier {
  static MobileAudioService? _instance;
  static MobileAudioService get instance =>
      _instance ??= MobileAudioService._();

  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  String? _tempFilePath;
  OrtSession? _onnxSession;
  String? _lastTranscript;

  bool _isInitialized = false;
  bool _isInitializing = false;
  Completer<void>? _initCompleter;

  bool get isRecording => _isRecording;
  String? get lastTranscript => _lastTranscript;
  bool get isInitialized => _isInitialized;

  MobileAudioService._();

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isInitializing) return _initCompleter?.future;
    _isInitializing = true;
    _initCompleter = Completer<void>();
    try {
      debugPrint('🚀 Starting MobileAudioService initialization...');
      OrtEnv.instance.init();
      try {
        await BackendService.instance.connectAndUpdateModel();
        await _loadLocalModel();
        debugPrint('✅ Initialized with Pi model');
      } catch (e) {
        debugPrint(
            '❌ Coordinator unavailable: $e. Falling back to asset model...');
        await _loadAssetModel();
        debugPrint('✅ Initialized with asset model');
      }
      _isInitialized = true;
      _initCompleter!.complete();
      debugPrint('🎉 MobileAudioService initialization complete');
    } catch (e) {
      debugPrint('❌ Initialization failed: $e');
      _initCompleter!.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> _loadLocalModel() async {
    final dir = await getApplicationDocumentsDirectory();
    final modelFile = File('${dir.path}/NeuVoice/speech_model.onnx');
    if (!await modelFile.exists()) {
      throw Exception('Local ONNX model file not found');
    }
    final modelBytes = await modelFile.readAsBytes();
    _onnxSession = OrtSession.fromBuffer(modelBytes, OrtSessionOptions());
    debugPrint('✅ Loaded local ONNX model');
  }

  Future<void> _loadAssetModel() async {
    final byteData = await rootBundle.load('assets/models/model.onnx');
    final modelBytes = byteData.buffer.asUint8List();
    _onnxSession = OrtSession.fromBuffer(modelBytes, OrtSessionOptions());
    debugPrint('✅ Loaded asset ONNX model');
  }

  Future<void> startRecording() async {
    if (_onnxSession == null) throw Exception('Model not loaded');
    if (!await _recorder.hasPermission()) {
      throw Exception('Mic permission denied');
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'rec_${DateTime.now().millisecondsSinceEpoch}.wav';
    _tempFilePath = '${dir.path}${Platform.pathSeparator}$fileName';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        bitRate: 128000,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: _tempFilePath!,
    );
    _isRecording = true;
    notifyListeners();
  }

  Future<void> stopRecording(String sessionId) async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    _isRecording = false;
    notifyListeners();

    if (path != null) {
      final samples = await AudioUtils.loadWavAsFloat32(path);
      final transcript = await _transcribe(samples);
      _lastTranscript = transcript;
      debugPrint('🔥 Transcript: $transcript');
      notifyListeners();
      // ... your logic for submitting training data ...
    }
  }

  Future<String> _transcribe(List<double> audioSamples) async {
    if (_onnxSession == null) throw Exception('Model not initialized');

    final melSpec = AudioUtils.extractMelSpectrogram(audioSamples);
    if (melSpec.isEmpty || melSpec.first.isEmpty) return '';

    final flattened = melSpec.expand((e) => e).toList();
    final floatData = Float32List.fromList(flattened);
    final shape = [1, melSpec.length, melSpec.first.length, 1];
    final inputTensor =
        OrtValueTensor.createTensorWithDataList(floatData, shape);

    try {
      final outputs = _onnxSession!.run(
        OrtRunOptions(),
        {'mel_input': inputTensor},
      );

      if (outputs.isEmpty || outputs[0] == null) {
        return '';
      }

      final outputValue = outputs[0]!.value;

      // --- THE FIX IS HERE ---
      // The output from the model is a 3D list like List<List<List<double>>>
      // We need to flatten it into a 1D list (List<double>) for your CTC decoder.
      if (outputValue is List) {
        final flatLogits = outputValue
            .expand((e) => e as List)
            .expand((e) => e as List)
            .map((e) => e as double)
            .toList();

        final transcript = AudioUtils.ctcGreedyDecode(flatLogits);
        return transcript;
      }
      // --- END OF FIX ---

      return '';
    } catch (e) {
      debugPrint('❌ ONNX inference error: $e');
      return '';
    } finally {
      inputTensor.release();
    }
  }

  @override
  void dispose() {
    _onnxSession?.release();
    _recorder.dispose();
    super.dispose();
  }
}
