// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/backend_service.dart';
import 'services/mobile_audio_service.dart';
import 'services/history_service.dart';
import 'screens/responsive_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NeuVoiceApp());
}

class NeuVoiceApp extends StatelessWidget {
  const NeuVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<BackendService>.value(
          value: BackendService.instance,
        ),
        // ✅ CRITICAL FIX: Use singleton instance
        ChangeNotifierProvider<MobileAudioService>.value(
          value: MobileAudioService.instance,
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (_) => HistoryService(),
        ),
      ],
      child: MaterialApp(
        title: 'NeuVoice Federated Learning',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          brightness: Brightness.light,
          useMaterial3: true,
        ),
        home: const AppInitializer(),
      ),
    );
  }
}

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    // ✅ CRITICAL FIX: Initialize only once
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    if (_hasInitialized) return;

    try {
      final audioService = MobileAudioService.instance;
      if (!audioService.isInitialized) {
        await audioService.initialize();
      }
      setState(() {
        _hasInitialized = true;
      });
    } catch (e) {
      debugPrint('❌ App initialization failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendService>(
      builder: (context, backend, child) {
        if (!_hasInitialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Initializing federated learning system...'),
                ],
              ),
            ),
          );
        }

        if (backend.isDownloadingModel) {
          return _ModelDownloadScreen(progress: backend.downloadProgress);
        }

        return const ResponsiveHomeScreen();
      },
    );
  }
}

class _ModelDownloadScreen extends StatelessWidget {
  final double progress;

  const _ModelDownloadScreen({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
            ),
            const SizedBox(height: 20),
            Text(
              'Downloading latest model...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// Add this widget to your main screen for debugging
class DebugTranscriptPanel extends StatelessWidget {
  const DebugTranscriptPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MobileAudioService>(
      builder: (context, audioService, child) {
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.yellow[100],
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEBUG: Transcript Status',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              const SizedBox(height: 8),
              Text('Last Transcript: ${audioService.lastTranscript ?? "null"}'),
              Text('Is Recording: ${audioService.isRecording}'),
              Text('Is Initialized: ${audioService.isInitialized}'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  debugPrint('🔥 DEBUG: Manual transcript check');
                  debugPrint(
                      '   Service transcript: ${audioService.lastTranscript}');
                },
                child: const Text('Debug Log'),
              ),
            ],
          ),
        );
      },
    );
  }
}
