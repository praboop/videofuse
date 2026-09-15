import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'processing_service.dart';

class _TimeInputFormatter extends TextInputFormatter {
  const _TimeInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    final limited = digits.length > 6 ? digits.substring(0, 6) : digits;
    final formatted = limited.length <= 2
        ? limited
        : limited.length <= 4
        ? '${limited.substring(0, 2)}:${limited.substring(2)}'
        : '${limited.substring(0, 2)}:${limited.substring(2, 4)}:${limited.substring(4)}';
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class SelectedVideo {
  const SelectedVideo({
    required this.path,
    required this.name,
    required this.size,
  });

  final String path;
  final String name;
  final int size;
}

void main() {
  runApp(const VideoFuseApp());
}

class VideoFuseApp extends StatelessWidget {
  const VideoFuseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VideoFuse',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0E7C7B),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F8F8),
        useMaterial3: true,
      ),
      routes: {
        ExtractLastFrameScreen.routeName: (_) => const ExtractLastFrameScreen(),
        StitchVideosScreen.routeName: (_) => const StitchVideosScreen(),
        ProcessingProgressScreen.routeName: (_) =>
            const ProcessingProgressScreen(),
        ExportResultScreen.routeName: (_) => const ExportResultScreen(),
      },
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Text(
          'VideoFuse',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VideoFuse',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Simple tools for everyday video work.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimary.withValues(
                        alpha: 0.88,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Video utilities',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12),
            UtilityActionTile(
              icon: Icons.image_outlined,
              title: 'Extract a frame',
              subtitle: 'Choose and save a frame from any video',
              onTap: () {
                Navigator.of(
                  context,
                ).pushNamed(ExtractLastFrameScreen.routeName);
              },
            ),
            const SizedBox(height: 12),
            UtilityActionTile(
              icon: Icons.video_collection_outlined,
              title: 'Stitch videos',
              subtitle: 'Join multiple clips into one video',
              onTap: () {
                Navigator.of(context).pushNamed(StitchVideosScreen.routeName);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class UtilityActionTile extends StatelessWidget {
  const UtilityActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 27),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: theme.textTheme.bodySmall),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: theme.colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExtractLastFrameScreen extends StatelessWidget {
  const ExtractLastFrameScreen({super.key});

  static const routeName = '/extract-last-frame';

  @override
  Widget build(BuildContext context) {
    return const MediaSelectionScreen(
      title: 'Extract Frame',
      icon: Icons.image_outlined,
      minimumFiles: 1,
    );
  }
}

class StitchVideosScreen extends StatelessWidget {
  const StitchVideosScreen({super.key});

  static const routeName = '/stitch-videos';

  @override
  Widget build(BuildContext context) {
    return const MediaSelectionScreen(
      title: 'Stitch Videos',
      icon: Icons.video_collection_outlined,
      minimumFiles: 2,
    );
  }
}

class MediaSelectionScreen extends StatefulWidget {
  const MediaSelectionScreen({
    required this.title,
    required this.icon,
    required this.minimumFiles,
    super.key,
  });

  final String title;
  final IconData icon;
  final int minimumFiles;

  bool get allowsMultiple => minimumFiles > 1;

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  // Selection is path/URI-only, so large source files no longer need to be
  // copied through Flutter memory. Keep a generous safety ceiling for invalid
  // or pathological inputs while allowing normal large camera exports.
  static const _maxFileSizeBytes = 2 * 1024 * 1024 * 1024;
  final List<SelectedVideo> _files = <SelectedVideo>[];
  final _processing = ProcessingService();
  final Map<String, FramePair> _previews = <String, FramePair>{};
  final Map<String, int> _cacheProgress = <String, int>{};
  bool _selecting = false;

  Future<void> _selectFiles() async {
    setState(() => _selecting = true);
    try {
      final files = await _processing.pickVideos(
        multiple: widget.allowsMultiple,
      );
      if (!mounted) return;
      final acceptedFiles = <SelectedVideo>[];
      final oversizedFiles = <String>[];
      for (final entry in files) {
        final path = entry['path'] as String?;
        final name = entry['name'] as String? ?? 'video';
        final size = (entry['size'] as num?)?.toInt() ?? 0;
        if (path == null || path.isEmpty) continue;
        final file = SelectedVideo(path: path, name: name, size: size);
        if (size > _maxFileSizeBytes) {
          oversizedFiles.add(file.name);
        } else {
          acceptedFiles.add(file);
        }
      }
      setState(() {
        if (!widget.allowsMultiple) _files.clear();
        for (final file in acceptedFiles) {
          if (!_files.any((existing) => existing.path == file.path)) {
            _files.add(file);
          }
        }
      });
      for (final file in acceptedFiles) {
        try {
          final duration = await _processing.durationMs(file.path);
          final first = await _processing.extractFrame(file.path, last: false);
          final last = await _processing.extractFrame(file.path, last: true);
          if (mounted) {
            setState(() => _previews[file.path] = FramePair(first, last));
          }
          // Build the 100-point cache in the background after the primary
          // first/last previews are visible.
          setState(() => _cacheProgress[file.path] = 0);
          _processing
              .prefetchThumbnails(
                file.path,
                duration,
                onProgress: (percent) {
                  if (mounted) {
                    setState(() => _cacheProgress[file.path] = percent);
                  }
                },
              )
              .then((_) {
                if (mounted) setState(() => _cacheProgress[file.path] = 100);
              })
              .catchError((_) {
                if (mounted) setState(() => _cacheProgress[file.path] = -1);
              });
        } catch (_) {
          // Keep the file selectable even when thumbnail extraction fails.
        }
      }
      if (oversizedFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${oversizedFiles.length} file${oversizedFiles.length == 1 ? '' : 's'} skipped. '
              'The selected video is too large to process.',
            ),
          ),
        );
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open that video: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _selecting = false);
    }
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // The themed header below owns the screen title; keep the app bar for
      // navigation so the title is not shown twice.
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.78),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: theme.colorScheme.onPrimary,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.allowsMultiple
                                ? 'Select clips in the order you want to use them.'
                                : 'Choose a video and explore its frames.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimary.withValues(
                                alpha: 0.88,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.tonalIcon(
                onPressed: _selecting ? null : _selectFiles,
                icon: _selecting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(widget.icon),
                label: Text(
                  _selecting
                      ? 'Opening files…'
                      : widget.allowsMultiple
                      ? 'Choose videos'
                      : 'Choose a video',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _files.isEmpty
                    ? 'MP4 and MOV files are supported.'
                    : '${_files.length} video${_files.length == 1 ? '' : 's'} selected',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _files.isEmpty
                    ? Center(
                        child: Icon(
                          widget.icon,
                          size: 56,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : ReorderableListView.builder(
                        itemCount: _files.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final file = _files.removeAt(oldIndex);
                            _files.insert(newIndex, file);
                          });
                        },
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return ClipPreviewTile(
                            key: ValueKey(file.path),
                            file: file,
                            icon: widget.icon,
                            frames: _previews[file.path],
                            onSave: (path, name) => _savePreview(path, name),
                            showCustom: !widget.allowsMultiple,
                            onCustom: !widget.allowsMultiple
                                ? () => _openCustomPicker(file)
                                : null,
                            onRemove: () => _removeFile(index),
                            cacheProgress: _cacheProgress[file.path],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePreview(String path, String name) async {
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save frame?'),
        content: const Text('Save this frame to your Downloads folder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) return;
    try {
      await _processing.saveToDownloads(path, name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frame saved to Downloads.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save frame: $error')));
      }
    }
  }

  Future<void> _openCustomPicker(SelectedVideo file) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: CustomFramePicker(
          file: file,
          durationMs: 0,
          processing: _processing,
          onSave: (path, name) => _savePreview(path, name),
        ),
      ),
    );
  }
}

class FramePair {
  const FramePair(this.first, this.last);
  final String first;
  final String last;
}

class ClipPreviewTile extends StatelessWidget {
  const ClipPreviewTile({
    required this.file,
    required this.icon,
    required this.onRemove,
    required this.frames,
    required this.onSave,
    this.showCustom = false,
    this.onCustom,
    this.cacheProgress,
    super.key,
  });

