import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class ProcessingService {
  static const _channel = MethodChannel('com.videofuse.processing');
  final Map<String, String> _thumbnailCache = <String, String>{};

  void _trace(String message) {
    debugPrint(
      '[VideoFuse][${DateTime.now().toIso8601String()}][Processing] $message',
    );
  }

  Future<List<Map<String, dynamic>>> pickVideos({
    required bool multiple,
  }) async {
    final result = await _channel.invokeMethod<List<dynamic>>('pickVideos', {
      'multiple': multiple,
    });
    return result
            ?.whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList() ??
        <Map<String, dynamic>>[];
  }

  List<int> cachedTimes(String inputPath) =>
      _thumbnailCache.keys
          .where((key) => key.startsWith('$inputPath:'))
          .map((key) => int.tryParse(key.substring(inputPath.length + 1)))
          .whereType<int>()
          .toList()
        ..sort();

  String? cachedPath(String inputPath, int timeMs) =>
      _thumbnailCache['$inputPath:$timeMs'];

  Future<List<int>> prefetchThumbnails(
    String inputPath,
    int durationMs, {
    void Function(int percent)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();
    final times = List<int>.generate(100, (index) {
      if (index == 0) return 0;
      if (index == 99) return durationMs;
      return (durationMs * index / 99).round();
    });
    // One native extractor session is substantially faster and uses less
    // memory than repeatedly creating ten separate decoder sessions.
    // Use the bounded retriever path for the coarse cache as well. Media3's
    // asynchronous queue can saturate some vendor Codec2 implementations when
    // 100 seek requests are submitted in one session.
    _trace('prefetch start count=${times.length} durationMs=$durationMs');
    await extractThumbnailStrip(
      inputPath,
      times,
      sequential: true,
      syncSeek: true,
    );
    _trace(
      'prefetch complete cached=${cachedTimes(inputPath).length} elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    onProgress?.call(100);
    return times;
  }

  Future<String> extractLastFrame(String inputPath) async {
    final output = await _channel.invokeMethod<String>('extractLastFrame', {
      'inputPath': inputPath,
    });
    if (output == null) throw StateError('No frame was generated.');
    return output;
  }

  Future<String> extractFrame(String inputPath, {required bool last}) async {
    final output = await _channel.invokeMethod<String>('extractFrame', {
      'inputPath': inputPath,
      'last': last,
    });
    if (output == null) throw StateError('No frame was generated.');
    return output;
  }

  Future<String> extractFrameAt(String inputPath, int timeMs) async {
    final output = await _channel.invokeMethod<String>('extractFrameAt', {
      'inputPath': inputPath,
      'timeMs': timeMs,
    });
    if (output == null) throw StateError('No frame was generated.');
    return output;
  }

  Future<int> durationMs(String inputPath) async =>
      (await _channel.invokeMethod<int>('durationMs', {
        'inputPath': inputPath,
      })) ??
      0;

  Future<double> frameRate(String inputPath) async =>
      (await _channel.invokeMethod<num>('frameRate', {
        'inputPath': inputPath,
      }))?.toDouble() ??
      30.0;

  Future<List<String>> extractThumbnailStrip(
    String inputPath,
    List<int> timesMs, {
    bool exact = false,
    bool sequential = false,
    bool syncSeek = false,
  }) async {
    // Exact requests must not reuse a coarse nearest-keyframe image at the
    // same timestamp. The detailed picker relies on the returned image being
    // the actual requested frame.
    final missingTimes = exact
        ? timesMs.toList()
        : timesMs
              .where((time) => !_thumbnailCache.containsKey('$inputPath:$time'))
              .toList();
    final stopwatch = Stopwatch()..start();
    _trace(
      'thumbnail request count=${timesMs.length} missing=${missingTimes.length} exact=$exact sequential=$sequential syncSeek=$syncSeek',
    );
    if (missingTimes.isNotEmpty) {
      _trace('thumbnail native start count=${missingTimes.length}');
      final result = await _channel
          .invokeMethod<List<dynamic>>('extractThumbnailStrip', {
            'inputPath': inputPath,
            'timesMs': missingTimes,
            'exact': exact,
            'sequential': sequential,
            'syncSeek': syncSeek,
          });
      final generated = result?.whereType<String>().toList() ?? <String>[];
      _trace(
        'thumbnail native complete generated=${generated.length}/${missingTimes.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
      );
      for (
        var index = 0;
        index < generated.length && index < missingTimes.length;
        index++
      ) {
        _thumbnailCache['$inputPath:${missingTimes[index]}'] = generated[index];
      }
    }
    final resolved = timesMs
        .map((time) => _thumbnailCache['$inputPath:$time'])
        .whereType<String>()
        .toList();
    _trace(
      'thumbnail resolved=${resolved.length}/${timesMs.length} elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    return resolved;
  }

  Future<DetailedFrameStrip> extractDetailedFrameStrip(
    String inputPath,
    int centerTimeMs,
    double frameRate,
  ) async {
    final stopwatch = Stopwatch()..start();
    _trace(
      'detail native start centerMs=$centerTimeMs fps=${frameRate.toStringAsFixed(3)}',
    );
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
      'extractDetailedFrameStrip',
      {
        'inputPath': inputPath,
        'centerTimeMs': centerTimeMs,
        'frameRate': frameRate,
      },
    );
    final paths = (result?['paths'] as List<dynamic>? ?? const <dynamic>[])
        .whereType<String>()
        .toList();
    final startFrame = (result?['startFrame'] as num?)?.toInt() ?? 0;
    _trace(
      'detail native complete frames=${paths.length} startFrame=$startFrame elapsedMs=${stopwatch.elapsedMilliseconds}',
    );
    return DetailedFrameStrip(paths: paths, startFrame: startFrame);
  }

  Future<String> saveToDownloads(String inputPath, String displayName) async {
    final output = await _channel.invokeMethod<String>('saveToDownloads', {
      'inputPath': inputPath,
      'displayName': displayName,
    });
    if (output == null) throw StateError('The file could not be saved.');
    return output;
  }

  Future<String> stitchVideos(List<String> inputPaths) async {
    final output = await _channel.invokeMethod<String>('stitchVideos', {
      'inputPaths': inputPaths,
    });
    if (output == null) throw StateError('No stitched video was generated.');
    return output;
  }
}

class DetailedFrameStrip {
  const DetailedFrameStrip({required this.paths, required this.startFrame});

  final List<String> paths;
  final int startFrame;
}
