// lib/screens/responsive_home_screen.dart
import 'package:flutter/material.dart';
import 'package:neuvoice_main/services/backend_service.dart';
import 'package:provider/provider.dart';

import '../widgets/recording_button.dart';
import '../widgets/server_status.dart';
import '../services/history_service.dart';
import '../models/session_model.dart';

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  String _sessionId = '';

  // Simple local connection flags; wire these to your backend later if desired.
  bool? _isConnected = false;
  bool? _isLoading = false;
  VoidCallback? _recheckConnection;

  @override
  void initState() {
    super.initState();
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _recheckConnection = () {
      // Hook this to your BackendService check if needed
      setState(() {
        _isLoading = true;
      });
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _isConnected = _isConnected == true ? false : true; // toggle demo
          _isLoading = false;
        });
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, history, _) {
        final items = history.history;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isPhone = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1200;
            final pad = isPhone
                ? 12.0
                : isTablet
                    ? 20.0
                    : 28.0;
            final titleSize = isPhone
                ? 20.0
                : isTablet
                    ? 24.0
                    : 28.0;

            return Scaffold(
              appBar: AppBar(
                title: Text('NeuVoice', style: TextStyle(fontSize: titleSize)),
                centerTitle: isPhone,
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Center(
                      child: ServerStatus(
                          isConnected: BackendService.instance
                              .isConnected, // ✅ Pass actual backend state
                          isLoading: BackendService.instance.isDownloadingModel,
                          recheckConnection: () async {
                            try {
                              await BackendService.instance
                                  .connectAndUpdateModel();
                            } catch (e) {
                              debugPrint(
                                  'Manual Pi coordinator refresh failed: $e');
                            }
                          } // nullable callback
                          ),
                    ),
                  ),
                ],
              ),
              body: SingleChildScrollView(
                padding: EdgeInsets.all(pad),
                child: _buildBody(context, items, isPhone, isTablet),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<TrainingExample> items,
    bool isPhone,
    bool isTablet,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopSection(context, isPhone),
        const SizedBox(height: 16),
        _buildLatestSection(context, items, isPhone),
        const SizedBox(height: 16),
        _buildHistorySection(context, items, isPhone, isTablet),
      ],
    );
  }

  Widget _buildTopSection(BuildContext context, bool isPhone) {
    final textStyle = TextStyle(
      fontSize: isPhone ? 14 : 16,
      color: Colors.grey[700],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          children: [
            Text(
              'Tap to start/stop recording.\nInference runs locally. Training examples are sent periodically.',
              textAlign: TextAlign.center,
              style: textStyle,
            ),
            const SizedBox(height: 12),
            Center(
              child: RecordingButton(
                sessionId: _sessionId,
                onTranscription: (t) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            t.isEmpty ? 'No transcript' : 'Transcript: $t')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestSection(
    BuildContext context,
    List<TrainingExample> items,
    bool isPhone,
  ) {
    final latest = items.isNotEmpty ? items.last : null;
    final labelStyle = TextStyle(
      fontSize: isPhone ? 16 : 18,
      fontWeight: FontWeight.w600,
    );
    final bodyStyle = TextStyle(
      fontSize: isPhone ? 14 : 16,
      color: Colors.grey[800],
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest transcription', style: labelStyle),
            const SizedBox(height: 8),
            if (latest == null)
              Text('(none yet)', style: bodyStyle)
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    latest.transcript.isNotEmpty
                        ? latest.transcript
                        : '(empty)',
                    maxLines: isPhone ? 3 : 4,
                    overflow: TextOverflow.ellipsis,
                    style: bodyStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'At: ${latest.formattedTimestamp}',
                    style: TextStyle(
                      fontSize: isPhone ? 12 : 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(
    BuildContext context,
    List<TrainingExample> items,
    bool isPhone,
    bool isTablet,
  ) {
    final headerStyle = TextStyle(
      fontSize: isPhone ? 16 : 18,
      fontWeight: FontWeight.w600,
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isPhone ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 8 : 12, vertical: 8),
              child: Row(
                children: [
                  Text('History', style: headerStyle),
                  const Spacer(),
                  _HistoryActions(isCompact: isPhone),
                ],
              ),
            ),
            const Divider(height: 1),
            if (items.isEmpty)
              Padding(
                padding: EdgeInsets.all(isPhone ? 12 : 16),
                child: Text(
                  'No history yet. Start recording!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: isPhone ? 14 : 16,
                    color: Colors.grey[700],
                  ),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: isPhone ? 300 : 400,
                ),
                child: _HistoryList(
                    items: items, isPhone: isPhone, isTablet: isTablet),
              ),
          ],
        ),
      ),
    );
  }
}

class _HistoryActions extends StatelessWidget {
  final bool isCompact;
  const _HistoryActions({required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        isCompact
            ? IconButton(
                tooltip: 'Upload all',
                onPressed: () async {
                  await _upload(context, history);
                },
                icon: const Icon(Icons.cloud_upload),
              )
            : OutlinedButton.icon(
                onPressed: () async {
                  await _upload(context, history);
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload'),
              ),
        const SizedBox(width: 8),
        isCompact
            ? IconButton(
                tooltip: 'Clear all',
                onPressed: () async {
                  await _clearAll(context, history);
                },
                icon: const Icon(Icons.delete_forever),
              )
            : OutlinedButton.icon(
                onPressed: () async {
                  await _clearAll(context, history);
                },
                icon: const Icon(Icons.delete_forever),
                label: const Text('Clear'),
              ),
      ],
    );
  }

  static Future<void> _upload(
      BuildContext context, HistoryService history) async {
    try {
      await history.uploadHistory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded history for training')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    }
  }

  static Future<void> _clearAll(
      BuildContext context, HistoryService history) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will delete all local transcriptions.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      history.clearHistory();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }
}

class _HistoryList extends StatelessWidget {
  final List<TrainingExample> items;
  final bool isPhone;
  final bool isTablet;

  const _HistoryList({
    required this.items,
    required this.isPhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) =>
          _HistoryTile(example: items[index], dense: isPhone),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final TrainingExample example;
  final bool dense;
  const _HistoryTile({required this.example, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final history = context.read<HistoryService>();
    final ts = example.formattedTimestamp;
    final preview = example.transcriptPreview;

    return ListTile(
      dense: dense,
      leading: const Icon(Icons.history),
      title: Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        'Session: ${example.sessionId?.substring(0, 10) ?? '-'} • $ts',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        tooltip: 'Delete',
        icon: const Icon(Icons.delete_outline),
        onPressed: () {
          history.deleteTranscription(example.id);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deleted item')),
          );
        },
      ),
    );
  }
}
