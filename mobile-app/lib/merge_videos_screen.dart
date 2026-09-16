import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'models/selected_video.dart';
import 'services/processing_service.dart';

class MergeVideosScreen extends StatefulWidget {
  const MergeVideosScreen({super.key});

  static const routeName = '/merge-videos';

  @override
  State<MergeVideosScreen> createState() => _MergeVideosScreenState();
}

class _MergeVideosScreenState extends State<MergeVideosScreen> {
  static const _maxFileSizeBytes = 2 * 1024 * 1024 * 1024;
  final _processing = ProcessingService();
  final List<SelectedVideo> _files = <SelectedVideo>[];
  final Map<String, List<String>> _previews = <String, List<String>>{};
  final Map<String, String> _previewStatus = <String, String>{};
  final Map<String, Map<String, dynamic>> _metadata =
      <String, Map<String, dynamic>>{};
  final Set<String> _selectedPaths = <String>{};
  bool _selecting = false;

  Future<void> _addVideos() async {
    setState(() => _selecting = true);
    try {
      final entries = await _processing.pickVideos(multiple: true);
      if (!mounted) return;
      final oversized = <String>[];
      final additions = <SelectedVideo>[];
      for (final entry in entries) {
        final path = entry['path'] as String?;
        if (path == null ||
            path.isEmpty ||
            _files.any((file) => file.path == path)) {
          continue;
        }
        final file = SelectedVideo(
          path: path,
          name: entry['name'] as String? ?? 'video',
          size: (entry['size'] as num?)?.toInt() ?? 0,
        );
        if (file.size > _maxFileSizeBytes) {
          oversized.add(file.name);
        } else {
          additions.add(file);
        }
      }
      setState(() {
        _files.addAll(additions);
        _selectedPaths.addAll(additions.map((file) => file.path));
      });
      for (final file in additions) {
        _loadPreview(file);
      }
      if (oversized.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${oversized.length} video${oversized.length == 1 ? '' : 's'} skipped because it is too large.',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open those videos: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  Future<void> _loadPreview(SelectedVideo file) async {
    if (mounted) setState(() => _previewStatus[file.path] = 'loading');
    try {
      final metadata = await _processing.inspectVideo(file.path);
      final duration = (metadata['durationMs'] as num?)?.toInt() ?? 0;
      final times = <int>[
        (duration * 0.15).round(),
        (duration * 0.50).round(),
        (duration * 0.85).round(),
      ];
      final paths = await _processing.extractThumbnailStrip(
        file.path,
        times,
        exact: false,
      );
      if (!mounted) return;
      setState(() {
        _metadata[file.path] = metadata;
        _previews[file.path] = paths;
        _previewStatus[file.path] = paths.isEmpty ? 'error' : 'ready';
      });
    } catch (_) {
      if (mounted) setState(() => _previewStatus[file.path] = 'error');
    }
  }

  void _removeAt(int index) => setState(() {
    _selectedPaths.remove(_files[index].path);
    _files.removeAt(index);
  });

  void _toggleSelected(SelectedVideo file) => setState(() {
    if (!_selectedPaths.add(file.path)) _selectedPaths.remove(file.path);
  });

  List<SelectedVideo> get _selectedFiles =>
      _files.where((file) => _selectedPaths.contains(file.path)).toList();

  List<(String, String)> _outputResolutionOptions(
    List<SelectedVideo> selectedFiles,
  ) {
    final dimensions = selectedFiles
        .map((file) => _metadata[file.path])
        .whereType<Map<String, dynamic>>()
        .map(
          (metadata) => (
            (metadata['width'] as num?)?.toInt() ?? 0,
            (metadata['height'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((size) => size.$1 > 0 && size.$2 > 0)
        .toList();
    final sourcesMatch =
        dimensions.length == selectedFiles.length &&
        dimensions.toSet().length == 1;
    final options = <(String, String)>[
      if (sourcesMatch)
        (
          'source',
          'Same as source (${dimensions.first.$1}×${dimensions.first.$2})',
        )
      else
        ('highest', 'Highest source resolution'),
      ('1080p', '1080p (1920×1080)'),
      ('720p', '720p (1280×720)'),
    ];
    return options;
  }

  void _move(int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= _files.length) return;
    setState(() {
      final file = _files.removeAt(index);
      _files.insert(target, file);
    });
  }

  Future<void> _confirmMerge() async {
    final selectedFiles = _selectedFiles;
    final outputOptions = _outputResolutionOptions(selectedFiles);
    var outputResolution = outputOptions.first.$1;
    final selectedPositions = selectedFiles
        .map((file) => _files.indexOf(file) + 1)
        .join(', ');
    final totalDurationMs = selectedFiles.fold<int>(
      0,
      (total, file) =>
          total + ((_metadata[file.path]?['durationMs'] as num?)?.toInt() ?? 0),
    );
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Merge ${selectedFiles.length} videos ($selectedPositions)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (totalDurationMs > 0)
                  Text('Duration: ${_formatDuration(totalDurationMs)}'),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(outputResolution),
                  initialValue: outputResolution,
                  decoration: const InputDecoration(
                    labelText: 'Output resolution',
                    border: OutlineInputBorder(),
                  ),
                  items: outputOptions
                      .map(
                        (option) => DropdownMenuItem<String>(
                          value: option.$1,
                          child: Text(option.$2),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => outputResolution = value);
                    }
                  },
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Start merge'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed == true && mounted) {
      await _runMerge(selectedFiles, outputResolution);
    }
  }

  Future<void> _runMerge(
    List<SelectedVideo> selectedFiles,
    String outputResolution,
  ) async {
    final progress = ValueNotifier<int>(0);
    final progressSubscription = _processing.mergeProgress.listen(
      (value) => progress.value = value,
    );
    final merge = _processing.mergeVideos(
      selectedFiles.map((file) => file.path).toList(),
      outputResolution: outputResolution,
    );
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ValueListenableBuilder<int>(
        valueListenable: progress,
        builder: (context, percent, _) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.merge_type,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Merging videos')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: percent / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 16),
              Text(
                '$percent%',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Combining selected clips',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => _processing.cancelMerge(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
    try {
      final output = await merge;
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      await _showMergeResult(output);
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!error.toString().contains('CANCELLED')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not merge videos: $error')),
        );
      }
    } finally {
      await progressSubscription.cancel();
      progress.dispose();
    }
  }

  Future<void> _showMergeResult(String outputPath) async {
    final fileNameController = TextEditingController(
      text: 'VideoFuse_Merge_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    try {
      await showModalBottomSheet<void>(
        context: context,
        builder: (sheetContext) {
          var saving = false;
          String? saveMessage;
          return StatefulBuilder(
            builder: (sheetBodyContext, setSheetState) => SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Your merged video is ready',
                      textAlign: TextAlign.center,
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: fileNameController,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: const InputDecoration(
                        labelText: 'File name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await _processing.saveVideoToDownloads(
                                  outputPath,
                                  _downloadFileName(fileNameController.text),
                                );
                                if (mounted && sheetContext.mounted) {
                                  setSheetState(
                                    () => saveMessage = 'Saved to Downloads.',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Video saved to Downloads.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (error) {
                                if (mounted && sheetContext.mounted) {
                                  setSheetState(
                                    () => saveMessage = 'Save failed: $error',
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Could not save video: $error',
                                      ),
                                    ),
                                  );
                                }
                              } finally {
                                if (sheetContext.mounted) {
                                  setSheetState(() => saving = false);
                                }
                              }
                            },
                      icon: const Icon(Icons.download_outlined),
                      label: Text(saving ? 'Saving…' : 'Save to device'),
                    ),
                    if (saveMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        saveMessage!,
                        textAlign: TextAlign.center,
                        style: Theme.of(sheetContext).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => SharePlus.instance.share(
                        ShareParams(files: [XFile(outputPath)]),
                      ),
                      icon: const Icon(Icons.share_outlined),
                      label: const Text('Share'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Create another'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      fileNameController.dispose();
    }
  }

  String _formatDuration(int milliseconds) {
    final totalSeconds = milliseconds ~/ 1000;
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _downloadFileName(String value) {
    final name = value.trim();
    if (name.isEmpty) {
      return 'VideoFuse_Merge_${DateTime.now().millisecondsSinceEpoch}.mp4';
    }
    return name.toLowerCase().endsWith('.mp4') ? name : '$name.mp4';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedFiles = _selectedFiles;
    final canMerge = selectedFiles.length >= 2;
    return Scaffold(
      appBar: AppBar(title: const Text('Merge videos')),
      body: SafeArea(
        child: _files.isEmpty
            ? _buildEmptyState(theme)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Drag to set order. Tap a number to include or exclude a clip.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _selecting ? null : _addVideos,
                          icon: _selecting
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: const Text('Add videos'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: _files.length,
                      onReorderItem: (oldIndex, newIndex) => setState(() {
                        final file = _files.removeAt(oldIndex);
                        _files.insert(newIndex, file);
                      }),
                      itemBuilder: (context, index) {
                        final file = _files[index];
                        return _MergeClipTile(
                          key: ValueKey(file.path),
                          file: file,
                          order: index + 1,
                          isSelected: _selectedPaths.contains(file.path),
                          canMoveUp: index > 0,
                          canMoveDown: index < _files.length - 1,
                          onMoveUp: () => _move(index, -1),
                          onMoveDown: () => _move(index, 1),
                          onRemove: () => _removeAt(index),
                          onToggleSelected: () => _toggleSelected(file),
                          previewPaths:
                              _previews[file.path] ?? const <String>[],
                          previewStatus: _previewStatus[file.path] ?? 'loading',
                          metadata: _metadata[file.path],
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          onPressed: canMerge ? _confirmMerge : null,
          icon: const Icon(Icons.merge_type),
          label: Text(
            canMerge
                ? 'Merge ${selectedFiles.length} videos'
                : 'Select at least 2 videos',
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.video_collection_outlined,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Choose clips to merge',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'You can reorder them before creating one video.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _selecting ? null : _addVideos,
              icon: _selecting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.video_library_outlined),
              label: const Text('Add videos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MergeClipTile extends StatelessWidget {
  const _MergeClipTile({
    required this.file,
    required this.order,
    required this.isSelected,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
    required this.onToggleSelected,
    required this.previewPaths,
    required this.previewStatus,
    this.metadata,
    super.key,
  });

  final SelectedVideo file;
  final int order;
  final bool isSelected;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;
  final VoidCallback onToggleSelected;
  final List<String> previewPaths;
  final String previewStatus;
  final Map<String, dynamic>? metadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
        child: Row(
          children: [
            Semantics(
              label: 'Video $order',
              value: isSelected ? 'Included in merge' : 'Excluded from merge',
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onToggleSelected,
                  customBorder: const CircleBorder(),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isSelected
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '$order',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -3,
                        bottom: -3,
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.remove_circle_outline,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: previewStatus == 'error'
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: List.generate(
                      3,
                      (index) => Expanded(
                        child: Container(
                          height: 48,
                          margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: index < previewPaths.length
                              ? Image.file(
                                  File(previewPaths[index]),
                                  fit: BoxFit.cover,
                                )
                              : Icon(
                                  previewStatus == 'error'
                                      ? Icons.broken_image_outlined
                                      : Icons.movie_outlined,
                                  size: 20,
                                  color: theme.colorScheme.outline,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              tooltip: 'Reorder video $order',
              onSelected: (value) {
                if (value == 'up') onMoveUp();
                if (value == 'down') onMoveDown();
                if (value == 'remove') onRemove();
              },
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'up',
                  enabled: canMoveUp,
                  child: const Text('Move up'),
                ),
                PopupMenuItem<String>(
                  value: 'down',
                  enabled: canMoveDown,
                  child: const Text('Move down'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove'),
                ),
              ],
              child: const Icon(Icons.more_vert),
            ),
            ReorderableDragStartListener(
              index: order - 1,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel {
    if (previewStatus == 'ready') {
      final width = metadata?['width'];
      final height = metadata?['height'];
      return width is num && height is num
          ? '${width.toInt()}×${height.toInt()}'
          : 'Ready';
    }
    return previewStatus == 'error' ? 'Preview unavailable' : 'Loading preview';
  }
}
