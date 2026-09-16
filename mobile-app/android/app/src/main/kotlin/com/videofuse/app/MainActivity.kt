package com.videofuse.app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.MediaStore
import androidx.media3.common.MediaItem
import androidx.media3.effect.Presentation
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.inspector.frame.FrameExtractor
import androidx.media3.transformer.Composition
import androidx.media3.transformer.EditedMediaItem
import androidx.media3.transformer.EditedMediaItemSequence
import androidx.media3.transformer.Effects
import androidx.media3.transformer.ExportException
import androidx.media3.transformer.ExportResult
import androidx.media3.transformer.ProgressHolder
import androidx.media3.transformer.Transformer
import com.google.common.util.concurrent.Futures
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import java.io.File
import kotlin.math.roundToInt
import java.util.concurrent.atomic.AtomicBoolean

private const val CHANNEL = "com.videofuse.processing"
private const val MERGE_PROGRESS_CHANNEL = "com.videofuse.processing/merge-progress"

class MainActivity : FlutterActivity() {
    private val processingExecutor = Executors.newFixedThreadPool(2)
    private var pendingPickerResult: MethodChannel.Result? = null
    @Volatile private var activeMerge: ActiveMerge? = null
    @Volatile private var mergeProgressSink: EventChannel.EventSink? = null
    private val mergeLock = Any()
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pickerRequestCode = 4107

    private class ActiveMerge(
        val output: File,
        val result: MethodChannel.Result,
    ) {
        val cancelled = AtomicBoolean(false)
        @Volatile var transformer: Transformer? = null
    }

    private data class OutputSize(val width: Int, val height: Int)

    override fun onDestroy() {
        if (activeMerge == null) processingExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MERGE_PROGRESS_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                    mergeProgressSink = events
                }

