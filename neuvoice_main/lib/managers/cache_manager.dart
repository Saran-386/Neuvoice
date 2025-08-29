import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

class CacheManager extends ChangeNotifier {
  bool _isClearing = false;

  bool get isClearing => _isClearing;

  Future<void> clearAllCache() async {
    try {
      _setClearing(true);
      debugPrint('🧹 Starting cache clear...');

      // Clear transcriptions
      final transcriptionsBox = Hive.box('transcriptions');
      await transcriptionsBox.clear();

      // Clear any other cached data
      // Add more boxes here if needed

      debugPrint('✅ All cache cleared');
    } catch (e) {
      debugPrint('❌ Cache clear failed: $e');
      rethrow;
    } finally {
      _setClearing(false);
    }
  }

  Future<int> getCacheSize() async {
    try {
      int totalItems = 0;

      final transcriptionsBox = Hive.box('transcriptions');
      totalItems += transcriptionsBox.length;

      return totalItems;
    } catch (e) {
      debugPrint('❌ Failed to get cache size: $e');
      return 0;
    }
  }

  void _setClearing(bool clearing) {
    if (_isClearing != clearing) {
      _isClearing = clearing;
      notifyListeners();
    }
  }
}
