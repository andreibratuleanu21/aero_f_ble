//
//  BleManager.swift
//  aero_f_ble
//
//  Created by abratule on 05.01.2022.
//

import Flutter
import Foundation
import CoreBluetooth
import Flutter

class BleManager: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, FlutterStreamHandler {
    
    private let _executor: AeroExecutor = AeroExecutor()
    private var _resultCallback: FlutterResult?
    private var _btManager: CBCentralManager?
    private var sink: FlutterEventSink?
    private var timer: Timer?
    private var allowEmptyName: Bool = true

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        sink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        sink = nil
        _btManager?.stopScan()
        return nil
    }

    var isAvailable: Bool {
        get {
            return _btManager?.state == .poweredOn
        }
    }
    
    var isConnected: Bool {
        get {
            return _connectedDevice != nil
        }
    }
    
    private var _availableDevices: [CBPeripheral] = []
    private var _availableDevicesMap: [[String:String]] {
        get {
            return _availableDevices.map({
                (device: CBPeripheral) -> [String:String] in
                return device.toMap()
            })
        }
    }

    private var _connectedDevice: CBPeripheral?
    var connectedDevice: [String:String]? {
        get {
            return _connectedDevice?.toMap()
        }
    }
    
    private var _connectedDeviceService: CBService?
    private var _connectedDeviceCharacteristic: CBCharacteristic?

    func initialize() {
        _btManager = CBCentralManager(
            delegate: self,
            queue: .global(qos: .background)
        )
    }
    
    func startScan(serviceUUIDs: [String]?, timeout: Int, duplicates: Bool, allowEmpty: Bool) -> Bool {
        _availableDevices.removeAll()
        allowEmptyName = allowEmpty;
        var cbUUIDs: [CBUUID] = []
        if serviceUUIDs != nil {
            for (service) in serviceUUIDs! {
                let cbUUID: CBUUID? = CBUUID(string: service)
                if cbUUID != nil {
                    cbUUIDs.append(cbUUID!)
                }
            }
        }
        _btManager?.scanForPeripherals(
            withServices: cbUUIDs.count > 0 ? cbUUIDs : nil,
            options: [
                CBCentralManagerScanOptionAllowDuplicatesKey: duplicates
            ]
        )
        if timeout > 0 {
            _executor.add { [weak self] in
                self?._executor.delayed(deadline: .now() + .milliseconds(timeout)) {
                    self?._btManager?.stopScan()
                }
            }
        }
        return _btManager?.state == .poweredOn && _btManager?.isScanning == true;
    }
    
    func stopScan() -> Bool {
        _btManager?.stopScan()
        return _btManager?.state == .poweredOn && _btManager?.isScanning == false;
    }
    
    func connect(uuidString: String, resultCallback: @escaping FlutterResult) {
        _executor.add { [weak self] in
            do {
                let uuid: UUID = UUID(uuidString: uuidString)!
                
                guard let peripheral: CBPeripheral = self?._availableDevices.first(where: {
                    (peripheral: CBPeripheral) -> Bool in
                    return peripheral.identifier == uuid
                }) else {
                    throw BleError(message: "Device not found!")
                }
                
                self?._resultCallback = resultCallback
                self?._btManager?.connect(peripheral)
                                      
            } catch let e as BleError {
                resultCallback(e.toFlutterError())
            } catch let e {
                resultCallback(FlutterError(
                    code: "BLE_ERROR",
                    message: e.localizedDescription,
                    details: "connect"
                ))
            }
        }
        
    }
    
    func sendBytes(_ bytes: Data, resultCallback: @escaping FlutterResult) {
        _executor.add(onCompleteNext: true) { [weak self] in
            do {
                guard let connectedDevice: CBPeripheral = self?._connectedDevice else {
                    throw BleError(message: "No device connected!")
                }
                
                if self?._connectedDeviceService == nil {
                    throw BleError(message: "Failed to send bytes!")
                }
                
                guard let characteristic: CBCharacteristic = self?._connectedDeviceCharacteristic else {
                    throw BleError(message: "The device does not support receiving bytes!")
                }
                
                connectedDevice.writeValue(
                    bytes,
                    for: characteristic,
                    type: .withoutResponse
                )
                
                resultCallback(true)
                
            } catch let e as BleError {
                resultCallback(e.toFlutterError())
            } catch let e {
                resultCallback(FlutterError(
                    code: "BLE_ERROR",
                    message: e.localizedDescription,
                    details: nil
                ))
            }
            
        }
    }
    
    func disconnect(_ resultCallback: @escaping FlutterResult) {
        guard let connectedDevice: CBPeripheral = _connectedDevice else {
            return
        }
        _executor.add { [weak self] in
            self?._resultCallback = resultCallback
            self?._btManager?.cancelPeripheralConnection(connectedDevice)
        }
        
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {}
    
    func centralManager(
        _ central: CBCentralManager,
        didConnect peripheral: CBPeripheral
    ) {
        _connectedDevice = peripheral
        _connectedDevice!.delegate = self
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _connectedDevice!.discoverServices(nil)
        
        _resultCallback?(connectedDevice!)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        _connectedDevice = nil
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _resultCallback?(error ?? true)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        _connectedDevice = nil
        _connectedDeviceService = nil
        _connectedDeviceCharacteristic = nil
        _resultCallback?(error)
        _resultCallback = nil
        _executor.next()
    }
    
    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String : Any],
        rssi RSSI: NSNumber
    ) {
        let alreadyExists: Bool = _availableDevices.contains(
            where: { $0.identifier == peripheral.identifier }
        )
        if !alreadyExists {
            if allowEmptyName == false && peripheral.name == nil {
                return;
            }
            _availableDevices.append(peripheral)
            guard let sink = sink else { return }
            sink(_availableDevicesMap)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services: [CBService] = peripheral.services, error == nil else {
            _connectedDeviceService = nil
            return
        }
        
        guard let service: CBService = services.first(where: { $0.isPrimary }) else {
            _connectedDeviceService = nil
            return
        }
        
        _connectedDeviceService = service
        peripheral.discoverCharacteristics(nil, for: service)
    }
    
    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        for characteristic in service.characteristics! {
            if characteristic.properties.contains(.writeWithoutResponse) {
                _connectedDeviceCharacteristic = characteristic
                break
            }
        }
        
    }

}

extension CBPeripheral {
    
    func toMap() -> [String: String] {
        return [
            "id": identifier.uuidString,
            "name": name ?? "Unknown"
        ]
    }
}