                override fun onCancel(arguments: Any?) {
                    mergeProgressSink = null
                }
            })
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "extractDetailedFrameStrip") {
                val inputPath = call.argument<String>("inputPath")
                val centerTimeMs = call.argument<Int>("centerTimeMs")
                val frameRate = call.argument<Number>("frameRate")?.toDouble()
                if (inputPath == null || centerTimeMs == null || frameRate == null) {
                    result.error("INVALID_ARGUMENTS", "Detailed frame input is missing", null)
                    return@setMethodCallHandler
                }
                processingExecutor.execute {
                    val startedAt = SystemClock.elapsedRealtime()
                    try {
                        Log.d("VideoFuse", "detail start at=$startedAt centerMs=$centerTimeMs fps=$frameRate")
                        val output = extractDetailedFrameStrip(inputPath, centerTimeMs, frameRate)
                        Log.d("VideoFuse", "detail complete at=${SystemClock.elapsedRealtime()} frames=${(output["paths"] as List<*>).size} startFrame=${output["startFrame"]} elapsedMs=${SystemClock.elapsedRealtime() - startedAt}")
                        result.success(output)
                    } catch (error: Exception) {
                        Log.e("VideoFuse", "detail failed at=${SystemClock.elapsedRealtime()} elapsedMs=${SystemClock.elapsedRealtime() - startedAt}: ${error.message}", error)
                        result.error("PROCESSING_FAILED", error.message, null)
                    }
                }
                return@setMethodCallHandler
            }
            if (call.method == "extractThumbnailStrip") {
                val inputPath = call.argument<String>("inputPath")
                val timesMs = call.argument<List<Int>>("timesMs")
                if (inputPath == null || timesMs == null) {
                    result.error("INVALID_ARGUMENTS", "Thumbnail input is missing", null)
                    return@setMethodCallHandler
                }
                processingExecutor.execute {
                    val startedAt = System.nanoTime()
                    try {
                        val exact = call.argument<Boolean>("exact") == true
                        val sequential = call.argument<Boolean>("sequential") == true
                        val syncSeek = call.argument<Boolean>("syncSeek") == true
                        Log.d("VideoFuse", "thumbnail start at=${SystemClock.elapsedRealtime()} count=${timesMs.size} exact=$exact sequential=$sequential syncSeek=$syncSeek first=${timesMs.firstOrNull()} last=${timesMs.lastOrNull()}")
                        val output = extractThumbnailStrip(inputPath, timesMs, exact, sequential, syncSeek)
                        Log.d("VideoFuse", "thumbnail complete at=${SystemClock.elapsedRealtime()} generated=${output.size}/${timesMs.size} exact=$exact sequential=$sequential syncSeek=$syncSeek elapsedMs=${(System.nanoTime() - startedAt) / 1_000_000}")
                        result.success(output)
                    } catch (error: Exception) {
                        Log.e("VideoFuse", "thumbnail failed elapsedMs=${(System.nanoTime() - startedAt) / 1_000_000}: ${error.message}", error)
                        result.error("PROCESSING_FAILED", error.message, null)
                    }
                }
                return@setMethodCallHandler
            }
            if (call.method == "pickVideos") {
                if (pendingPickerResult != null) {
                    result.error("PICKER_BUSY", "A file picker is already open", null)
                    return@setMethodCallHandler
                }
                pendingPickerResult = result
                val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    type = "video/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                    putExtra(Intent.EXTRA_ALLOW_MULTIPLE, call.argument<Boolean>("multiple") == true)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                }
                startActivityForResult(intent, pickerRequestCode)
                return@setMethodCallHandler
            }
            try {
                when (call.method) {
                    "extractLastFrame" -> result.success(extractLastFrame(call.argument<String>("inputPath")!!))
                    "extractFrame" -> result.success(extractFrame(call.argument<String>("inputPath")!!, call.argument<Boolean>("last") == true))
                    "extractFrameAt" -> result.success(extractFrameAt(call.argument<String>("inputPath")!!, call.argument<Int>("timeMs") ?: 0))
                    "durationMs" -> result.success(videoDurationMs(call.argument<String>("inputPath")!!))
                    "frameRate" -> result.success(videoFrameRate(call.argument<String>("inputPath")!!))
                    "inspectVideo" -> result.success(inspectVideo(call.argument<String>("inputPath")!!))
                    "saveToDownloads" -> result.success(saveToDownloads(call.argument<String>("inputPath")!!, call.argument<String>("displayName")!!))
                    "saveVideoToDownloads" -> result.success(saveVideoToDownloads(call.argument<String>("inputPath")!!, call.argument<String>("displayName")!!))
                    "cancelMerge" -> result.success(cancelMerge())
                    "mergeVideos" -> {
                        val inputPaths = call.argument<List<String>>("inputPaths")
                        if (inputPaths == null || inputPaths.size < 2) {
                            result.error("INVALID_ARGUMENTS", "Select at least two videos", null)
                        } else {
                            mergeVideos(
                                inputPaths,
                                call.argument<String>("outputResolution") ?: "highest",
                                result,
                            )
                        }
                    }
                    "stitchVideos" -> {
                        val inputPaths = call.argument<List<String>>("inputPaths")
                        if (inputPaths == null || inputPaths.size < 2) {
                            result.error("INVALID_ARGUMENTS", "Select at least two videos", null)
                        } else {
                            mergeVideos(inputPaths, "highest", result)
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (error: Exception) {
                result.error("PROCESSING_FAILED", error.message, null)
            }
        }
    }

    @Deprecated("Activity result callback is required for the Flutter picker bridge")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != pickerRequestCode) return
        val pending = pendingPickerResult ?: return
        pendingPickerResult = null
        if (resultCode != RESULT_OK || data == null) {
            pending.success(emptyList<Map<String, Any?>>())
            return
        }
        val uris = buildList {
            data.data?.let(::add)
            data.clipData?.let { clip -> for (index in 0 until clip.itemCount) add(clip.getItemAt(index).uri) }
        }.distinct()
        val files = uris.map { uri ->
            try {
                contentResolver.takePersistableUriPermission(uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } catch (_: SecurityException) { }
            val (name, size) = queryDisplayInfo(uri)
            mapOf<String, Any?>("path" to uri.toString(), "name" to name, "size" to size)
        }
        pending.success(files)
    }

    private fun queryDisplayInfo(uri: Uri): Pair<String, Long> {
        var name = uri.lastPathSegment ?: "video"
        var size = 0L
        contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE), null, null, null)?.use { cursor ->
            if (cursor.moveToFirst()) {
                val nameIndex = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                if (nameIndex >= 0) name = cursor.getString(nameIndex) ?: name
                if (sizeIndex >= 0 && !cursor.isNull(sizeIndex)) size = cursor.getLong(sizeIndex)
            }
        }
        return name to size
    }

    private fun setRetrieverSource(retriever: MediaMetadataRetriever, inputPath: String) {
        if (inputPath.startsWith("content://")) retriever.setDataSource(this, Uri.parse(inputPath)) else retriever.setDataSource(inputPath)
    }

    private fun setExtractorSource(extractor: MediaExtractor, inputPath: String) {
        if (inputPath.startsWith("content://")) extractor.setDataSource(this, Uri.parse(inputPath), null) else extractor.setDataSource(inputPath)
    }

    private fun extractLastFrame(inputPath: String): String {
        return extractFrame(inputPath, true)
    }

    private fun extractFrame(inputPath: String, last: Boolean): String {
        val retriever = MediaMetadataRetriever()
        setRetrieverSource(retriever, inputPath)
        val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)
            ?.toLongOrNull() ?: 0L
        val timestampUs = if (last) {
            (durationMs.coerceAtLeast(1L) * 1000L) - 1L
        } else {
            0L
        }
        // Decode at source resolution. The Flutter preview scales this image
        // for display, but the file written to Downloads must remain original
        // resolution.
        val frame = retriever.getFrameAtTime(timestampUs, MediaMetadataRetriever.OPTION_CLOSEST)
            ?: throw IllegalStateException("Could not read the last frame")
        Log.d("VideoFuse", "full-resolution frame last=$last size=${frame.width}x${frame.height}")
        val output = File.createTempFile("videofuse_frame_", ".png", cacheDir)
        output.outputStream().use { frame.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        frame.recycle()
        retriever.release()
        return output.absolutePath
    }

    private fun extractFrameAt(inputPath: String, timeMs: Int): String {
        val retriever = MediaMetadataRetriever()
        setRetrieverSource(retriever, inputPath)
        val frame = retriever.getFrameAtTime(timeMs.coerceAtLeast(0).toLong() * 1000L, MediaMetadataRetriever.OPTION_CLOSEST)
            ?: throw IllegalStateException("Could not read frame")
        Log.d("VideoFuse", "full-resolution frame timeMs=$timeMs size=${frame.width}x${frame.height}")
        val output = File.createTempFile("videofuse_frame_", ".png", cacheDir)
        output.outputStream().use { frame.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, it) }
        frame.recycle(); retriever.release()
        return output.absolutePath
    }

    private fun videoDurationMs(inputPath: String): Int {
        val retriever = MediaMetadataRetriever()
        setRetrieverSource(retriever, inputPath)
        val value = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toIntOrNull() ?: 0
        retriever.release()
        return value
    }

    private fun videoFrameRate(inputPath: String): Double {
        val extractor = MediaExtractor()
        setExtractorSource(extractor, inputPath)
        return try {
            var rate = 30.0
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                if (format.getString(MediaFormat.KEY_MIME)?.startsWith("video/") == true && format.containsKey(MediaFormat.KEY_FRAME_RATE)) {
                    rate = format.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble()
                    break
                }
            }
            rate
        } finally {
            extractor.release()
        }
    }

    private fun inspectVideo(inputPath: String): Map<String, Any?> {
        val extractor = MediaExtractor()
        setExtractorSource(extractor, inputPath)
        val result = mutableMapOf<String, Any?>()
        try {
            var width = 0
            var height = 0
            var rotation = 0
            var videoMime: String? = null
            var audioMime: String? = null
            var frameRate = 30.0
            for (index in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(index)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                if (mime.startsWith("video/")) {
                    videoMime = mime
                    if (format.containsKey(MediaFormat.KEY_WIDTH)) width = format.getInteger(MediaFormat.KEY_WIDTH)
                    if (format.containsKey(MediaFormat.KEY_HEIGHT)) height = format.getInteger(MediaFormat.KEY_HEIGHT)
                    if (format.containsKey(MediaFormat.KEY_ROTATION)) rotation = format.getInteger(MediaFormat.KEY_ROTATION)
                    if (format.containsKey(MediaFormat.KEY_FRAME_RATE)) frameRate = format.getInteger(MediaFormat.KEY_FRAME_RATE).toDouble()
                } else if (mime.startsWith("audio/")) {
                    audioMime = mime
                }
            }
            val retriever = MediaMetadataRetriever()
            setRetrieverSource(retriever, inputPath)
            val duration = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
            retriever.release()
            result["durationMs"] = duration
            result["width"] = width
            result["height"] = height
            result["rotation"] = rotation
            result["frameRate"] = frameRate
            result["videoMime"] = videoMime
            result["audioMime"] = audioMime
            result["hasAudio"] = audioMime != null
            return result
        } finally {
            extractor.release()
        }
    }

    @OptIn(UnstableApi::class)
    private fun extractThumbnailStrip(inputPath: String, timesMs: List<Int>, exact: Boolean, sequential: Boolean, syncSeek: Boolean): List<String> {
        return try {
            if (sequential) extractThumbnailStripLegacy(inputPath, timesMs, syncSeek)
            else extractThumbnailStripMedia3(inputPath, timesMs, exact)
        } catch (_: Exception) {
            extractThumbnailStripLegacy(inputPath, timesMs, syncSeek)
        }
    }

    @OptIn(UnstableApi::class)
    private fun extractThumbnailStripMedia3(inputPath: String, timesMs: List<Int>, exact: Boolean): List<String> {
        val outputs = mutableListOf<String>()
        val mediaItem = MediaItem.fromUri(inputPath)
        val builder = FrameExtractor.Builder(this, mediaItem)
        // Coarse cache thumbnails do not need frame-perfect seeking. Seeking to
        // the nearest sync sample avoids decoding and discarding hundreds of
        // intermediate frames for every requested timestamp. Detailed frame
        // extraction opts into exact seeking via the `exact` flag.
        if (!exact) builder.setSeekParameters(SeekParameters.CLOSEST_SYNC)
        builder.build().use { extractor ->
            for (timeMs in timesMs) {
                val frame = Futures.getUnchecked(extractor.getFrame(timeMs.toLong()))
                val output = File.createTempFile("videofuse_thumb_", ".jpg", cacheDir)
                val sourceBitmap = frame.bitmap
                val thumbnail = android.graphics.Bitmap.createScaledBitmap(sourceBitmap, 240, 135, true)
                try {
                    output.outputStream().use { thumbnail.compress(android.graphics.Bitmap.CompressFormat.JPEG, 72, it) }
                } finally {
                    thumbnail.recycle()
                    // Do not retain full decoded bitmaps while generating a
                    // long thumbnail strip (critical for large source videos).
                    sourceBitmap.recycle()
                }
                outputs.add(output.absolutePath)
            }
        }
        return outputs
    }

    private fun extractThumbnailStripLegacy(inputPath: String, timesMs: List<Int>, syncSeek: Boolean = false): List<String> {
        val retriever = MediaMetadataRetriever()
        setRetrieverSource(retriever, inputPath)
        val outputs = mutableListOf<String>()
        try {
            for (timeMs in timesMs) {
                val frame = retriever.getScaledFrameAtTime(
                    timeMs.coerceAtLeast(0).toLong() * 1000L,
                    if (syncSeek) MediaMetadataRetriever.OPTION_CLOSEST_SYNC else MediaMetadataRetriever.OPTION_CLOSEST,
                    240,
                    135,
                ) ?: continue
                val output = File.createTempFile("videofuse_thumb_", ".jpg", cacheDir)
                output.outputStream().use {
                    frame.compress(android.graphics.Bitmap.CompressFormat.JPEG, 72, it)
                }
                frame.recycle()
                outputs.add(output.absolutePath)
            }
        } finally {
            retriever.release()
        }
        return outputs
    }

    /**
     * Decodes the requested 61-frame preview as one contiguous range. Calling
     * getScaledFrameAtTime 61 times makes several device codecs repeatedly
     * seek and discard input samples; that is the source of the slow or empty
     * detailed strip seen after a grid selection.
     */
    private fun extractDetailedFrameStrip(inputPath: String, centerTimeMs: Int, frameRate: Double): Map<String, Any> {
        val startedAt = SystemClock.elapsedRealtime()
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) {
            Log.w("VideoFuse", "detail contiguous unavailable at=$startedAt api=${Build.VERSION.SDK_INT}; using timestamp fallback")
            return extractDetailedFrameStripFallback(inputPath, centerTimeMs, frameRate)
        }
        try {
            val retriever = MediaMetadataRetriever()
            try {
                setRetrieverSource(retriever, inputPath)
                val durationMs = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_DURATION)?.toLongOrNull() ?: 0L
                val metadataFrameCount = retriever.extractMetadata(MediaMetadataRetriever.METADATA_KEY_VIDEO_FRAME_COUNT)?.toIntOrNull()
                val totalFrames = (metadataFrameCount ?: ((durationMs * frameRate) / 1000.0).roundToInt())
                    .coerceAtLeast(1)
                val centerFrame = ((centerTimeMs * frameRate) / 1000.0).roundToInt().coerceIn(0, totalFrames - 1)
                val startFrame = (centerFrame - 30).coerceAtLeast(0)
                val endFrame = (centerFrame + 30).coerceAtMost(totalFrames - 1)
                val requestedCount = endFrame - startFrame + 1
                Log.d("VideoFuse", "detail contiguous start at=$startedAt durationMs=$durationMs metadataFrames=$metadataFrameCount totalFrames=$totalFrames centerFrame=$centerFrame startFrame=$startFrame count=$requestedCount")
                val frames = retriever.getFramesAtIndex(startFrame, requestedCount)
                val outputs = mutableListOf<String>()
                for (frame in frames) {
                    try {
                        outputs.add(writePreviewThumbnail(frame))
                    } finally {
                        frame.recycle()
                    }
                }
                Log.d("VideoFuse", "detail contiguous complete at=${SystemClock.elapsedRealtime()} returned=${outputs.size}/$requestedCount elapsedMs=${SystemClock.elapsedRealtime() - startedAt}")
                return mapOf("paths" to outputs, "startFrame" to startFrame)
            } finally {
                retriever.release()
            }
        } catch (error: Exception) {
            Log.w("VideoFuse", "detail contiguous failed at=${SystemClock.elapsedRealtime()} elapsedMs=${SystemClock.elapsedRealtime() - startedAt}; using timestamp fallback: ${error.message}", error)
            return extractDetailedFrameStripFallback(inputPath, centerTimeMs, frameRate)
        }
    }

    private fun extractDetailedFrameStripFallback(inputPath: String, centerTimeMs: Int, frameRate: Double): Map<String, Any> {
        val frameIntervalMs = (1000.0 / frameRate.coerceAtLeast(1.0)).roundToInt().coerceAtLeast(1)
        val startTime = (centerTimeMs - (30 * frameIntervalMs)).coerceAtLeast(0)
        val times = List(61) { index -> startTime + (index * frameIntervalMs) }
        val outputs = extractThumbnailStripLegacy(inputPath, times, false)
        val startFrame = ((startTime * frameRate) / 1000.0).roundToInt()
        Log.d("VideoFuse", "detail fallback complete at=${SystemClock.elapsedRealtime()} returned=${outputs.size}/${times.size} startFrame=$startFrame")
        return mapOf("paths" to outputs, "startFrame" to startFrame)
    }

    private fun writePreviewThumbnail(frame: android.graphics.Bitmap): String {
        val thumbnail = android.graphics.Bitmap.createScaledBitmap(frame, 240, 135, true)
        return try {
            val output = File.createTempFile("videofuse_thumb_", ".jpg", cacheDir)
            output.outputStream().use {
                thumbnail.compress(android.graphics.Bitmap.CompressFormat.JPEG, 72, it)
            }
            output.absolutePath
        } finally {
            if (thumbnail !== frame) thumbnail.recycle()
        }
    }

    private fun saveToDownloads(inputPath: String, displayName: String): String {
        val values = android.content.ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, "image/png")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create a Downloads file")
        contentResolver.openOutputStream(uri).use { output ->
            requireNotNull(output)
            FileInputStream(inputPath).use { input -> input.copyTo(output) }
        }
        values.clear(); values.put(MediaStore.Downloads.IS_PENDING, 0)
        contentResolver.update(uri, values, null, null)
        return uri.toString()
    }

    private fun saveVideoToDownloads(inputPath: String, displayName: String): String {
        val values = android.content.ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, displayName)
            put(MediaStore.Downloads.MIME_TYPE, "video/mp4")
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
            ?: throw IllegalStateException("Could not create a Downloads file")
        contentResolver.openOutputStream(uri).use { output ->
            requireNotNull(output)
            FileInputStream(inputPath).use { input -> input.copyTo(output) }
        }
        values.clear(); values.put(MediaStore.Downloads.IS_PENDING, 0)
        contentResolver.update(uri, values, null, null)
        return uri.toString()
    }

    private fun cancelMerge(): Boolean {
        val active = synchronized(mergeLock) {
            val current = activeMerge ?: return false
            activeMerge = null
            current
        }
        active.cancelled.set(true)
        active.output.delete()
        active.transformer?.cancel()
        stopMergeForegroundService()
        emitMergeProgress(0)
        active.result.error("CANCELLED", "Video merge cancelled", null)
        return true
    }

    private fun mergeVideos(
        paths: List<String>,
        outputResolution: String,
        result: MethodChannel.Result,
    ) {
        val output = File.createTempFile("videofuse_merge_", ".mp4", cacheDir)
        val active = ActiveMerge(output, result)
        synchronized(mergeLock) {
            if (activeMerge != null) {
                output.delete()
                result.error("MERGE_BUSY", "A video merge is already running", null)
                return
            }
            activeMerge = active
        }
        startMergeForegroundService()
        emitMergeProgress(0)
        // Most phone clips already use the same H.264/AAC formats. In that
        // case copying compressed samples is dramatically faster than asking
        // Transformer to decode and encode every frame.
        processingExecutor.execute {
            if (outputResolution == "source" && tryFastMerge(paths, output, active)) {
                mainHandler.post {
                    if (!active.cancelled.get()) {
                        Log.d("VideoFuse", "fast merge complete output=${output.absolutePath}")
                        finishMergeSuccess(active)
                    }
                }
            } else {
                runOnUiThread {
                    if (!active.cancelled.get()) {
                        startTransformerMerge(paths, outputResolution, active)
                    }
                }
            }
        }
    }

    private fun isActiveMerge(active: ActiveMerge): Boolean =
        synchronized(mergeLock) { activeMerge === active }

    private fun finishMergeSuccess(active: ActiveMerge) {
        if (!isActiveMerge(active)) return
        synchronized(mergeLock) { if (activeMerge === active) activeMerge = null }
        stopMergeForegroundService()
        emitMergeProgress(100)
        active.result.success(active.output.absolutePath)
    }

    private fun finishMergeError(active: ActiveMerge, message: String, error: Exception? = null) {
        if (!isActiveMerge(active)) return
        synchronized(mergeLock) { if (activeMerge === active) activeMerge = null }
        active.output.delete()
        stopMergeForegroundService()
        Log.e("VideoFuse", message, error)
        active.result.error("PROCESSING_FAILED", message, null)
    }

    private fun emitMergeProgress(percent: Int) {
        mainHandler.post { mergeProgressSink?.success(percent.coerceIn(0, 100)) }
    }

    private fun startMergeForegroundService() {
        try {
            val intent = Intent(this, MergeForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(intent)
            } else {
                startService(intent)
            }
        } catch (error: Exception) {
            // A foreground service can be unavailable on a restricted device.
            // The merge still runs while the activity process remains alive.
            Log.w("VideoFuse", "Could not start merge foreground service", error)
        }
    }

    private fun stopMergeForegroundService() {
        stopService(Intent(this, MergeForegroundService::class.java))
    }

    private fun compatibleTrack(a: MediaFormat, b: MediaFormat, mime: String): Boolean {
        if (a.getString(MediaFormat.KEY_MIME) != mime || b.getString(MediaFormat.KEY_MIME) != mime) return false
        val keys = if (mime.startsWith("video/")) {
            listOf(MediaFormat.KEY_WIDTH, MediaFormat.KEY_HEIGHT, MediaFormat.KEY_FRAME_RATE)
        } else {
            listOf(MediaFormat.KEY_SAMPLE_RATE, MediaFormat.KEY_CHANNEL_COUNT)
        }
        return keys.all { key ->
            !a.containsKey(key) || !b.containsKey(key) || a.getInteger(key) == b.getInteger(key)
        }
    }

    private fun tryFastMerge(paths: List<String>, output: File, active: ActiveMerge): Boolean {
        val extractors = mutableListOf<MediaExtractor>()
        var muxer: MediaMuxer? = null
        var completed = false
        return try {
            val firstFormats = mutableMapOf<String, MediaFormat>()
            paths.forEachIndexed { index, path ->
                val extractor = MediaExtractor()
                setExtractorSource(extractor, path)
                extractors += extractor
                val formats = mutableMapOf<String, MediaFormat>()
                for (track in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(track)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                    if (mime.startsWith("video/") || mime.startsWith("audio/")) formats[mime.substringBefore('/')] = format
                }
                if (index == 0) firstFormats.putAll(formats)
                else if (formats.keys != firstFormats.keys || formats.any { (kind, format) ->
                        !compatibleTrack(firstFormats.getValue(kind), format, format.getString(MediaFormat.KEY_MIME)!!)
                    }) return false
            }

            if (active.cancelled.get()) return false
            val sourceDurationsUs = extractors.map { extractor ->
                (0 until extractor.trackCount).mapNotNull { track ->
                    val format = extractor.getTrackFormat(track)
                    if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else null
                }.maxOrNull() ?: 0L
            }
            val totalDurationUs = sourceDurationsUs.sum().coerceAtLeast(1L)
            var completedDurationUs = 0L
            var lastProgress = -1
            muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val outputTracks = mutableMapOf<String, Int>()
            firstFormats.forEach { (kind, format) -> outputTracks[kind] = muxer.addTrack(format) }
            muxer.start()
            var offsetUs = 0L
            val buffer = ByteBuffer.allocate(4 * 1024 * 1024)
            val info = android.media.MediaCodec.BufferInfo()
            for ((sourceIndex, extractor) in extractors.withIndex()) {
                var segmentEndUs = 0L
                for (track in 0 until extractor.trackCount) {
                    val format = extractor.getTrackFormat(track)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: continue
                    val kind = when {
                        mime.startsWith("video/") -> "video"
                        mime.startsWith("audio/") -> "audio"
                        else -> continue
                    }
                    extractor.selectTrack(track)
                    while (true) {
                        if (active.cancelled.get()) return false
                        buffer.clear()
                        val size = extractor.readSampleData(buffer, 0)
                        if (size < 0) break
                        val sampleTimeUs = extractor.sampleTime.coerceAtLeast(0L)
                        info.set(0, size, sampleTimeUs + offsetUs, extractor.sampleFlags)
                        muxer.writeSampleData(outputTracks.getValue(kind), buffer, info)
                        segmentEndUs = maxOf(segmentEndUs, sampleTimeUs)
                        val progress = (((completedDurationUs + sampleTimeUs) * 99) / totalDurationUs)
                            .toInt()
                            .coerceIn(0, 99)
                        if (progress > lastProgress) {
                            lastProgress = progress
                            emitMergeProgress(progress)
                        }
                        extractor.advance()
                    }
                    extractor.unselectTrack(track)
                }
                val declaredDurationUs = firstFormats.values.mapNotNull { format ->
                    if (format.containsKey(MediaFormat.KEY_DURATION)) format.getLong(MediaFormat.KEY_DURATION) else null
                }.maxOrNull() ?: 0L
                offsetUs += maxOf(segmentEndUs + 1L, declaredDurationUs)
                completedDurationUs += sourceDurationsUs[sourceIndex]
            }
            muxer.stop()
            completed = true
            true
        } catch (error: Exception) {
            Log.i("VideoFuse", "fast merge unavailable; falling back to Transformer: ${error.message}")
            false
        } finally {
            try { muxer?.release() } catch (_: Exception) { }
            extractors.forEach { try { it.release() } catch (_: Exception) { } }
            if (!completed && output.exists()) output.delete()
        }
    }

    @OptIn(UnstableApi::class)
    private fun resolveOutputSize(paths: List<String>, outputResolution: String): OutputSize {
        when (outputResolution) {
            "1080p" -> return OutputSize(1920, 1080)
            "720p" -> return OutputSize(1280, 720)
        }
        val sourceSizes = paths.mapNotNull { path ->
            val extractor = MediaExtractor()
            try {
                setExtractorSource(extractor, path)
                (0 until extractor.trackCount).firstNotNullOfOrNull { track ->
                    val format = extractor.getTrackFormat(track)
                    val mime = format.getString(MediaFormat.KEY_MIME) ?: return@firstNotNullOfOrNull null
                    if (mime.startsWith("video/") &&
                        format.containsKey(MediaFormat.KEY_WIDTH) &&
                        format.containsKey(MediaFormat.KEY_HEIGHT)
                    ) {
                        OutputSize(
                            format.getInteger(MediaFormat.KEY_WIDTH),
                            format.getInteger(MediaFormat.KEY_HEIGHT),
                        )
                    } else {
                        null
                    }
                }
            } finally {
                extractor.release()
            }
        }
        if (sourceSizes.isEmpty()) return OutputSize(1920, 1080)
        if (outputResolution == "source" && sourceSizes.distinct().size == 1) {
            return sourceSizes.first()
        }
        return sourceSizes.maxBy { it.width.toLong() * it.height }
    }

    private fun startTransformerMerge(
        paths: List<String>,
        outputResolution: String,
        active: ActiveMerge,
    ) {
        if (!isActiveMerge(active) || active.cancelled.get()) return
        try {
            // A single output canvas prevents a visible size/aspect-ratio jump
            // at clip boundaries. SCALE_TO_FIT preserves each source aspect
            // ratio and uses black bars where the source does not match.
            val outputSize = resolveOutputSize(paths, outputResolution)
            val targetWidth = outputSize.width
            val targetHeight = outputSize.height
            val uniformEffects = Effects(
                emptyList(),
                listOf(
                    Presentation.createForWidthAndHeight(
                        targetWidth,
                        targetHeight,
                        Presentation.LAYOUT_SCALE_TO_FIT,
                    ),
                ),
            )
            val items = paths.map { path ->
                EditedMediaItem.Builder(MediaItem.fromUri(path)).build()
            }
            val sequence = EditedMediaItemSequence.withAudioAndVideoFrom(items)
            val composition = Composition.Builder(sequence)
                .setEffects(uniformEffects)
                // Force the normalized export path to process both tracks so
                // differing audio sample rates and codecs are handled by
                // Transformer instead of being copied through unchanged.
                .setTransmuxVideo(false)
                .setTransmuxAudio(false)
                .build()
            lateinit var transformer: Transformer
            transformer = Transformer.Builder(this)
                .setVideoMimeType("video/avc")
                .setAudioMimeType("audio/mp4a-latm")
                .addListener(object : Transformer.Listener {
                    override fun onCompleted(composition: Composition, exportResult: ExportResult) {
                        if (active.transformer !== transformer) return
                        Log.d("VideoFuse", "merge complete output=${active.output.absolutePath}")
                        finishMergeSuccess(active)
                    }

                    override fun onError(
                        composition: Composition,
                        exportResult: ExportResult,
                        exportException: ExportException,
                    ) {
                        if (active.transformer !== transformer) return
                        finishMergeError(
                            active,
                            "Video merge failed: ${exportException.message}",
                            exportException,
                        )
                    }
                })
                .build()
            try {
                // Transformer owns its application thread and performs the
                // actual transcode asynchronously. Starting it here keeps
                // creation and access on the same handler thread.
                active.transformer = transformer
                transformer.start(composition, active.output.absolutePath)
                scheduleTransformerProgress(active, transformer)
            } catch (error: Exception) {
                finishMergeError(active, "Could not start video merge: ${error.message}", error)
            }
        } catch (error: Exception) {
            finishMergeError(active, "Could not prepare video merge: ${error.message}", error)
        }
    }

    @OptIn(UnstableApi::class)
    private fun scheduleTransformerProgress(active: ActiveMerge, transformer: Transformer) {
        val progressHolder = ProgressHolder()
        val pollProgress = object : Runnable {
            override fun run() {
                if (!isActiveMerge(active) || active.cancelled.get()) return
                if (transformer.getProgress(progressHolder) == Transformer.PROGRESS_STATE_AVAILABLE) {
                    emitMergeProgress(progressHolder.progress)
                }
                mainHandler.postDelayed(this, 250)
            }
        }
        mainHandler.post(pollProgress)
    }
}
