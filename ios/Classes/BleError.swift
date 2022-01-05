//
//  BleError.swift
//  aero_f_ble
//
//  Created by abratule on 05.01.2022.
//

import Flutter
import Foundation

struct BleError: Error {
    let message: String
    
    func toFlutterError() -> FlutterError {
        return FlutterError(
            code: "BLE_ERROR",
            message: message,
            details: nil
        )
    }
}
