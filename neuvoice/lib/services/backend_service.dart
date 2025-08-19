// lib/services/backend_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';

class BackendService extends ChangeNotifier {
  static const String baseUrl =
      'https://aware-national-bull.ngrok-free.app'; // Your Pi coordinator IP:port
  static BackendService? _instance;
  static BackendService get instance => _instance ??= BackendService._();

  bool _isConnected = false;
  bool _isDownloadingModel = false;
  double _downloadProgress = 0.0;

  bool get isConnected => _isConnected;
  bool get isDownloadingModel => _isDownloadingModel;
  double get downloadProgress => _downloadProgress;
  Timer? _statusTimer;
  BackendService._() {
    _startPeriodicStatusCheck();
  }

  void _startPeriodicStatusCheck() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      try {
        debugPrint('🔄 Periodic status check...');
        await _checkConnection();
        if (!_isConnected) {
          _setConnectionState(true, false, 1.0);
          debugPrint('✅ Periodic check: Pi coordinator reachable');
        }
      } catch (e) {
        if (_isConnected) {
          _setConnectionState(false, false, 0.0);
          debugPrint('❌ Periodic check: Pi coordinator unreachable');
        }
      }
    });
  }

  /// Check connection to Pi coordinator and download latest model
  /// Check connection to Pi coordinator and download latest model
  Future<void> connectAndUpdateModel() async {
    try {
      // ✅ CRITICAL FIX: Set initial connecting state
      _setConnectionState(false, true, 0.0);
      debugPrint('🔄 Setting connection state: connecting...');

      debugPrint('🔍 Testing Pi coordinator connection...');
      await _checkConnection();
      debugPrint('✅ Pi coordinator is reachable');

      // ✅ Update state immediately after successful connection test
      _setConnectionState(true, true, 0.0);
      debugPrint('🔄 Setting connection state: connected, checking updates...');

      debugPrint('🔍 Checking model version...');
      final needsUpdate = await _checkModelVersion();
      debugPrint('📋 Model update needed: $needsUpdate');

      if (needsUpdate) {
        debugPrint('📥 Starting model download...');
        await _downloadModelWithProgress();
        debugPrint('✅ Model download completed');
      } else {
        debugPrint('ℹ️ Model is already up to date');
      }

      // ✅ CRITICAL FIX: Ensure final connected state is set with small delay
      _setConnectionState(true, false, 1.0);
      debugPrint('🔄 Final connection state: connected, ready');

      // ✅ Force additional notification to ensure UI updates
      await Future.delayed(const Duration(milliseconds: 100));
      notifyListeners();
      debugPrint('🔄 Additional UI notification sent');
    } catch (e) {
      debugPrint('❌ connectAndUpdateModel failed: $e');
      _setConnectionState(false, false, 0.0);
      debugPrint('🔄 Setting connection state: disconnected due to error');
      rethrow;
    }
  }

  void _setConnectionState(bool connected, bool downloading, double progress) {
    final wasConnected = _isConnected;
    final wasDownloading = _isDownloadingModel;

    _isConnected = connected;
    _isDownloadingModel = downloading;
    _downloadProgress = progress;

    // ✅ Add logging to track state changes
    debugPrint(
        '🔄 State change: connected=$connected (was $wasConnected), downloading=$downloading (was $wasDownloading), progress=${(progress * 100).toStringAsFixed(1)}%');

    notifyListeners();
  }

  Future<void> _checkConnection() async {
    // ✅ FIX: Use Future.timeout() wrapper instead of invalid timeout parameter
    final response = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception('Pi coordinator not reachable: ${response.statusCode}');
    }
  }

  Future<bool> _checkModelVersion() async {
    try {
      // Check if local model file exists first
      final dir = await getApplicationDocumentsDirectory();
      final appDir = Directory('${dir.path}${Platform.pathSeparator}NeuVoice');
      final modelFile =
          File('${appDir.path}${Platform.pathSeparator}speech_model.onnx');

      if (!await modelFile.exists()) {
        debugPrint('📂 Local model file does not exist - forcing download');
        return true; // Force download
      }

      // Get server version
      final response = await http
          .get(Uri.parse('$baseUrl/models/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        debugPrint('⚠️ Failed to get server version - forcing download');
        return true;
      }

      final serverVersion = response.body.trim();
      debugPrint('📄 Server model version: $serverVersion');

      // Check local version
      final localVersion = await _getLocalModelVersion();
      debugPrint('📄 Local model version: $localVersion');

      final needsUpdate = serverVersion != localVersion;
      debugPrint('🔄 Update needed: $needsUpdate');

      return needsUpdate;
    } catch (e) {
      debugPrint('⚠️ Version check failed: $e - forcing download');
      return true; // Download if check fails
    }
  }

  Future<String> _getLocalModelVersion() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final versionFile = File('${dir.path}/model_version.txt');
      if (await versionFile.exists()) {
        return await versionFile.readAsString();
      }
    } catch (e) {
      debugPrint('No local model version found');
    }
    return '';
  }

  Future<void> _downloadModelWithProgress() async {
    debugPrint('📥 Starting model download process...');

    final request = http.Request('GET', Uri.parse('$baseUrl/models/latest'));
    final client = http.Client();

    debugPrint('🌐 Sending request to: $baseUrl/models/latest');

    final response =
        await client.send(request).timeout(const Duration(seconds: 30));

    debugPrint('📡 Response status: ${response.statusCode}');

    if (response.statusCode != 200) {
      throw Exception('Model download failed: ${response.statusCode}');
    }

    final contentLength = response.contentLength ?? 0;
    debugPrint('📊 Content length: $contentLength bytes');

    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}${Platform.pathSeparator}NeuVoice');

    debugPrint('📁 Creating directory: ${appDir.path}');
    await appDir.create(recursive: true);

    final modelFile =
        File('${appDir.path}${Platform.pathSeparator}speech_model.onnx');
    debugPrint('💾 Target file path: ${modelFile.path}');

    final sink = modelFile.openWrite();
    int bytesReceived = 0;

    try {
      debugPrint('🔄 Starting to receive data stream...');
      await for (final chunk in response.stream) {
        bytesReceived += chunk.length;
        sink.add(chunk);

        if (contentLength > 0) {
          final progress = bytesReceived / contentLength;
          _setConnectionState(_isConnected, true, progress);
          debugPrint(
              '⬇️ Downloaded: $bytesReceived/$contentLength bytes (${(progress * 100).toStringAsFixed(1)}%)');
        } else {
          debugPrint('⬇️ Downloaded: $bytesReceived bytes');
        }
      }
    } finally {
      await sink.flush();
      await sink.close();
      client.close();
    }

    // ✅ CRITICAL: Verify file was created and has content
    if (await modelFile.exists()) {
      final fileSize = await modelFile.length();
      debugPrint(
          '✅ Model download completed: ${modelFile.path} ($fileSize bytes)');

      if (fileSize == 0) {
        await modelFile.delete();
        throw Exception('Downloaded model file is empty');
      }
    } else {
      throw Exception('Model file was not created after download');
    }

    await _saveModelVersion();
  }

  Future<void> _saveModelVersion() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/models/version'))
          .timeout(const Duration(seconds: 5));
      final version = response.body.trim();

      final dir = await getApplicationDocumentsDirectory();
      final versionFile = File('${dir.path}/model_version.txt');
      await versionFile.writeAsString(version);
    } catch (e) {
      debugPrint('Failed to save model version: $e');
    }
  }

  /// Submit training example to Pi coordinator
  Future<void> submitTrainingExample({
    required String sessionId,
    required List<List<double>> melFeatures,
    required String transcript,
    double confidence = 0.0,
  }) async {
    if (!_isConnected) return;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/training/submit'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'session_id': sessionId,
              'mel_features': melFeatures,
              'transcript': transcript,
              'timestamp': DateTime.now().toIso8601String(),
              'confidence': confidence,
            }),
          )
          .timeout(const Duration(seconds: 15)); // ✅ FIX: Add timeout wrapper

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to submit training data: ${response.statusCode}');
      }

      debugPrint('✅ Training data submitted to Pi coordinator');
    } catch (e) {
      debugPrint('❌ Training data submission failed: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }
}
