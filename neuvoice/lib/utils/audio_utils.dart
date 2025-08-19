/*import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io';*/
import 'package:wav/wav.dart';

class AudioUtils {
  static Future<List<double>> loadWavAsFloat32(String path) async {
    final wav = await Wav.readFile(path); // Wav.readFile returns Wav object
    return wav.channels[0]
        .map((s) => s.toDouble())
        .toList(); // Access samples from the first channel
  }

  static List<List<double>> extractMelSpectrogram(
    List<double> samples, {
    int sampleRate = 16000,
    int nMels = 40,
  }) {
    // TODO: Implement proper STFT + Mel filterbank
    // Return dummy zeros for now with right shape
    final timeSteps = 100;
    return List.generate(timeSteps, (_) => List.filled(nMels, 0.0));
  }

  static String ctcGreedyDecode(List<List<double>> logits) {
    final sb = StringBuffer();
    int prev = -1;
    for (final frame in logits) {
      final maxIndex = frame.indexOf(frame.reduce((a, b) => a > b ? a : b));
      if (maxIndex != prev && maxIndex != 0) {
        sb.write(String.fromCharCode(96 + maxIndex));
      }
      prev = maxIndex;
    }
    return sb.toString();
  }
}
