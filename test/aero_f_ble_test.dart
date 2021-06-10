import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aero_f_ble/aero_f_ble.dart';

void main() {
  const MethodChannel channel = MethodChannel('aero_f_ble');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await AeroFBle.platformVersion, '42');
  });
}
