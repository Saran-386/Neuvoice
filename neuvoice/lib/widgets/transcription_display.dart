// lib/widgets/transcript_history.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mobile_audio_service.dart';

class TranscriptHistory extends StatelessWidget {
  const TranscriptHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileAudioService>(
      builder: (context, audioService, child) {
        final transcript = audioService.lastTranscript;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Latest Transcript',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                transcript?.isNotEmpty == true
                    ? transcript!
                    : 'No speech recognized yet',
                style: TextStyle(
                  fontSize: 16,
                  color: transcript?.isNotEmpty == true
                      ? Colors.black87
                      : Colors.grey[500],
                  fontStyle: transcript?.isNotEmpty == true
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
