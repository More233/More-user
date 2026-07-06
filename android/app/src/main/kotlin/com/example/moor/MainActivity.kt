package com.example.moor

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.nio.ByteBuffer
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.app.more/video_utils"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "stripAudio") {
                val inputPath = call.argument<String>("inputPath")
                val outputPath = call.argument<String>("outputPath")
                if (inputPath == null || outputPath == null) {
                    result.error("INVALID_ARGUMENTS", "Arguments must be inputPath and outputPath", null)
                    return@setMethodCallHandler
                }
                thread {
                    val error = stripAudio(inputPath, outputPath)
                    runOnUiThread {
                        if (error == null) {
                            result.success(outputPath)
                        } else {
                            result.error("EXPORT_FAILED", error, null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    private fun stripAudio(inputPath: String, outputPath: String): String? {
        val extractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        try {
            extractor.setDataSource(inputPath)
            
            var videoTrackIndex = -1
            var videoFormat: MediaFormat? = null
            for (i in 0 until extractor.trackCount) {
                val format = extractor.getTrackFormat(i)
                val mime = format.getString(MediaFormat.KEY_MIME) ?: ""
                if (mime.startsWith("video/")) {
                    videoTrackIndex = i
                    videoFormat = format
                    break
                }
            }
            
            if (videoTrackIndex == -1 || videoFormat == null) {
                return "No video track found"
            }
            
            extractor.selectTrack(videoTrackIndex)
            
            muxer = MediaMuxer(outputPath, MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4)
            val writeTrackIndex = muxer.addTrack(videoFormat)
            
            muxer.start()
            
            val maxBufferSize = videoFormat.getInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 1024 * 1024)
            val buffer = ByteBuffer.allocate(maxBufferSize)
            val bufferInfo = android.media.MediaCodec.BufferInfo()
            
            while (true) {
                bufferInfo.offset = 0
                bufferInfo.size = extractor.readSampleData(buffer, 0)
                if (bufferInfo.size < 0) {
                    break
                }
                bufferInfo.presentationTimeUs = extractor.sampleTime
                bufferInfo.flags = extractor.sampleFlags
                muxer.writeSampleData(writeTrackIndex, buffer, bufferInfo)
                extractor.advance()
            }
            
            muxer.stop()
            return null
        } catch (e: Exception) {
            return e.localizedMessage ?: "Unknown error"
        } finally {
            try {
                extractor.release()
            } catch (e: Exception) {}
            try {
                muxer?.release()
            } catch (e: Exception) {}
        }
    }
}
