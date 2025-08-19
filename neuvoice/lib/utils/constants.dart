class AppConstants {
  static const String piServerUrl =
      'https://aware-national-bull.ngrok-free.app';
  static const String transcribeEndpoint = '/transcribe';
  static const String healthEndpoint = '/health';
  static const String statusEndpoint = '/status';
  static const String feedbackEndpoint = '/feedback';
  static const String trainingEndpoint = '/training_data';

  // UI Constants
  static const double maxPhoneWidth = 600;
  static const double maxTabletWidth = 900;

  // Recording Constants
  static const int sampleRate = 16000;
  static const int channelCount = 1;
  static const int bitRate = 128000;

  // UI Configuration
  static const double maxContentWidth = 800.0;
  static const double defaultPadding = 16.0;

  // Animation Durations
  static const Duration recordingPulseDuration = Duration(milliseconds: 1000);
  static const Duration buttonScaleDuration = Duration(milliseconds: 200);

  static const String modelVersion = 'v1.0';

  // Colors
  static const int recordingColor = 0xFFFF4444;
  static const int processingColor = 0xFFFF9800;
  static const int readyColor = 0xFF2196F3;
  static const int successColor = 0xFF4CAF50;
  static const int errorColor = 0xFFE53935;
}
