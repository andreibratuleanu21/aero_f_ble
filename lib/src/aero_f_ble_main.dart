import 'dart:async';

import 'package:flutter/services.dart';

class AeroFBle {
  static const MethodChannel _methodChannel = const MethodChannel('aero_f_ble/method');
  static const EventChannel _eventChannel = const EventChannel('aero_f_ble/event');

  static Future<String> get platform async {
    final String? platform = await _methodChannel.invokeMethod<String>('getPlatform');
    return platform ?? "Unknown platform";
  }

  static Future<String> get platformVersion async {
    final String? version = await _methodChannel.invokeMethod<String>('getPlatformVersion');
    return version ?? "Unknown version";
  }

  static Future<bool> get isAvailable async {
    final bool? isUp = await _methodChannel.invokeMethod<bool>('isAvailable');
    return isUp == null ? false : isUp;
  }

  static Future<bool> startScan({List<String> serviceUUIDs = const [], int timeout = 0, bool allowDuplicates = false, bool allowEmptyName = true}) async {
    final Map<String, dynamic> params = <String, dynamic>{
      "serviceUUIDs": serviceUUIDs,
      "timeout": timeout,
      "duplicates": allowDuplicates,
      "allowEmptyName": allowEmptyName
    };
    final bool? isUp = await _methodChannel.invokeMethod<bool>('startScan', params);
    return isUp == null ? false : isUp;
  }

  static Future<bool> stopScan() async {
    final bool? isUp = await _methodChannel.invokeMethod<bool>('stopScan');
    return isUp == null ? false : isUp;
  }

  static Stream<List<BtDevice>> get scanUpdates {
    return _eventChannel.receiveBroadcastStream().map((devices) => List<BtDevice>.from(devices.map((device) => BtDevice.fromMap(device as Map))));
  }
}

class BtDevice {
  const BtDevice({
    required this.id,
    required this.name,
  });
  final String id;
  final String name;

  factory BtDevice.fromMap(Map map) {
    return BtDevice(
      id: map['id'] as String,
      name: map['name'] as String,
    );
  }

  @override
  String toString() {
    return "$id : $name";
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
