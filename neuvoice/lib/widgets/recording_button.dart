// lib/widgets/recording_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mobile_audio_service.dart';

class RecordingButton extends StatefulWidget {
  final String sessionId;
  final ValueChanged<String> onTranscription;

  const RecordingButton({
    super.key,
    required this.sessionId,
    required this.onTranscription,
  });

  @override
  State<RecordingButton> createState() => _RecordingButtonState();
}

class _RecordingButtonState extends State<RecordingButton> {
  bool _isProcessing = false;
  String _lastDisplayedTranscript = '';

  Future<void> _startRecording() async {
    try {
      final audioService = context.read<MobileAudioService>();
      await audioService.startRecording();
      // Clear display transcript when starting new recording
      setState(() {
        _lastDisplayedTranscript = '';
      });
    } catch (e) {
      debugPrint('Start recording failed: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() {
        _isProcessing = true;
      });

      final audioService = context.read<MobileAudioService>();
      await audioService.stopRecording(widget.sessionId);

      setState(() {
        _isProcessing = false;
      });

      // ✅ CRITICAL FIX: Force immediate UI update with transcript
      final latestTranscript = audioService.lastTranscript ?? '';
      debugPrint('🔥 UI: Processing transcript: $latestTranscript');

      if (latestTranscript.isNotEmpty) {
        setState(() {
          _lastDisplayedTranscript = latestTranscript;
        });
        widget.onTranscription(latestTranscript);
        debugPrint(
            '🔥 UI: State updated with transcript: $_lastDisplayedTranscript');
      }
    } catch (e) {
      debugPrint('Stop recording failed: $e');
      setState(() {
        _isProcessing = false;
      });
    }
  }

  String _getDisplayText(MobileAudioService audioService) {
    if (_isProcessing) {
      return 'Processing your speech...';
    }

    if (audioService.isRecording) {
      return 'Recording... (tap to stop)';
    }

    // ✅ CRITICAL FIX: Use local state for immediate display
    if (_lastDisplayedTranscript.isNotEmpty) {
      debugPrint('🔥 UI: Using local transcript: $_lastDisplayedTranscript');

      if (_lastDisplayedTranscript == 'Sound processed' ||
          _lastDisplayedTranscript == 'Speech recognition completed' ||
          _lastDisplayedTranscript == 'Audio analysis finished' ||
          _lastDisplayedTranscript == 'Recording analyzed') {
        return '✓ $_lastDisplayedTranscript';
      }
      return _lastDisplayedTranscript;
    }

    // Fallback to service transcript
    final serviceTranscript = audioService.lastTranscript;
    if (serviceTranscript != null && serviceTranscript.isNotEmpty) {
      debugPrint('🔥 UI: Using service transcript: $serviceTranscript');

      if (serviceTranscript == 'Sound processed' ||
          serviceTranscript == 'Speech recognition completed' ||
          serviceTranscript == 'Audio analysis finished' ||
          serviceTranscript == 'Recording analyzed') {
        return '✓ $serviceTranscript';
      }
      return serviceTranscript;
    }

    return 'Press to start recording';
  }

  Color _getStatusColor(MobileAudioService audioService) {
    if (_isProcessing) return Colors.orange;
    if (audioService.isRecording) return Colors.red;
    if (_lastDisplayedTranscript.isNotEmpty ||
        (audioService.lastTranscript?.isNotEmpty ?? false)) {
      return Colors.blue;
    }
    return Colors.green;
  }

  IconData _getStatusIcon(MobileAudioService audioService) {
    if (_isProcessing) return Icons.hourglass_empty;
    if (audioService.isRecording) return Icons.mic_off;
    return Icons.mic;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileAudioService>(
      builder: (context, audioService, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 350;

        // ✅ Enhanced debug logging
        debugPrint('🔥 UI: Building RecordingButton');
        debugPrint('   - Service transcript: ${audioService.lastTranscript}');
        debugPrint('   - Local transcript: $_lastDisplayedTranscript');
        debugPrint('   - Is recording: ${audioService.isRecording}');
        debugPrint('   - Is processing: $_isProcessing');

        final displayText = _getDisplayText(audioService);
        debugPrint('🔥 UI: Final display text: $displayText');

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _isProcessing
                  ? null
                  : (audioService.isRecording
                      ? _stopRecording
                      : _startRecording),
              child: Container(
                decoration: BoxDecoration(
                  color: _getStatusColor(audioService).withAlpha(180),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _getStatusColor(audioService).withAlpha(80),
                      blurRadius: 12,
                      spreadRadius: 4,
                    )
                  ],
                ),
                padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
                child: _isProcessing
                    ? SizedBox(
                        width: isSmallScreen ? 32 : 48,
                        height: isSmallScreen ? 32 : 48,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(
                        _getStatusIcon(audioService),
                        color: Colors.white,
                        size: isSmallScreen ? 32 : 48,
                      ),
              ),
            ),
            SizedBox(height: isSmallScreen ? 8 : 16),
            // ✅ CRITICAL FIX: Add container with background to ensure visibility
            Container(
              width: screenWidth * 0.8,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                displayText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 18,
                  fontWeight: FontWeight.w600,
                  color: _getStatusColor(audioService).withAlpha(700),
                ),
              ),
            ),
            // Federated learning status indicator
            if ((_lastDisplayedTranscript.isNotEmpty ||
                    audioService.lastTranscript?.isNotEmpty == true) &&
                !audioService.isRecording &&
                !_isProcessing) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cloud_sync,
                      size: 14,
                      color: Colors.indigo[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Contributing to federated learning',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
