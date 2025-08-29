// lib/widgets/server_status.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/backend_service.dart';

class ServerStatus extends StatelessWidget {
  final bool? isConnected;
  final bool? isLoading;
  final VoidCallback? recheckConnection;

  const ServerStatus({
    super.key,
    this.isConnected,
    this.isLoading,
    this.recheckConnection,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<BackendService>(
      builder: (context, backend, child) {
        // ✅ Use backend service state as primary source of truth
        final actuallyConnected = backend.isConnected;
        final actuallyDownloading = backend.isDownloadingModel;
        final downloadProgress = backend.downloadProgress;

        return GestureDetector(
          onTap: () async {
            // ✅ Manual refresh functionality
            debugPrint('🔄 Manual server status refresh triggered');
            try {
              await backend.connectAndUpdateModel();
            } catch (e) {
              debugPrint('❌ Manual refresh failed: $e');
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(actuallyConnected, actuallyDownloading),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor(actuallyConnected, actuallyDownloading)
                    .withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusIcon(actuallyConnected, actuallyDownloading),
                const SizedBox(width: 6),
                Text(
                  _getStatusText(
                      actuallyConnected, actuallyDownloading, downloadProgress),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (actuallyDownloading && downloadProgress > 0) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      value: downloadProgress,
                      strokeWidth: 2,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(bool connected, bool downloading) {
    if (downloading) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Icon(
      connected ? Icons.cloud_done : Icons.cloud_off,
      size: 14,
      color: Colors.white,
    );
  }

  String _getStatusText(bool connected, bool downloading, double progress) {
    if (downloading) {
      if (progress > 0) {
        return '${(progress * 100).toStringAsFixed(0)}%';
      }
      return 'Syncing...';
    }
    return connected ? 'Connected' : 'Offline';
  }

  Color _getStatusColor(bool connected, bool downloading) {
    if (downloading) {
      return Colors.orange;
    }
    return connected ? Colors.green : Colors.red;
  }
}
