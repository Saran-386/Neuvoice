// lib/services/history_service.dart
import 'package:flutter/foundation.dart';
import '../models/session_model.dart';
import 'backend_service.dart';

class HistoryService extends ChangeNotifier {
  final List<TrainingExample> _history = [];
  bool _isLoading = false;

  List<TrainingExample> get history => List.unmodifiable(_history);
  List<TrainingExample> get transcriptions => history;
  bool get isLoading => _isLoading;

  void setLoading(bool v) {
    if (_isLoading != v) {
      _isLoading = v;
      notifyListeners();
    }
  }

  void addTranscription({
    required String sessionId,
    required String transcript,
    required DateTime timestamp,
    required List<List<double>> melFeatures,
    double confidence = 0.0,
  }) {
    _history.add(
      TrainingExample(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        melFeatures: melFeatures,
        transcript: transcript,
        timestamp: timestamp,
        sessionId: sessionId,
        confidence: confidence,
      ),
    );
    notifyListeners();
  }

  TrainingExample? getLatest() {
    if (_history.isEmpty) return null;
    return _history.reduce((a, b) {
      final aTime = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.isAfter(bTime) ? a : b;
    });
  }

  Future<void> uploadHistory() async {
    if (_history.isEmpty) return;
    setLoading(true);
    try {
      for (final item in _history) {
        await BackendService.instance.submitTrainingExample(
          sessionId: item.sessionId ?? '',
          melFeatures: item.melFeatures,
          transcript: item.transcript,
          confidence: item.confidence,
        );
      }
    } finally {
      setLoading(false);
    }
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  void clearAll() => clearHistory();

  void deleteExample(String id) {
    _history.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void deleteTranscription(String id) => deleteExample(id);
}
