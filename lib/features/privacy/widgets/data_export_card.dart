import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../shared/widgets/animated_button.dart';
import '../../../shared/widgets/loading_indicators.dart';

class DataExportCard extends StatefulWidget {
  const DataExportCard({super.key});

  @override
  State<DataExportCard> createState() => _DataExportCardState();
}

class _DataExportCardState extends State<DataExportCard> {
  bool _isExporting = false;
  double _exportProgress = 0.0;
  ExportStatus _exportStatus = ExportStatus.idle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.file_download,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export Your Data',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Download a copy of all your data',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          if (_isExporting) ...[
            _buildExportProgress(theme),
          ] else ...[
            _buildExportOptions(theme),
          ],
        ],
      ),
    );
  }

  Widget _buildExportOptions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What would you like to export?',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        _ExportOption(
          title: 'All Data',
          description: 'Complete data export including conversations, memories, and settings',
          icon: Icons.folder,
          isSelected: true,
          onChanged: (selected) {},
        ),
        
        const SizedBox(height: 8),
        
        _ExportOption(
          title: 'Conversations Only',
          description: 'Chat history and messages',
          icon: Icons.chat,
          isSelected: false,
          onChanged: (selected) {},
        ),
        
        const SizedBox(height: 8),
        
        _ExportOption(
          title: 'Memories Only',
          description: 'Formed memories and relationship data',
          icon: Icons.psychology,
          isSelected: false,
          onChanged: (selected) {},
        ),
        
        const SizedBox(height: 8),
        
        _ExportOption(
          title: 'Settings Only',
          description: 'Preferences and configuration',
          icon: Icons.settings,
          isSelected: false,
          onChanged: (selected) {},
        ),
        
        const SizedBox(height: 20),
        
        Row(
          children: [
            Expanded(
              child: AnimatedButton(
                onPressed: _startExport,
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Start Export'),
                  ],
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Export will be in JSON format and may take a few minutes for large datasets.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportProgress(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _getProgressMessage(),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_exportStatus == ExportStatus.completed)
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 20,
              )
            else if (_exportStatus == ExportStatus.error)
              Icon(
                Icons.error,
                color: theme.colorScheme.error,
                size: 20,
              ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        if (_exportStatus == ExportStatus.inProgress) ...[
          ProgressLoader(
            progress: _exportProgress,
            progressColor: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          
          const Center(
            child: DotsLoader(),
          ),
        ] else if (_exportStatus == ExportStatus.completed) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.file_download_done, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Complete',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your data has been exported successfully.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  onPressed: _downloadFile,
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, size: 20),
                      SizedBox(width: 8),
                      Text('Download File'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedButton(
                onPressed: _resetExport,
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                child: const Text('New Export'),
              ),
            ],
          ),
        ] else if (_exportStatus == ExportStatus.error) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: theme.colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Export Failed',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'There was an error exporting your data. Please try again.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AnimatedButton(
                  onPressed: _retryExport,
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh, size: 20),
                      SizedBox(width: 8),
                      Text('Retry'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              AnimatedButton(
                onPressed: _resetExport,
                backgroundColor: theme.colorScheme.surfaceVariant,
                foregroundColor: theme.colorScheme.onSurfaceVariant,
                child: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _getProgressMessage() {
    switch (_exportStatus) {
      case ExportStatus.inProgress:
        if (_exportProgress < 0.3) {
          return 'Preparing export...';
        } else if (_exportProgress < 0.7) {
          return 'Collecting data...';
        } else {
          return 'Finalizing export...';
        }
      case ExportStatus.completed:
        return 'Export completed successfully!';
      case ExportStatus.error:
        return 'Export failed';
      case ExportStatus.idle:
        return '';
    }
  }

  void _startExport() {
    setState(() {
      _isExporting = true;
      _exportStatus = ExportStatus.inProgress;
      _exportProgress = 0.0;
    });

    _simulateExport();
  }

  void _simulateExport() {
    const duration = Duration(milliseconds: 100);
    const increment = 0.05;

    void updateProgress() {
      if (_exportProgress >= 1.0) {
        setState(() {
          _exportStatus = ExportStatus.completed;
        });
        return;
      }

      setState(() {
        _exportProgress += increment;
      });

      Future.delayed(duration, updateProgress);
    }

    updateProgress();
  }

  void _downloadFile() {
    // TODO: Implement actual file download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File download started'),
      ),
    );
  }

  void _retryExport() {
    _startExport();
  }

  void _resetExport() {
    setState(() {
      _isExporting = false;
      _exportStatus = ExportStatus.idle;
      _exportProgress = 0.0;
    });
  }
}

class _ExportOption extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final Function(bool) onChanged;

  const _ExportOption({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? theme.colorScheme.primary.withOpacity(0.1) 
            : theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.3)
              : theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onChanged(value ?? false),
        title: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        secondary: Icon(icon, color: theme.colorScheme.primary),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
    );
  }
}

enum ExportStatus {
  idle,
  inProgress,
  completed,
  error,
}