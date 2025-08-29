// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/history_service.dart';
import '../models/session_model.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<HistoryService>(
      builder: (context, history, _) {
        // Expect these in HistoryService:
        // - List<TrainingExample> get transcriptions
        // - bool get isLoading // This line is a comment, not code. The actual fix is in HistoryService.
        final items = history.transcriptions;
        final loading = history.isLoading;

        return LayoutBuilder(
          builder: (context, constraints) {
            // Responsive breakpoints
            final isPhone = constraints.maxWidth < 600;
            final isTablet =
                constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

            final horizontalPadding = isPhone
                ? 12.0
                : isTablet
                    ? 20.0
                    : 32.0;
            final titleSize = isPhone
                ? 18.0
                : isTablet
                    ? 22.0
                    : 24.0;
            final cardMargin = isPhone ? 8.0 : 12.0;
            final iconSize = isPhone ? 20.0 : 24.0;

            return Scaffold(
              appBar: AppBar(
                title: Text('Transcription History',
                    style: TextStyle(fontSize: titleSize)),
                centerTitle: isPhone,
                actions:
                    _buildAppBarActions(context, history, loading, isPhone),
              ),
              body: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: loading && items.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : items.isEmpty
                        ? _EmptyState(
                            onUploadTap: loading
                                ? null
                                : () => _handleUpload(context, history),
                            isCompact: isPhone,
                          )
                        : _ResponsiveHistoryList(
                            items: items,
                            onDelete: (id) =>
                                _handleDelete(context, history, id),
                            isPhone: isPhone,
                            isTablet: isTablet,
                            cardMargin: cardMargin,
                            iconSize: iconSize,
                          ),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
    BuildContext context,
    HistoryService history,
    bool loading,
    bool isPhone,
  ) {
    return [
      // Upload
      isPhone
          ? IconButton(
              tooltip: 'Upload all',
              onPressed: loading ? null : () => _handleUpload(context, history),
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
            )
          : TextButton.icon(
              onPressed: loading ? null : () => _handleUpload(context, history),
              icon: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cloud_upload),
              label: const Text('Upload'),
            ),
      // Clear
      isPhone
          ? IconButton(
              tooltip: 'Clear all',
              onPressed:
                  loading ? null : () => _handleClearAll(context, history),
              icon: const Icon(Icons.delete_forever),
            )
          : TextButton.icon(
              onPressed:
                  loading ? null : () => _handleClearAll(context, history),
              icon: const Icon(Icons.delete_forever),
              label: const Text('Clear'),
            ),
    ];
  }

  Future<void> _handleUpload(
      BuildContext context, HistoryService history) async {
    history.setLoading(true);
    try {
      await history.uploadHistory();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Uploaded history for training')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      if (mounted) history.setLoading(false);
    }
  }

  Future<void> _handleClearAll(
      BuildContext context, HistoryService history) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will delete all local transcriptions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      history.clearAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('History cleared')),
      );
    }
  }

  void _handleDelete(BuildContext context, HistoryService history, String id) {
    history.deleteTranscription(id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted item')),
    );
  }
}

class _ResponsiveHistoryList extends StatelessWidget {
  final List<TrainingExample> items;
  final ValueChanged<String> onDelete;
  final bool isPhone;
  final bool isTablet;
  final double cardMargin;
  final double iconSize;

  const _ResponsiveHistoryList({
    required this.items,
    required this.onDelete,
    required this.isPhone,
    required this.isTablet,
    required this.cardMargin,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    if (isPhone) {
      // Mobile: compact list
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) =>
            _buildMobileItem(context, items[index]),
      );
    } else {
      // Tablet/Desktop: grid of cards
      return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: isTablet ? 420.0 : 360.0,
          childAspectRatio: 2.6,
          crossAxisSpacing: cardMargin,
          mainAxisSpacing: cardMargin,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) => _buildCardItem(context, items[index]),
      );
    }
  }

  Widget _buildMobileItem(BuildContext context, TrainingExample ex) {
    final preview = ex.transcriptPreview;
    final ts = ex.formattedTimestamp;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(Icons.history, size: iconSize),
      title: Text(
        preview,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session: ${ex.sessionId?.substring(0, 8) ?? '-'}',
              style: const TextStyle(fontSize: 12)),
          Text(
            '$ts • conf: ${ex.confidence.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete, size: iconSize),
        onPressed: () => onDelete(ex.id),
        tooltip: 'Delete',
      ),
      onTap: () => _navigateToDetail(context, ex),
    );
  }

  Widget _buildCardItem(BuildContext context, TrainingExample ex) {
    final preview = ex.transcriptPreview;
    final ts = ex.formattedTimestamp;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _navigateToDetail(context, ex),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: iconSize),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, size: iconSize),
                    onPressed: () => onDelete(ex.id),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              const Spacer(),
              Text(
                'Session: ${ex.sessionId?.substring(0, 12) ?? '-'}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ts,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  Text('conf: ${ex.confidence.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail(BuildContext context, TrainingExample ex) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _HistoryDetail(example: ex)),
    );
  }
}

class _HistoryDetail extends StatelessWidget {
  final TrainingExample example;

  const _HistoryDetail({required this.example});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final padding = isNarrow ? 16.0 : 24.0;
        final fontSize = isNarrow ? 14.0 : 16.0;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Transcription Detail'),
            centerTitle: isNarrow,
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  'Session Information',
                  [
                    'Session ID: ${example.sessionId ?? 'Unknown'}',
                    'Timestamp: ${example.formattedTimestamp}',
                    'Confidence: ${example.confidence.toStringAsFixed(3)}',
                    'Mel Features: ${example.dimensionsString}',
                  ],
                  isNarrow,
                ),
                const SizedBox(height: 16),
                _buildTranscriptCard(fontSize, isNarrow),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String title, List<String> info, bool isNarrow) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: isNarrow ? 16 : 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...info.map(
              (text) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child:
                    Text(text, style: TextStyle(fontSize: isNarrow ? 12 : 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(double fontSize, bool isNarrow) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(isNarrow ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transcript',
                style: TextStyle(
                    fontSize: isNarrow ? 16 : 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                example.transcript.isNotEmpty ? example.transcript : '(empty)',
                style: TextStyle(
                    fontSize: fontSize, fontFamily: 'monospace', height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback? onUploadTap;
  final bool isCompact;

  const _EmptyState({this.onUploadTap, required this.isCompact});

  @override
  Widget build(BuildContext context) {
    final iconSize = isCompact ? 40.0 : 64.0;
    final titleSize = isCompact ? 16.0 : 20.0;
    final bodySize = isCompact ? 14.0 : 16.0;

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: isCompact ? 300 : 520),
        padding: EdgeInsets.all(isCompact ? 16 : 24),
        decoration: BoxDecoration(
          color: Colors.blueGrey.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blueGrey.withAlpha(60)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: iconSize, color: Colors.blueGrey),
            SizedBox(height: isCompact ? 8 : 12),
            Text(
              'No transcriptions yet',
              style:
                  TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              'Start recording to build your local training history for federated learning.',
              style: TextStyle(fontSize: bodySize),
              textAlign: TextAlign.center,
            ),
            if (onUploadTap != null) ...[
              SizedBox(height: isCompact ? 12 : 16),
              OutlinedButton.icon(
                onPressed: onUploadTap,
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Upload (if any)'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
