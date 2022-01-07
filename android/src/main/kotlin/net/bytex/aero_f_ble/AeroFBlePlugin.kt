package net.bytex.aero_f_ble

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.content.Context
import android.content.ContextWrapper
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.content.ContextCompat.getSystemService

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import no.nordicsemi.android.support.v18.scanner.*


/** AeroFBlePlugin */
class AeroFBlePlugin: FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
  private lateinit var methodChannel : MethodChannel
  private lateinit var eventChannel : EventChannel
  private lateinit var appContext: Context
  private val btManager : BleManager = BleManager()

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    appContext = flutterPluginBinding.applicationContext;
    methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "aero_f_ble/method")
    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "aero_f_ble/event")
    methodChannel.setMethodCallHandler(this)
    eventChannel.setStreamHandler(this)

  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) = try {
    when (call.method) {
      "getPlatform" -> {
        result.success("Android")
      }
      "isAvailable" -> {
        val bluetoothManager = appContext.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
        if (bluetoothManager.adapter == null) {
          result.success(false)
        }
        result.success(bluetoothManager.adapter.isEnabled)
      }
      "getPlatformVersion" -> {
        result.success(android.os.Build.VERSION.RELEASE)
      }
      "startScan" -> {
        val serviceUuids : List<String> = call.argument<List<String>>("serviceUUIDs") ?: emptyList()
        val timeout : Long = (call.argument<Int>("timeout") ?: 0).toLong()
        val duplicates : Boolean = call.argument<Boolean>("duplicates") ?: false
        val allowEmpty : Boolean = call.argument<Boolean>("allowEmptyName") ?: true
        val options : Map<String, Any>? = call.argument<Map<String, Any>>("android")
        btManager.startScan(serviceUuids, timeout, duplicates, allowEmpty, options)
        result.success(true)
      }
      "stopScan" -> {
        btManager.stopScan()
        result.success(true)
      }
      else -> result.notImplemented()
    }
  } catch (e: Exception) {
    Log.e("aero_internal", e.message ?: "Unknown")
    result.error(
      "BLE_ERROR",
      e.message,
      e.cause
    )
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
    btManager.dispose()
  }

  override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
    if (sink != null) {
      btManager.setNewSink(sink)
    }
  }

  override fun onCancel(arguments: Any?) {
    btManager.rmSink()
  }
}
