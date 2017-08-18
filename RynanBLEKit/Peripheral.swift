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
    
    public var peripheral: CBPeripheral?
    private var centralManager: CentralManager?
    fileprivate var rnCharacteristic: CBCharacteristic?
    fileprivate var rnService: CBService?
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
//        self.centralManager = centralManager
        super.init()
        self.peripheral?.delegate = self
    }
    
    deinit {
        self.peripheral?.delegate = nil
    }
    
    class func deviceServiceUUID() -> CBUUID{
        return CBUUID(string:"181C")
    }
    
    class func deviceCharacteristicUUID() -> CBUUID{
        return CBUUID(string:"2A99")
    }
    
    public var state: CBPeripheralState {
        return (peripheral?.state)!
    }
    
    public var isConnected: Bool {
        return peripheral?.state == .connected
    }
    
    public var name: String? {
        return peripheral?.name ?? "Unknown"
    }
    
    public var identifier: UUID {
        return (peripheral?.identifier)!
    }
    
    public var service: [CBService]? {
        guard let services = peripheral?.services else { return nil }
    
        return services // filter { $0.uuid.uuidString == serviceUUID }.first
    }

    /** Read value of characteristic */
    func readData(for characteristic: CBCharacteristic) {
        guard let peripheral = peripheral else { return }
        peripheral.readValue(for: characteristic)
    }
    
    /** Write value for characteristic */
    func writeData(data: Data, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType = .withResponse) {
        guard let peripheral = peripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    /** Set notification */
    func setNotify(enable: Bool, forCharacteristic characteristic: CBCharacteristic){
        guard let peripheral = peripheral else { return }
        peripheral.setNotifyValue(enable, for: characteristic)
    }
    
    /** Services were discoverd */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Peripheral -> didDiscoverServices")
        guard let services = peripheral.services else { return }
        for service in services {
            if service.uuid.uuidString == "181C" {
                peripheral.discoverCharacteristics(nil, for: service)
                print("didDiscoverServices: \(service)")
            }
        }
    }
    
    /** Characteristics were discovered */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Peripheral -> didDiscoverCharacteristics")
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid.uuidString == "2A99" {
                // If it is, subscribe to it
                peripheral.setNotifyValue(true, for: thisCharacteristic)
            }
        }
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
