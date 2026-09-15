package com.videofuse.app

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.media.MediaMuxer
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.util.Log
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import android.provider.MediaStore
import androidx.media3.common.MediaItem
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.SeekParameters
import androidx.media3.inspector.frame.FrameExtractor
import com.google.common.util.concurrent.Futures
import java.io.FileInputStream
import java.util.concurrent.Executors
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.roundToInt

private const val CHANNEL = "com.videofuse.processing"

class MainActivity : FlutterActivity() {
    private val processingExecutor = Executors.newFixedThreadPool(2)
    private var pendingPickerResult: MethodChannel.Result? = null
    private val pickerRequestCode = 4107

    override fun onDestroy() {
        processingExecutor.shutdownNow()
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                    "saveToDownloads" -> result.success(saveToDownloads(call.argument<String>("inputPath")!!, call.argument<String>("displayName")!!))
                    "stitchVideos" -> result.success(stitchVideos(call.argument<List<String>>("inputPaths")!!))
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

    private fun stitchVideos(paths: List<String>): String {
        require(paths.size >= 2) { "Select at least two videos" }
        val first = MediaExtractor()
        setExtractorSource(first, paths[0])
        val output = File.createTempFile("videofuse_stitched_", ".mp4", cacheDir)
        val muxer = MediaMuxer(output.absolutePath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
        val trackMap = HashMap<Int, Int>()
        for (i in 0 until first.trackCount) trackMap[i] = muxer.addTrack(first.getTrackFormat(i))
        muxer.start()
        val buffer = java.nio.ByteBuffer.allocate(1024 * 1024)
        val info = MediaCodec.BufferInfo()
        var videoOffset = 0L
        for (path in paths) {
            val extractor = MediaExtractor()
            setExtractorSource(extractor, path)
            for (track in 0 until extractor.trackCount) {
                extractor.selectTrack(track)
                var sampleTime: Long
                while (extractor.readSampleData(buffer, 0) >= 0) {
                    sampleTime = extractor.sampleTime
                    info.offset = 0
                    info.size = extractor.sampleSize.toInt()
                    info.presentationTimeUs = sampleTime + videoOffset
                    info.flags = extractor.sampleFlags
                    muxer.writeSampleData(trackMap[track] ?: continue, buffer, info)
                    extractor.advance()
                }
                extractor.unselectTrack(track)
            }
            videoOffset += 1_000_000L
            extractor.release()
        }
        muxer.stop(); muxer.release(); first.release()
        return output.absolutePath
    }
}
