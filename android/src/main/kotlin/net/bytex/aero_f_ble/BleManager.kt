package net.bytex.aero_f_ble

import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.EventChannel
import no.nordicsemi.android.support.v18.scanner.*

class BleManager: ScanCallback() {
    private var scanner : BluetoothLeScannerCompat? = null;
    private var allowEmpty : Boolean = true
    private var allowDuplicates : Boolean = false
    private var settings : ScanSettings = ScanSettings.Builder().build()
    private var sink : EventChannel.EventSink? = null

    fun startScan(serviceUuids : List<String>, timeout : Long, duplicates : Boolean, allowEmptyNames : Boolean, options : Map<String, Any>?) {
        if (scanner == null) {
            scanner = BluetoothLeScannerCompat.getScanner()
            allowEmpty = allowEmptyNames
            allowDuplicates = duplicates
            if (options != null) {
                settings = ScanSettings.Builder().setScanMode(options["mode"] as Int).build()
            }
            if (timeout > 0) {
                Handler(Looper.getMainLooper()).postDelayed({
                    stopScan()
                }, timeout)
            }
            val filters : MutableList<ScanFilter> = mutableListOf<ScanFilter>()
            if (serviceUuids.isNotEmpty()) {
                for (uuidStr in serviceUuids) {
                    filters.add(
                        ScanFilter.Builder().setServiceUuid(ParcelUuid.fromString(uuidStr)).build()
                    )
                }
            }
            scanner!!.startScan(filters, settings, this)
        }
    }

    fun stopScan() {
        if (scanner != null) {
            scanner!!.stopScan(this)
            scanner = null
        }
    }

    fun setNewSink(ns : EventChannel.EventSink) {
        sink = ns
    }

    fun rmSink() {
        sink = null
    }

    fun dispose() {
        stopScan()
        rmSink()
    }

    override fun onScanResult(callbackType: Int, result: ScanResult) {
        val newDevice : Map<String, Any?> = mapOf<String, Any?>(
            "id" to result.device.address,
            "mac" to result.device.address,
            "name" to ((result.scanRecord?.deviceName ?: result.device.name) ?: "Unknown"),
            "rssi" to result.rssi,
            "txPwr" to result.txPower,
            "connect" to result.isConnectable,
            "adv" to result.scanRecord?.bytes,
            "bond" to result.device.bondState,
            "type" to result.device.type,
        )
        if (allowEmpty || newDevice["name"] != "Unknown") {
            sink?.success(newDevice)
        }
    }

    override fun onBatchScanResults(results: List<ScanResult?>) {
        Log.d("aero_internal", "Batch something...")
    }

    override fun onScanFailed(errorCode: Int) {
        Log.d("aero_internal", "Scan failed")
    }
}