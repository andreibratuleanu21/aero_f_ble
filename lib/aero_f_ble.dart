
import 'dart:async';

import 'package:flutter/services.dart';

class AeroFBle {
  static const MethodChannel _channel =
      const MethodChannel('aero_f_ble');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
