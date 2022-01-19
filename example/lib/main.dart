import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:aero_f_ble/aero_f_ble.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  late StreamSubscription<BtDevice> _scanStream;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _scanStream.cancel();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platform;
    String version;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platform = await AeroFBle.platform;
      version = await AeroFBle.platformVersion;
      print(await AeroFBle.isAvailable);
      _scanStream = AeroFBle.scanUpdates.listen((BtDevice device) {
        print(device.toString());
      });
    } on PlatformException {
      platform = 'Failed to get platform and/or version.';
      version = '';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platform + " " + version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(children: [
            Text('Running on: $_platformVersion\n'),
            ElevatedButton(
              onPressed: () {
                print("OK!");
                AeroFBle.startScan(allowEmptyName: false);
              },
              child: const Text('Start'),
            ),
            ElevatedButton(
              onPressed: () {
                print("Nya!");
                AeroFBle.stopScan();
              },
              child: const Text('Stop'),
            ),
          ]),
        ),
      ),
    );
  }
}
