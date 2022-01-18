import Flutter
import CoreBluetooth

public class SwiftAeroPlugin: NSObject, FlutterPlugin {
    
    private let _bleManager: BleManager
    
    init(_ bleMgr: BleManager) {
        _bleManager = bleMgr
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel: FlutterMethodChannel = FlutterMethodChannel(
            name: "aero_f_ble/method",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "aero_f_ble/event",
            binaryMessenger: registrar.messenger()
        )
        let bleMgr: BleManager = BleManager()
        bleMgr.initialize()
        let instance: SwiftAeroPlugin = SwiftAeroPlugin(bleMgr)
        eventChannel.setStreamHandler(bleMgr)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "isAvailable":
                let isAvailable: Bool? = _bleManager.isAvailable
                result(isAvailable)
            case "startScan":
                guard let data: [String:Any] = call.arguments as? Dictionary<String, Any> else {
                    throw BleError(message: "Invalid argument for method ['startScan']")
                }
                guard let serviceUUIDs: [String]? = data["UUIDs"] as? [String]? else {
                    throw BleError(message: "Invalid payload for ['serviceUUIDs']")
                }
                guard let timeout: Int = data["timeout"] as? Int else {
                    throw BleError(message: "Invalid payload for ['timeout']")
                }
                guard let duplicates: Bool = data["duplicates"] as? Bool else {
                    throw BleError(message: "Invalid payload for ['allowDuplicates']")
                }
                guard let allowEmpty: Bool = data["allowEmpty"] as? Bool else {
                    throw BleError(message: "Invalid payload for ['allowEmptyName']")
                }
                let isOk: Bool = _bleManager.startScan(serviceUUIDs: serviceUUIDs, timeout: timeout, duplicates: duplicates, allowEmpty: allowEmpty)
                result(isOk)
            case "stopScan":
                let isOk: Bool = _bleManager.stopScan()
                result(isOk)
            case "connectedDevice":
                let connectedDevice: [String:String]? = _bleManager.connectedDevice
                result(connectedDevice)
            case "getAvailableDevices":
                print("meow")
                //_bleManager.getAvailableDevices(result)
            case "connect":
                throw BleError(message: "Invalid argument for method [connect]")
//                _bleManager.connect(
//                    uuidString: uuidString,
//                    resultCallback: result
//                )
            case "disconnect":
                _bleManager.disconnect(result)
            case "sendBytes":
                guard let data: [String:Any] = call.arguments as? [String:Any] else {
                    throw BleError(message: "Invalid argument for method [sendBytes]")
                }
                
                guard let bytes: FlutterStandardTypedData = data["bytes"] as? FlutterStandardTypedData else {
                    throw BleError(message: "Invalid payload for ['bytes']")
                }
                               
                _bleManager.sendBytes(bytes.data, resultCallback: result)
            case "getPlatform":
                result("iOS")
            case "getPlatformVersion":
                result(UIDevice.current.systemVersion)
            default:
                result(FlutterMethodNotImplemented)
            }
        } catch let e as BleError {
            result(e.toFlutterError())
        } catch let e {
            result(FlutterError(
                code: "BLE_ERROR",
                message: "Uncaught error.",
                details: e.localizedDescription
            ))
        }
    }
}