  final SelectedVideo file;
  final IconData icon;
  final VoidCallback onRemove;
  final FramePair? frames;
  final Future<void> Function(String path, String name) onSave;
  final bool showCustom;
  final VoidCallback? onCustom;
  final int? cacheProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                if (cacheProgress != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: cacheProgress! < 0
                        ? Tooltip(
                            message: 'Preview cache failed',
                            child: Icon(
                              Icons.error_outline,
                              color: theme.colorScheme.error,
                              size: 22,
                            ),
                          )
                        : Tooltip(
                            message: 'Building preview cache',
                            child: SizedBox.square(
                              dimension: 34,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: cacheProgress! >= 100 ? 1 : null,
                                    strokeWidth: 3,
                                    color: theme.colorScheme.primary,
                                    backgroundColor: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                  ),
                                  Text(
                                    '${cacheProgress!}%',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                ),
                const Icon(Icons.drag_handle),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _PreviewBox(
                    label: 'First frame',
                    icon: icon,
                    path: frames?.first,
                    onSave: onSave,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _PreviewBox(
                    label: 'Last frame',
                    icon: icon,
                    path: frames?.last,
                    onSave: onSave,
                  ),
                ),
                if (showCustom) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _PreviewBox(
                      label: 'Custom',
                      icon: icon,
                      onTap: onCustom,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewBox extends StatelessWidget {
  const _PreviewBox({
    required this.label,
    required this.icon,
    this.path,
    this.onSave,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final String? path;
  final Future<void> Function(String path, String name)? onSave;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AspectRatio(
      aspectRatio: 1.25,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
        ),
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 3),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: path == null
                    ? Icon(icon, color: theme.colorScheme.primary, size: 27)
                    : GestureDetector(
                        onTap: () => onSave!(
                          path!,
                          'videofuse_${label.toLowerCase().replaceAll(' ', '_')}.png',
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(
                            File(path!),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomFramePicker extends StatefulWidget {
  const CustomFramePicker({
    required this.file,
    required this.durationMs,
    required this.processing,
    required this.onSave,
    super.key,
  });
  final SelectedVideo file;
  final int durationMs;
  final ProcessingService processing;
  final Future<void> Function(String path, String name) onSave;
  @override
  State<CustomFramePicker> createState() => _CustomFramePickerState();
}

class _CustomFramePickerState extends State<CustomFramePicker> {
  double position = 0;
  int duration = 0;
  double fps = 30.0;
  final timeController = TextEditingController();
  List<String> thumbnails = <String>[];
  List<int> thumbnailTimes = <int>[];
  List<String> detailThumbnails = <String>[];
  List<int> detailTimes = <int>[];
  final ScrollController detailScrollController = ScrollController();
  bool detailLoading = false;
  bool loading = true;
  int selectedTime = 0;
  int gridAnimationDirection = 1;
  Axis gridAnimationAxis = Axis.horizontal;
  int _gridRequestId = 0;
  int _detailRequestId = 0;
  int selectedDetailIndex = -1;
  int highlightedGridTime = 0;

  void _trace(String area, String message) {
    debugPrint(
      '[VideoFuse][${DateTime.now().toIso8601String()}][$area] $message',
    );
  }

  Future<void> _load() async {
    final requestId = ++_gridRequestId;
    final stopwatch = Stopwatch()..start();
    _trace(
      'Grid',
      'start id=$requestId position=${position.toStringAsFixed(4)}',
    );
    setState(() => loading = true);
    selectedTime = (duration * position).round();
    final available = widget.processing.cachedTimes(widget.file.path);
    final candidates =
        available.isEmpty
              ? <int>[selectedTime]
              : (available.toList()..sort(
                      (a, b) => (a - selectedTime).abs().compareTo(
                        (b - selectedTime).abs(),
                      ),
                    ))
                    .take(16)
                    .toList()
          ..sort();

    // Cache timestamps are stored in milliseconds, while the grid displays
    // frame timestamps. Two nearby cache points can therefore render the same
    // label (for example, two entries both appearing as 0:30:05). Keep one
    // entry per displayed frame. Do not insert the exact slider time here:
    // that would turn every slider movement into a decoder request and delay
    // an otherwise instant cache-only grid update.
    final window = <int>[];
    final displayedLabels = <String>{};
    for (final time in candidates) {
      if (displayedLabels.add(_formatTime(time))) window.add(time);
    }
    final times = window;
    final highlightedTime = times.isEmpty
        ? selectedTime
        : times.reduce(
            (a, b) =>
                (a - selectedTime).abs() <= (b - selectedTime).abs() ? a : b,
          );
    _trace(
      'Grid',
      'cache window id=$requestId available=${available.length} tiles=${times.length} selected=$selectedTime highlighted=$highlightedTime',
    );
    List<String> paths;
    try {
      paths = await widget.processing.extractThumbnailStrip(
        widget.file.path,
        times,
      );
    } catch (error) {
      _trace('Grid', 'cache request failed id=$requestId error=$error');
      paths = <String>[];
    }
    if (mounted && requestId == _gridRequestId) {
      setState(() {
        thumbnails = paths;
        thumbnailTimes = times;
        highlightedGridTime = highlightedTime;
        loading = false;
      });
      _trace(
        'Grid',
        'complete id=$requestId paths=${paths.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      // Keep the detailed strip synchronized with the currently selected
      // grid frame; it is shown immediately without requiring a second tap.
      if (paths.isNotEmpty && duration > 0) _loadDetail(selectedTime);
    } else {
      _trace(
        'Grid',
        'stale result ignored id=$requestId current=$_gridRequestId elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
  }

  Future<void> _loadDetail(int centerTime) async {
    final requestId = ++_detailRequestId;
    final stopwatch = Stopwatch()..start();
    _trace(
      'Detail',
      'start id=$requestId center=$centerTime (${_formatTime(centerTime)}) fps=${fps.toStringAsFixed(3)}',
    );
    setState(() {
      detailLoading = true;
      detailThumbnails = <String>[];
      detailTimes = <int>[];
      selectedDetailIndex = -1;
    });
    DetailedFrameStrip strip;
    try {
      // Decode one contiguous range around the selected frame. This avoids 61
      // independent timestamp seeks, which can make vendor decoders discard
      // hundreds of frames and leave the strip appearing stuck.
      strip = await widget.processing.extractDetailedFrameStrip(
        widget.file.path,
        centerTime,
        fps,
      );
    } catch (error) {
      _trace('Detail', 'native request failed id=$requestId error=$error');
      strip = const DetailedFrameStrip(paths: <String>[], startFrame: 0);
    }
    if (mounted && requestId == _detailRequestId) {
      final times = List<int>.generate(
        strip.paths.length,
        (index) => (((strip.startFrame + index) * 1000) / fps)
            .round()
            .clamp(0, duration)
            .toInt(),
      );
      final selectedIndex = strip.paths.isEmpty
          ? -1
          : List<int>.generate(strip.paths.length, (index) => index).reduce(
              (a, b) =>
                  (times[a] - centerTime).abs() <= (times[b] - centerTime).abs()
                  ? a
                  : b,
            );
      setState(() {
        detailTimes = times;
        detailThumbnails = strip.paths;
        detailLoading = false;
        selectedDetailIndex = selectedIndex;
      });
      _centerDetailIndex(selectedIndex);
      _trace(
        'Detail',
        'complete id=$requestId frames=${strip.paths.length} startFrame=${strip.startFrame} selectedIndex=$selectedIndex elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    } else {
      _trace(
        'Detail',
        'stale result ignored id=$requestId current=$_detailRequestId elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
    }
  }

  void _centerDetailIndex(int index) {
    if (index < 0) return;
    _centerDetailIndexAfterLayout(index, 0);
  }

  void _centerDetailIndexAfterLayout(int index, int attempt) {
    if (!mounted || index < 0) return;
    if (!detailScrollController.hasClients) {
      if (attempt < 4) {
        Future<void>.delayed(const Duration(milliseconds: 50), () {
          _centerDetailIndexAfterLayout(index, attempt + 1);
        });
      }
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !detailScrollController.hasClients) return;
      const itemExtent = 96.0; // 90px thumbnail + 6px separator
      final viewport = MediaQuery.sizeOf(context).width - 32;
      final target = (index * itemExtent) - ((viewport - 90) / 2);
      detailScrollController.animateTo(
        target.clamp(0.0, detailScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _saveDetailFrame(int index) async {
    if (index < 0 || index >= detailTimes.length) return;
    setState(() => selectedDetailIndex = index);
    _centerDetailIndex(index);
    try {
      final exactPath = await widget.processing.extractFrameAt(
        widget.file.path,
        detailTimes[index],
      );
      if (mounted && index < detailThumbnails.length) {
        // Replace the tapped preview before confirmation so the displayed and
        // exported images are guaranteed to be the same frame.
        setState(() => detailThumbnails[index] = exactPath);
      }
      await widget.onSave(
        exactPath,
        '${_baseName()}_t${_timestampForFile(detailTimes[index])}.png',
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not prepare this frame: $error')),
        );
      }
    }
  }

  void _selectCachedThumbnail(int timeMs) {
    setState(() {
      selectedTime = timeMs;
      _detailRequestId++;
      position = duration == 0 ? 0 : timeMs / duration;
      timeController.text = _formatTime(timeMs);
      detailThumbnails = <String>[];
      detailTimes = <int>[];
      selectedDetailIndex = -1;
    });
    _loadDetail(timeMs);
  }

  void _swipeGrid(int direction, {required Axis axis}) {
    final cached = widget.processing.cachedTimes(widget.file.path);
    if (cached.isEmpty || duration == 0) return;
    final current = (duration * position).round();
    var index = cached.reduce(
      (a, b) => (a - current).abs() <= (b - current).abs() ? a : b,
    );
    var currentIndex = cached.indexOf(index);
    currentIndex = (currentIndex + direction * 5).clamp(0, cached.length - 1);
    final nextTime = cached[currentIndex];
    setState(() {
      position = nextTime / duration;
      _detailRequestId++;
      timeController.text = _formatTime(nextTime);
      gridAnimationDirection = direction;
      gridAnimationAxis = axis;
      loading = true;
      detailThumbnails = <String>[];
      detailTimes = <int>[];
      selectedDetailIndex = -1;
    });
    _load();
  }

  @override
  void initState() {
    super.initState();
    duration = widget.durationMs;
    _initialize();
  }

  @override
  void dispose() {
    timeController.dispose();
    detailScrollController.dispose();
    super.dispose();
  }

  void _applyTime() {
    final parts = timeController.text.trim().split(':');
    if (parts.length != 3) return;
    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);
    final frame = int.tryParse(parts[2]);
    final frameRate = fps.round().clamp(1, 240);
    if (minutes == null ||
        seconds == null ||
        frame == null ||
        seconds < 0 ||
        seconds > 59 ||
        frame < 0 ||
        frame >= frameRate) {
      return;
    }
    final timeMs =
        ((minutes * 60 + seconds) * 1000) + (frame * 1000 ~/ frameRate);
    if (timeMs > duration) {
      return;
    }
    setState(() {
      position = duration == 0 ? 0 : timeMs / duration;
      _detailRequestId++;
      loading = true;
      detailThumbnails = <String>[];
      detailTimes = <int>[];
      selectedDetailIndex = -1;
    });
    _load();
  }

  Future<void> _initialize() async {
    if (duration == 0) {
      duration = await widget.processing.durationMs(widget.file.path);
      fps = await widget.processing.frameRate(widget.file.path);
      if (mounted) setState(() {});
    }
    if (duration > 0) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final gridRows = thumbnails.isEmpty ? 1 : (thumbnails.length + 3) ~/ 4;
    final tileWidth = (MediaQuery.sizeOf(context).width - 50) / 4;
    // Keep the loading state stable, but remove unused rows once thumbnails
    // have arrived so the detailed strip sits directly below the grid.
    final gridHeight = loading
        ? 440.0
        : (gridRows * (tileWidth / 1.1)) + ((gridRows - 1) * 6);
    final thumbnailStrip = GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) {
          _swipeGrid(velocity < 0 ? 1 : -1, axis: Axis.horizontal);
        }
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 100) {
          _swipeGrid(velocity < 0 ? 1 : -1, axis: Axis.vertical);
        }
      },
      child: SizedBox(
        height: gridHeight,
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: thumbnails.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 1.1,
          ),
          itemBuilder: (context, index) {
            final path = thumbnails[index];
            final isSelected = thumbnailTimes[index] == highlightedGridTime;
            return GestureDetector(
              onTap: () => _selectCachedThumbnail(thumbnailTimes[index]),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.transparent,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.all(2),
                child: Column(
                  children: [
                    Text(
                      _formatTime(thumbnailTimes[index]),
                      style: const TextStyle(fontSize: 11),
                    ),
                    Expanded(
                      child: Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    final animatedThumbnailStrip = AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        final offset = gridAnimationAxis == Axis.horizontal
            ? Offset(0.08 * gridAnimationDirection, 0)
            : Offset(0, 0.08 * gridAnimationDirection);
        return SlideTransition(
          position: Tween<Offset>(
            begin: offset,
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) =>
          currentChild ?? const SizedBox.shrink(),
      child: KeyedSubtree(
        key: ValueKey<String>(thumbnailTimes.join(',')),
        child: thumbnailStrip,
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a custom frame',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Selected: ${_formatTime((duration * position).round())} / ${_formatTime(duration)}',
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: timeController,
                      inputFormatters: const <TextInputFormatter>[
                        _TimeInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                        hintText: 'mm:ss:ff',
                        hintStyle: TextStyle(color: Colors.grey),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.datetime,
                      onSubmitted: (_) => _applyTime(),
                    ),
                  ),
                  IconButton(
                    onPressed: _applyTime,
                    icon: const Icon(Icons.check),
                  ),
                ],
              ),
              Slider(
                value: position,
                onChanged: duration == 0
                    ? null
                    : (value) => setState(() {
                        position = value;
                        timeController.text = _formatTime(
                          (duration * value).round(),
                        );
                        loading = true;
                        detailThumbnails = <String>[];
                        detailTimes = <int>[];
                        selectedDetailIndex = -1;
                      }),
                onChangeEnd: (_) => _load(),
              ),
              if (loading && thumbnails.isEmpty)
                const SizedBox(
                  height: 440,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Loading..'),
                      ],
                    ),
                  ),
                )
              else
                SizedBox(
                  height: gridHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      animatedThumbnailStrip,
                      if (loading)
                        ColoredBox(
                          color: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withValues(alpha: 0.82),
                          child: const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox.square(
                                  dimension: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text('Loading..'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (detailLoading)
                const SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Loading detailed frames..'),
                      ],
                    ),
                  ),
                )
              else if (detailThumbnails.isNotEmpty)
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    controller: detailScrollController,
                    scrollDirection: Axis.horizontal,
                    itemCount: detailThumbnails.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 6),
                    itemBuilder: (context, index) => GestureDetector(
                      onTap: () => _saveDetailFrame(index),
                      child: Column(
                        children: [
                          Text(_formatTime(detailTimes[index])),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            width: 90,
                            height: 145,
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: index == selectedDetailIndex
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Image.file(
                              File(detailThumbnails[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 4),
              const Text('Tap a frame to save.'),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int milliseconds) {
    final framesPerSecond = fps.round().clamp(1, 240);
    final totalFrames = (milliseconds * framesPerSecond / 1000).round();
    final totalSeconds = totalFrames ~/ framesPerSecond;
    final frame = totalFrames % framesPerSecond;
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}:${frame.toString().padLeft(2, '0')}';
  }

  String _baseName() {
    final name = widget.file.name;
    final dot = name.lastIndexOf('.');
    return (dot > 0 ? name.substring(0, dot) : name).replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
  }

  String _timestampForFile(int milliseconds) {
    final framesPerSecond = fps.round().clamp(1, 240);
    final totalFrames = (milliseconds * framesPerSecond / 1000).round();
    final seconds = totalFrames ~/ framesPerSecond;
    final frame = totalFrames % framesPerSecond;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}h${minutes.toString().padLeft(2, '0')}m${secs.toString().padLeft(2, '0')}s_f${frame.toString().padLeft(4, '0')}';
  }
}

class ProcessingProgressScreen extends StatelessWidget {
  const ProcessingProgressScreen({super.key});

  static const routeName = '/processing-progress';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Processing',
      actionLabel: 'Cancel',
      icon: Icons.hourglass_empty,
      showProgress: true,
    );
  }
}

class ExportResultScreen extends StatelessWidget {
  const ExportResultScreen({super.key});

  static const routeName = '/export-result';

  @override
  Widget build(BuildContext context) {
    return const UtilityScreenScaffold(
      title: 'Export Ready',
      actionLabel: 'Share',
      icon: Icons.ios_share_outlined,
    );
  }
}

class UtilityScreenScaffold extends StatelessWidget {
  const UtilityScreenScaffold({
    required this.title,
    required this.actionLabel,
    required this.icon,
    this.showProgress = false,
    super.key,
  });

  final String title;
  final String actionLabel;
  final IconData icon;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Center(
                    child: showProgress
                        ? const SizedBox.square(
                            dimension: 40,
                            child: CircularProgressIndicator(),
                          )
                        : Icon(
                            icon,
                            size: 52,
                            color: theme.colorScheme.primary,
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: null,
                icon: Icon(icon),
                label: Text(actionLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
