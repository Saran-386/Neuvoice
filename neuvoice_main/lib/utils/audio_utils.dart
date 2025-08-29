import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:wav/wav.dart';
// [NOTE] This code is written for the modern 'fftea' package
import 'package:fftea/fftea.dart';

class AudioUtils {
  // Your file loading function is preserved.
  static Future<List<double>> loadWavAsFloat32(String path) async {
    final wav = await Wav.readFile(path);
    // Convert samples to be in the range [-1.0, 1.0] for processing.
    return wav.channels[0].map((s) => s / 32768.0).toList();
  }

  // This is the Mel Spectrogram function updated to use the correct FFTEA API.
  static List<List<double>> extractMelSpectrogram(
    List<double> samples, {
    int sampleRate = 16000,
    int nFft = 512,
    int nMels = 40,
    int hopLength = 160,
  }) {
    if (samples.isEmpty) {
      return [];
    }

    // [API FIX] The STFT constructor takes the window size and hop length.
    // The window function is applied separately.
    final stft = STFT(nFft);
    final window = Window.hanning(nFft); // The correct method name is 'hann'

    final stftResult = <List<double>>[];

    // The fftea library processes the signal in chunks.
    stft.run(
      Float64List.fromList(samples),
      (Float64x2List result) {
        // Apply the window to the chunk before FFT.
        // The 'inPlaceApplyWindow' method modifies the 'result' directly.
        window.inPlaceApplyWindow(result);
        final windowedChunk = result;

        // Calculate the power spectrum (magnitude squared)
        final power = windowedChunk
            .sublist(0, nFft ~/ 2 + 1)
            .map((c) => c.x * c.x + c.y * c.y)
            .toList();
        stftResult.add(power);
      },
    );

    if (stftResult.isEmpty) return [];

    final melFilterbank = _createMelFilterbank(
      nFft: nFft,
      nMels: nMels,
      sampleRate: sampleRate,
    );

    final melSpectrogram = stftResult.map((spectrum) {
      return _applyFilterbank(spectrum, melFilterbank);
    }).toList();

    return _toLogScale(melSpectrogram);
  }

  // Your robust CTC decoder is preserved.
  static String ctcGreedyDecode(dynamic logits) {
    List<List<double>> logits2D;

    if (logits is List && logits.isNotEmpty && logits.first is List) {
      logits2D = logits.map((e) => (e as List).cast<double>()).toList();
    } else if (logits is List<double>) {
      const int numClasses = 29;
      if (logits.isEmpty || logits.length % numClasses != 0) {
        debugPrint('❌ Invalid flattened logits length.');
        return '';
      }
      final int timeSteps = logits.length ~/ numClasses;
      logits2D = [];
      for (int t = 0; t < timeSteps; t++) {
        logits2D.add(logits.sublist(t * numClasses, (t + 1) * numClasses));
      }
    } else {
      debugPrint('❌ Unsupported logits type: ${logits.runtimeType}');
      return '';
    }

    const String characters = "abcdefghijklmnopqrstuvwxyz '";
    String decoded = '';
    int lastIndex = -1;

    for (var timeStep in logits2D) {
      int maxIndex = 0;
      double maxProb = -double.infinity;
      for (var i = 0; i < timeStep.length; i++) {
        if (timeStep[i] > maxProb) {
          maxProb = timeStep[i];
          maxIndex = i;
        }
      }
      // The blank token is now assumed to be index 28 based on your Python code
      if (maxIndex != 28 && maxIndex != lastIndex) {
        if (maxIndex < characters.length) {
          decoded += characters[maxIndex];
        }
      }
      lastIndex = maxIndex;
    }
    return decoded;
  }

  // All helper functions are preserved.
  static List<List<double>> _createMelFilterbank(
      {required int nFft,
      required int nMels,
      required int sampleRate,
      double fMin = 0.0,
      double? fMax}) {
    final fMaxEffective = fMax ?? sampleRate / 2.0;
    final melMin = 1127.0 * log(1.0 + fMin / 700.0);
    final melMax = 1127.0 * log(1.0 + fMaxEffective / 700.0);
    final melPoints = List.generate(
        nMels + 2, (i) => melMin + i * (melMax - melMin) / (nMels + 1));
    final hzPoints =
        melPoints.map((m) => 700.0 * (exp(m / 1127.0) - 1.0)).toList();
    final binPoints =
        hzPoints.map((f) => (f * (nFft / 2) / sampleRate).floor()).toList();
    final filterbank =
        List.generate(nMels, (_) => List.filled(nFft ~/ 2 + 1, 0.0));
    for (var i = 1; i < nMels + 1; i++) {
      final fPrev = binPoints[i - 1];
      final fCurr = binPoints[i];
      final fNext = binPoints[i + 1];
      for (var j = fPrev; j < fCurr; j++) {
        if (fCurr > fPrev) filterbank[i - 1][j] = (j - fPrev) / (fCurr - fPrev);
      }
      for (var j = fCurr; j < fNext; j++) {
        if (fNext > fCurr) filterbank[i - 1][j] = (fNext - j) / (fNext - fCurr);
      }
    }
    return filterbank;
  }

  static List<double> _applyFilterbank(
      List<double> spectrum, List<List<double>> filterbank) {
    return filterbank.map((row) {
      double sum = 0.0;
      for (var i = 0; i < spectrum.length; i++) {
        sum += spectrum[i] * row[i];
      }
      return sum;
    }).toList();
  }

  static List<List<double>> _toLogScale(List<List<double>> melSpectrogram) {
    return melSpectrogram
        .map((row) => row.map((val) => log(val + 1e-9)).toList())
        .toList();
  }
}
