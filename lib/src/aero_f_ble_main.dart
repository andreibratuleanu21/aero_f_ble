import 'dart:async';

import 'package:flutter/services.dart';

// name is State. BOND State.
enum BondState {
  DISCONNECTED,
  CONNECTING,
  CONNECTED,
  DISCONNECTING
}

enum DeviceType {
  UNKNOWN,
  CLASSIC,
  LE,
  DUAL
}

enum AndroidScanMode {
  OPPORTUNISTIC,
  LOW_POWER,
  BALANCED,
  LOW_LATENCY
}


class AndroidScanOptions {
  final AndroidScanMode powerMode;

  AndroidScanOptions({this.powerMode = AndroidScanMode.LOW_POWER});
}

class AeroFBle {
  static const MethodChannel _methodChannel = const MethodChannel('aero_f_ble/method');
  static const EventChannel _eventChannel = const EventChannel('aero_f_ble/event');

  static Future<String> get platform async {
    try {
      final String? platform = await _methodChannel.invokeMethod<String>('getPlatform');
      return platform ?? "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  static Future<String> get platformVersion async {
    try {
      final String? version = await _methodChannel.invokeMethod<String>('getPlatformVersion');
      return version ?? "Unknown";
    } catch (e) {
      return "Unknown";
    }
  }

  static Future<bool> get isAvailable async {
    try {
      final bool? isUp = await _methodChannel.invokeMethod<bool>('isAvailable');
      return isUp == null ? false : isUp;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> startScan({
    List<String> serviceUUIDs = const [],
    int timeout = 0,
    bool allowEmptyName = true,
    bool allowDuplicates = false,
    AndroidScanOptions? androidOptions
  }) async {
    final AndroidScanOptions aso = androidOptions ?? AndroidScanOptions();
    final Map<String, dynamic> params = <String, dynamic>{
      "UUIDs": serviceUUIDs,
      "timeout": timeout,
      "allowEmpty": allowEmptyName,
      "duplicates": allowDuplicates,
      "android": <String, dynamic>{
        "mode": aso.powerMode.index - 1
      }
    };
    try {
      final bool? isUp = await _methodChannel.invokeMethod<bool>('startScan', params);
      return isUp == null ? false : isUp;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> stopScan() async {
    try {
      final bool? isUp = await _methodChannel.invokeMethod<bool>('stopScan');
      return isUp == null ? false : isUp;
    } catch (e) {
      return false;
    }
  }

  static Stream<BtDevice> get scanUpdates {
    return _eventChannel.receiveBroadcastStream().map((device) => BtDevice.fromMap(device as Map));
  }
}

class BtDevice {
  const BtDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.txPower,
    required this.connectable,
    required this.rawAdvertisingBytes,
    required this.type,
    required this.bondState
  });
  final String id;
  final String name;
  final int rssi;
  final int txPower;
  final bool connectable;
  final List<int> rawAdvertisingBytes;
  final DeviceType type;
  final BondState bondState;

  factory BtDevice.fromMap(Map map) {
    return BtDevice(
      id: map['id'] as String,
      name: map['name'] as String,
      rssi: map['rssi'] as int,
      txPower: map['txPwr'] as int,
      connectable: map['connect'] as bool,
      type: DeviceType.values[map['type'] as int],
      bondState: BondState.values[(map['bond'] as int) - 10],
      rawAdvertisingBytes: map["adv"] as List<int>
    );
  }

  @override
  String toString() {
    return "$id : $name : ${rawAdvertisingBytes.length} : ${bondState.toString()} : ${type.toString()}";
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BtDevice &&
      other.id == id &&
      other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
