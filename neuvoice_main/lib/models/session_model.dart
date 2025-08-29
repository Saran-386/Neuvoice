/// Data models for session management and training examples in federated learning system
class Session {
  final String id;
  final DateTime createdAt;
  String? transcript;
  bool finalized;
  Map<String, dynamic> metadata;

  Session({
    required this.id,
    required this.createdAt,
    this.transcript,
    this.finalized = false,
    this.metadata = const {},
  });

  /// Convert session to JSON for API calls
  Map<String, dynamic> toJson() => {
        'session_id': id,
        'created_at': createdAt.toIso8601String(),
        'transcript': transcript,
        'finalized': finalized,
        'metadata': metadata,
      };

  /// Create session from JSON response
  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['session_id'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        transcript: json['transcript'] as String?,
        finalized: json['finalized'] as bool? ?? false,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  /// Update session transcript
  Session copyWith({
    String? transcript,
    bool? finalized,
    Map<String, dynamic>? metadata,
  }) =>
      Session(
        id: id,
        createdAt: createdAt,
        transcript: transcript ?? this.transcript,
        finalized: finalized ?? this.finalized,
        metadata: metadata ?? this.metadata,
      );
}

/// Training example containing mel features and transcript for federated learning
class TrainingExample {
  final String id;
  final List<List<double>> melFeatures; // 2D array [time_steps, mel_bins]
  final String transcript;
  final DateTime? timestamp;
  final String? sessionId;
  final double confidence;

  TrainingExample({
    required this.id,
    required this.melFeatures,
    required this.transcript,
    this.timestamp,
    this.sessionId,
    this.confidence = 0.0,
  });

  /// Convert to JSON for backend submission
  Map<String, dynamic> toJson() => {
        'example_id': id,
        'mel_features_shape': [
          melFeatures.length,
          melFeatures.isEmpty ? 0 : melFeatures.first.length
        ],
        'mel_features': melFeatures.expand((e) => e).toList(), // flattened
        'transcript': transcript,
        'timestamp': timestamp?.toIso8601String(),
        'session_id': sessionId,
        'confidence': confidence,
      };

  /// Create from JSON (if needed for local storage/caching)
  factory TrainingExample.fromJson(Map<String, dynamic> json) {
    final shape = (json['mel_features_shape'] as List<dynamic>).cast<int>();
    final flattened = (json['mel_features'] as List<dynamic>).cast<double>();

    // Reconstruct 2D mel features from flattened array
    final melFeatures = <List<double>>[];
    final timeSteps = shape[0];
    final melBins = shape[1];

    for (int t = 0; t < timeSteps; t++) {
      final start = t * melBins;
      final end = start + melBins;
      melFeatures.add(flattened.sublist(start, end));
    }

    return TrainingExample(
      id: json['example_id'] as String,
      melFeatures: melFeatures,
      transcript: json['transcript'] as String,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      sessionId: json['session_id'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Get mel spectrogram dimensions for validation
  String get dimensionsString => melFeatures.isEmpty
      ? '0×0'
      : '${melFeatures.length}×${melFeatures.first.length}';

  /// Check if mel features are valid
  bool get isValidMelFeatures {
    if (melFeatures.isEmpty) return false;
    final expectedLength = melFeatures.first.length;
    return melFeatures.every((frame) => frame.length == expectedLength);
  }

  /// Get human-readable timestamp
  String get formattedTimestamp {
    if (timestamp == null) return 'Unknown time';
    final local = timestamp!.toLocal();
    return '${local.day}/${local.month}/${local.year} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  /// Create a preview of transcript for UI display
  String get transcriptPreview {
    if (transcript.isEmpty) return '(empty)';
    final cleaned = transcript.replaceAll('\n', ' ').trim();
    return cleaned.length <= 50 ? cleaned : '${cleaned.substring(0, 47)}...';
  }
}

/// Model update info from Pi coordinator
class ModelUpdate {
  final String version;
  final DateTime releasedAt;
  final int sizeBytes;
  final String downloadUrl;
  final String checksum;
  final Map<String, dynamic> metadata;

  ModelUpdate({
    required this.version,
    required this.releasedAt,
    required this.sizeBytes,
    required this.downloadUrl,
    required this.checksum,
    this.metadata = const {},
  });

  factory ModelUpdate.fromJson(Map<String, dynamic> json) => ModelUpdate(
        version: json['version'] as String,
        releasedAt: DateTime.parse(json['released_at'] as String),
        sizeBytes: json['size_bytes'] as int,
        downloadUrl: json['download_url'] as String,
        checksum: json['checksum'] as String,
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );

  /// Human-readable file size
  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Device info for federated learning network
class FederatedDevice {
  final String deviceId;
  final String deviceType; // 'mobile', 'desktop', 'web', 'iot'
  final String platform; // 'android', 'ios', 'windows', 'linux', 'web'
  final DateTime lastSeen;
  final String modelVersion;
  final int contributedExamples;

  FederatedDevice({
    required this.deviceId,
    required this.deviceType,
    required this.platform,
    required this.lastSeen,
    required this.modelVersion,
    this.contributedExamples = 0,
  });

  factory FederatedDevice.fromJson(Map<String, dynamic> json) =>
      FederatedDevice(
        deviceId: json['device_id'] as String,
        deviceType: json['device_type'] as String,
        platform: json['platform'] as String,
        lastSeen: DateTime.parse(json['last_seen'] as String),
        modelVersion: json['model_version'] as String,
        contributedExamples: json['contributed_examples'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'device_id': deviceId,
        'device_type': deviceType,
        'platform': platform,
        'last_seen': lastSeen.toIso8601String(),
        'model_version': modelVersion,
        'contributed_examples': contributedExamples,
      };

  /// Check if device is recently active (within last 24 hours)
  bool get isActive => DateTime.now().difference(lastSeen).inHours < 24;

  /// Get device icon based on type and platform
  String get deviceIcon {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return platform.toLowerCase() == 'ios' ? '📱' : '🤖';
      case 'desktop':
        switch (platform.toLowerCase()) {
          case 'windows':
            return '🖥️';
          case 'macos':
            return '🖥️';
          case 'linux':
            return '🐧';
          default:
            return '💻';
        }
      case 'web':
        return '🌐';
      case 'iot':
        return '📡';
      default:
        return '🔌';
    }
  }
}

/// Training statistics for monitoring federated learning progress
class TrainingStats {
  final int totalExamples;
  final int activeDevices;
  final DateTime lastTraining;
  final double averageConfidence;
  final Map<String, int> deviceContributions;
  final String currentModelVersion;

  TrainingStats({
    required this.totalExamples,
    required this.activeDevices,
    required this.lastTraining,
    required this.averageConfidence,
    required this.deviceContributions,
    required this.currentModelVersion,
  });

  factory TrainingStats.fromJson(Map<String, dynamic> json) => TrainingStats(
        totalExamples: json['total_examples'] as int,
        activeDevices: json['active_devices'] as int,
        lastTraining: DateTime.parse(json['last_training'] as String),
        averageConfidence: (json['average_confidence'] as num).toDouble(),
        deviceContributions:
            (json['device_contributions'] as Map<String, dynamic>)
                .map((k, v) => MapEntry(k, v as int)),
        currentModelVersion: json['current_model_version'] as String,
      );

  /// Get formatted time since last training
  String get timeSinceLastTraining {
    final diff = DateTime.now().difference(lastTraining);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
