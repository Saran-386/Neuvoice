import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'audio_service_interface.dart';
import '../utils/constants.dart';
import 'audio_converter.dart';

class RealtimeAudioService extends ChangeNotifier {
  final AudioServiceInterface _audioService;
  WebSocketChannel? _wsChannel;
  bool _isStreaming = false;
  StreamSubscription? _audioSubscription;

  RealtimeAudioService(this._audioService);

  bool get isStreaming => _isStreaming;

  Future<bool> startStreaming({
    required Function(String) onTranscription,
    Function(String)? onError,
  }) async {
    try {
      debugPrint('🌊 Starting realtime streaming...');

      // Connect WebSocket
      _wsChannel = WebSocketChannel.connect(
        Uri.parse('${AppConstants.piServerUrl.replaceFirst('http', 'ws')}/ws'),
      );

      // Listen for transcriptions
      _wsChannel!.stream.listen(
        (data) {
          try {
            final result = data as Map<String, dynamic>;
            if (result['text'] != null) {
              onTranscription(result['text']);
            }
          } catch (e) {
            onError?.call('WebSocket data error: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ WebSocket error: $error');
          onError?.call('Connection lost');
          stopStreaming();
        },
      );

      // Start audio recording
      if (!await _audioService.startRecording()) {
        throw Exception('Failed to start audio recording');
      }

      // Subscribe to audio stream
      _audioSubscription = _audioService.audioStream?.listen((audioChunk) {
        _processAudioChunk(audioChunk);
      });

      _isStreaming = true;
      debugPrint('✅ Realtime streaming started');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Streaming start failed: $e');
      onError?.call('Failed to start streaming');
      return false;
    }
  }

  Future<void> _processAudioChunk(List<double> audioChunk) async {
    try {
      // Convert to mel spectrogram
      final melSpectrogram =
          await AudioConverter.convertToMelSpectrogram(audioChunk);

      // Send to WebSocket
      _wsChannel?.sink.add({
        'mel_spectrogram': melSpectrogram,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      debugPrint('❌ Audio chunk processing failed: $e');
    }
  }

  Future<void> stopStreaming() async {
    try {
      debugPrint('🛑 Stopping realtime streaming...');

      await _audioSubscription?.cancel();
      _audioSubscription = null;

      await _audioService.stopRecording();

      await _wsChannel?.sink.close();
      _wsChannel = null;

      _isStreaming = false;
      debugPrint('✅ Realtime streaming stopped');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Streaming stop error: $e');
    }
  }

  @override
  void dispose() {
    stopStreaming();
    super.dispose();
  }
}
