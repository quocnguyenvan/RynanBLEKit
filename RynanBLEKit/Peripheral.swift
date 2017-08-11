//
//  Peripheral.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import CoreBluetooth

// MARK: - Peripheral -

public class Peripheral: NSObject, CBPeripheralDelegate {
    
    private let peripheral: CBPeripheral?
    private let centralManager: CentralManager?
    
    init(peripheral: CBPeripheral, centralManager: CentralManager) {
//        peripheral.delegate = Peripheral as? CBPeripheralDelegate
        self.peripheral = peripheral
        self.centralManager = centralManager
        super.init()
    }
    
    /** Read value of characteristic */
    func readValueForCharacteristic(characteristic: CBCharacteristic) {
        guard let peripheral = peripheral else { return }
        peripheral.readValue(for: characteristic)
    }
    
    /** Write value for characteristic */
    func writeValue(data: Data, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType = .withResponse) {
        guard let peripheral = peripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    /** Set notification */
    func setNotification(enable: Bool, forCharacteristic characteristic: CBCharacteristic){
        guard let peripheral = peripheral else { return }
        peripheral.setNotifyValue(enable, for: characteristic)
    }
    
    /** Services were discoverd */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Peripheral -> didDiscoverServices")
    }
    
    /** Characteristics were discovered */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Peripheral -> didDiscoverCharacteristics")
    }
    
    /** Discovery descriptor when the peripheral has found the descriptor for the characteristic */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("Peripheral -> didDiscoverDescriptors")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Peripheral -> didWriteValue")
    }
    
    /** Update value */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Peripheral -> didUpdateValue")
    }
    
}
