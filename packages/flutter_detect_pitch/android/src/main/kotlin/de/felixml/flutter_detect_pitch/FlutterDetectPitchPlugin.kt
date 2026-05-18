package de.felixml.flutter_detect_pitch

import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import kotlin.concurrent.thread
import kotlin.math.sqrt

class FlutterDetectPitchPlugin : FlutterPlugin, EventChannel.StreamHandler {

  private var eventChannel: EventChannel? = null
  private var recorder: AudioRecord? = null
  private var recordingThread: Thread? = null
  @Volatile
  private var isRecording = false
  private var eventSink: EventChannel.EventSink? = null
  private val mainHandler = Handler(Looper.getMainLooper())

  companion object {
    private const val SAMPLE_RATE = 44100
    private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private const val AUDIO_FORMAT = AudioFormat.ENCODING_PCM_16BIT
    private const val BUFFER_SIZE = 2048
  }

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    eventChannel = EventChannel(binding.binaryMessenger, "pitch_stream")
    eventChannel?.setStreamHandler(this)
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    stopRecording()
    eventChannel?.setStreamHandler(null)
    eventChannel = null
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    eventSink = events
    startRecording()
  }

  override fun onCancel(arguments: Any?) {
    stopRecording()
  }

  private fun startRecording() {
    val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
    if (minBuf == AudioRecord.ERROR_BAD_VALUE || minBuf == AudioRecord.ERROR) {
      mainHandler.post {
        eventSink?.error("AUDIO_INIT", "getMinBufferSize failed", null)
      }
      return
    }
    val bufSize = kotlin.math.max(minBuf, BUFFER_SIZE * 2)
    val rec = try {
      AudioRecord(
        MediaRecorder.AudioSource.MIC,
        SAMPLE_RATE,
        CHANNEL_CONFIG,
        AUDIO_FORMAT,
        bufSize
      )
    } catch (e: Exception) {
      mainHandler.post {
        eventSink?.error("AUDIO_INIT", e.message, null)
      }
      return
    }
    if (rec.state != AudioRecord.STATE_INITIALIZED) {
      rec.release()
      mainHandler.post {
        eventSink?.error("AUDIO_INIT", "AudioRecord not initialized", null)
      }
      return
    }
    recorder = rec
    try {
      rec.startRecording()
    } catch (e: Exception) {
      rec.release()
      recorder = null
      mainHandler.post {
        eventSink?.error("AUDIO_START", e.message, null)
      }
      return
    }
    isRecording = true
    val readLen = BUFFER_SIZE.coerceAtMost(bufSize / 2).coerceAtLeast(256)
    recordingThread = thread(start = true, name = "pitch-detect") {
      val buffer = ShortArray(readLen)
      while (isRecording) {
        val r = recorder?.read(buffer, 0, readLen) ?: 0
        if (r > 0) {
          val rmsLin = rmsS16(buffer, r)
          val frequency = detectFrequency(buffer, r)
          if (frequency > 0 && isRecording) {
            val hz = frequency.toDouble()
            val norm = (rmsLin / 11000.0).coerceIn(0.0, 1.0)
            mainHandler.post {
              if (isRecording) {
                eventSink?.success(
                  mapOf(
                    "hz" to hz,
                    "rms" to norm,
                  ),
                )
              }
            }
          }
        }
      }
    }
  }

  private fun stopRecording() {
    isRecording = false
    try {
      recordingThread?.join(1500)
    } catch (_: InterruptedException) {
    }
    recordingThread = null
    val rec = recorder
    recorder = null
    if (rec != null) {
      try {
        rec.stop()
      } catch (_: IllegalStateException) {
      } catch (_: Exception) {
      }
      try {
        rec.release()
      } catch (_: Exception) {
      }
    }
  }

  private fun rmsS16(buffer: ShortArray, n: Int): Double {
    if (n <= 0) {
      return 0.0
    }
    var acc = 0.0
    for (i in 0 until n) {
      val v = buffer[i].toDouble()
      acc += v * v
    }
    return sqrt(acc / n)
  }

  private fun detectFrequency(buffer: ShortArray, read: Int): Float {
    var numCrossings = 0
    for (i in 1 until read) {
      if ((buffer[i - 1] > 0 && buffer[i] <= 0) || (buffer[i - 1] < 0 && buffer[i] >= 0)) {
        numCrossings++
      }
    }
    val durationInSeconds = read.toFloat() / SAMPLE_RATE
    return if (durationInSeconds > 0) {
      (numCrossings / 2f) / durationInSeconds
    } else {
      0f
    }
  }
}
