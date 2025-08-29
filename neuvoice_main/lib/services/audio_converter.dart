import 'dart:math';
import 'package:fftea/fftea.dart';

class AudioConverter {
  static const int sampleRate = 16000;
  static const int nMels = 40;
  static const int nFft = 1024;
  static const int hopLength = 512;

  static Future<List<List<double>>> convertToMelSpectrogram(
      List<double> audioData) async {
    try {
      // Pad audio if too short
      List<double> paddedAudio = List.from(audioData);
      if (paddedAudio.length < nFft) {
        paddedAudio.addAll(List.filled(nFft - paddedAudio.length, 0.0));
      }

      // Calculate number of frames
      final numFrames = max(1, (paddedAudio.length - nFft) ~/ hopLength + 1);

      // Generate mel spectrogram
      final fft = FFT(nFft);
      final melSpectrogram = <List<double>>[];

      for (int frame = 0; frame < numFrames; frame++) {
        final startIdx = frame * hopLength;
        final frameData = List<double>.filled(nFft, 0.0);

        // Extract frame and apply Hanning window
        for (int i = 0; i < nFft; i++) {
          if (startIdx + i < paddedAudio.length) {
            final window = 0.5 - 0.5 * cos(2 * pi * i / (nFft - 1));
            frameData[i] = paddedAudio[startIdx + i] * window;
          }
        }

        // Compute FFT - now Complex is properly imported
        final fftResult = fft.realFft(frameData);

        // Convert to power spectrum
        final powerSpectrum = <double>[];
        for (int i = 0; i < fftResult.length; i++) {
          final magnitude = sqrt(fftResult[i].x * fftResult[i].x +
              fftResult[i].y * fftResult[i].y);
          powerSpectrum.add(magnitude * magnitude);
        }

        // Apply mel filter bank
        final melFrame = _computeMelFrame(powerSpectrum);
        melSpectrogram.add(melFrame);
      }

      // Normalize spectrogram
      return _normalizeSpectrogram(melSpectrogram);
    } catch (e) {
      throw Exception('Mel spectrogram conversion failed: $e');
    }
  }

  static List<double> _computeMelFrame(List<double> powerSpectrum) {
    // Simplified mel filter bank implementation
    final melFrame = <double>[];
    for (int mel = 0; mel < nMels; mel++) {
      double energy = 0.0;
      final startBin = (mel * powerSpectrum.length / nMels).floor();
      final endBin = ((mel + 1) * powerSpectrum.length / nMels).floor();

      for (int bin = startBin; bin < min(endBin, powerSpectrum.length); bin++) {
        energy += powerSpectrum[bin];
      }

      melFrame.add(log(max(energy, 1e-10)));
    }

    return melFrame;
  }

  static List<List<double>> _normalizeSpectrogram(
      List<List<double>> spectrogram) {
    if (spectrogram.isEmpty) return spectrogram;

    // Calculate global mean and std
    double sum = 0.0;
    int count = 0;
    for (final frame in spectrogram) {
      for (final value in frame) {
        sum += value;
        count++;
      }
    }
    final mean = count > 0 ? sum / count : 0.0;

    double sumSquares = 0.0;
    for (final frame in spectrogram) {
      for (final value in frame) {
        sumSquares += pow(value - mean, 2);
      }
    }
    final std = count > 0 ? sqrt(sumSquares / count) + 1e-6 : 1.0;

    // Normalize
    return spectrogram.map((frame) {
      return frame.map((value) => (value - mean) / std).toList();
    }).toList();
  }
}
