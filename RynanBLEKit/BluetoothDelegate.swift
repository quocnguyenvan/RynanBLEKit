//
//  BluetoothDelegate.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import CoreBluetooth

/**
 *  Bluetooth Model Delegate
 */
@objc public protocol BluetoothDelegate : class {
    
    /** Gọi khi state bluetooth được update. */
    @objc optional func didUpdateState(_ state: CBManagerState)
    
    /** Gọi khi peripheral được scan thấy. */
    @objc optional func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber)
    
    /** Gọi khi peripheral đã kết nối thành công. */
    @objc optional func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral)
    
    /** Gọi khi peripheral đã kết nối thất bại. */
    @objc optional func failToConnectPeripheral(_ peripheral: CBPeripheral, error: Error)
    
    /** Gọi khi services đã discovered. */
    @objc optional func didDiscoverServices(_ peripheral: CBPeripheral)
    
    /** Gọi khi peripheral đã ngắt kết nối. */
    @objc optional func didDisconnectPeripheral(_ peripheral: CBPeripheral)
    
    /** The callback function when interrogate the peripheral is timeout */
    @objc optional func didFailedToInterrogate(_ peripheral: CBPeripheral)
    
    /** Gọi khi TÌM THẤY characteritics. */
    @objc optional func didDiscoverCharacteritics(_ service: CBService)
    
    /** Gọi khi KHÔNG tìm thấy characteritics. */
    @objc optional func didFailToDiscoverCharacteritics(_ error: Error)
    
    /** Discover descriptor for characteristic successfully */
    @objc optional func didDiscoverDescriptors(_ characteristic: CBCharacteristic)
    
    /** Failed to discover descriptor for characteristic. */
    @objc optional func didFailToDiscoverDescriptors(_ error: Error)
    
    /** Gọi khi đọc giá trị của characteristic thành công. */
    @objc optional func didReadValueForCharacteristic(_ characteristic: CBCharacteristic)
    
    /** Gọi khi đọc giá trị của characteristic thất bại. */
    @objc optional func didFailToReadValueForCharacteristic(_ error: Error)
}
