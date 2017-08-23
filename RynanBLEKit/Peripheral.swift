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
    
    public var peripheral: CBPeripheral
    
    public typealias ConnectionHandler = ((Bool) -> Void)
    public typealias ServiceDiscovery = (([CBService], Error?) -> Void)
    public typealias CharacteristicDiscovery = ((CBService, [CBCharacteristic], Error?) -> Void)
    public typealias ReadHandler = ((Data?, Error?) -> Void)
    public typealias WriteHandler = ((Error?) -> Void)
    
    open var discoveredServices = [CBService: [CBCharacteristic]]()
    
    private var centralManager: CentralManager
    fileprivate var connectionHandler: ConnectionHandler?
    // Should these handlers be queues?
    fileprivate var serviceDiscoveryHandler: ServiceDiscovery?
    fileprivate var characteristicDiscoveryHandler: CharacteristicDiscovery?
    fileprivate var readHandler: ReadHandler?
    fileprivate var writeHandler: WriteHandler?
    
    fileprivate var notificationHandler = [CBCharacteristic: ReadHandler]()
    
    fileprivate var autoReconnect = false
    
    init(centralManager: CentralManager, peripheral: CBPeripheral) {
        self.centralManager = centralManager
        self.peripheral = peripheral
//        super.init()
        self.peripheral.delegate = centralManager // self
    }
    
    convenience init(_ copy: Peripheral) {
        self.init(centralManager: copy.centralManager, peripheral: copy.peripheral)
    }
    
    deinit {
        self.peripheral.delegate = nil
    }
    
    class func deviceServiceUUID() -> CBUUID{
        return CBUUID(string:"181C")
    }
    
    class func deviceCharacteristicUUID() -> CBUUID{
        return CBUUID(string:"2A99")
    }
    
    public var state: CBPeripheralState {
        return peripheral.state
    }
    
    public var isConnected: Bool {
        return peripheral.state == .connected
    }
    
    public var name: String? {
        return peripheral.name ?? "Unknown"
    }
    
    public var identifier: UUID {
        return peripheral.identifier
    }
    
    public var uuidString: String {
        return peripheral.identifier.uuidString
    }
    
    open var id: String {
        return peripheral.identifier.uuidString
    }
    
    public var service: [CBService]? {
        guard let services = peripheral.services else { return nil }
    
        return services // filter { $0.uuid.uuidString == serviceUUID }.first
    }
    
    open func connect(with timeout: TimeInterval? = nil, autoReconnect: Bool = true, complete: ConnectionHandler?) {
        print("Calling connect")
        self.connectionHandler = complete
        self.autoReconnect = autoReconnect
        self.centralManager.connectPeripheral(self)
    }
    
    open func disconnect(autoReconnect: Bool = false) {
        print("Calling disconnect")
        self.autoReconnect = autoReconnect
        self.centralManager.disconnectPeripheral(self)
    }
    
    open func discoverServices(with uuids: [CBUUID]? = nil, complete: ServiceDiscovery?) {
        guard isConnected == true else {
            print("Not connected - cannot discoverServices")
            return
        }
        serviceDiscoveryHandler = complete
        print("discoverServices: \(self.peripheral) \(String(describing: self.peripheral.delegate))")
        self.peripheral.discoverServices(uuids)
    }
    
    open func discoverCharacteristics(with uuids: [CBUUID]? = nil, for service: CBService, complete: CharacteristicDiscovery?) {
        guard isConnected == true else {
            print("Not connected - cannot discoverCharacteristics")
            return
        }
        characteristicDiscoveryHandler = complete
        print("discoverCharacteristics")
        peripheral.discoverCharacteristics(uuids, for: service)
    }
    
    open func read(from characteristic: String, in service: String, complete: ReadHandler?) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Not connected - cannot read")
            return
        }
        readHandler = complete
        peripheral.readValue(for: targetCharacteristic)
    }
    
    open func write(data: Data, to characteristic: String, in service: String, complete: WriteHandler? = nil) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Not connected - cannot write")
            return
        }
        writeHandler = complete
        var writeType = CBCharacteristicWriteType.withResponse
        if complete == nil {
            writeType = .withoutResponse
        }
        peripheral.writeValue(data, for: targetCharacteristic, type: writeType)
    }
    
    open func subscribe(to characteristic: String, in service: String, complete: ReadHandler?) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Not connected - cannot write")
            return
        }
        
        guard targetCharacteristic.isNotifying == false else {
            return
        }
        
        // TODO: Can using just the characteristic UUID cause a conflict if there is an identical characteristic in another service? Can't recall if legal
        notificationHandler[targetCharacteristic] = complete
        peripheral.setNotifyValue(true, for: targetCharacteristic)
    }
    
    // TODO: Faster probably to just iterate through the notification handler instead of current method
    open func unsubscribe(from characteristic: String, in service: String) {
        guard let targetService = peripheral.services?.find(uuidString: service),
            let targetCharacteristic = targetService.characteristics?.find(uuidString: characteristic) else {
                return
        }
        
        guard isConnected == true else {
            print("Not connected - cannot write")
            return
        }
        
        guard targetCharacteristic.isNotifying == true else {
            return
        }
        notificationHandler.removeValue(forKey: targetCharacteristic)
        peripheral.setNotifyValue(false, for: targetCharacteristic)
    }
    
    func didConnect() {
        print("didConnect: Calling connection handler: Is handler nil? \(connectionHandler == nil)")
        connectionHandler?(true)
    }
    
    func didDisconnect() {
        print("didDisconnect: Calling disconnection handler: Is handler nil? \(connectionHandler == nil)")
        connectionHandler?(false)
        if autoReconnect == true {
            connect(complete: connectionHandler)
        }
    }
    
    func didUpdateName() { }
    
    func didModifyServices(invalidatedServices: [CBService]) { }
    
    func didUpdateRSSI(error: Error?) { }
    
    func didReadRSSI(RSSI: NSNumber, error: Error?) { }
    
    func didDiscoverServices(error: Error?) {
        discoveredServices.removeAll()
        
        peripheral.services?.forEach({ service in
            print("Service Discovered: \(service.uuid.uuidString)")
            discoveredServices[service] = [CBCharacteristic]()
        })
        
        serviceDiscoveryHandler?(Array(discoveredServices.keys), error)
    }
    
    func didDiscoverIncludedServicesFor(service: CBService, error: Error?) { }
    
    func didDiscoverCharacteristicsFor(service: CBService, error: Error?) {
        discoveredServices[service]?.removeAll()
        
        var characteristics = [CBCharacteristic]()
        service.characteristics?.forEach({ characteristic in
            print("Characteristic Discovered: \(characteristic.uuid.uuidString)")
            characteristics.append(characteristic)
        })
        
        discoveredServices[service]? = characteristics
        characteristicDiscoveryHandler?(service, characteristics, error)
    }
    
    func didUpdateValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateValueFor: \(characteristic.uuid.uuidString) with: \(String(describing: characteristic.value))")
        readHandler?(characteristic.value, error)
        readHandler = nil
        notificationHandler[characteristic]?(characteristic.value, error)
    }
    
    func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        print("didWriteValueFor: \(characteristic.uuid.uuidString)")
        writeHandler?(error)
        writeHandler = nil
    }
    
    // This is equivalent to a direct READ from the characteristic
    func didUpdateNotificationStateFor(characteristic: CBCharacteristic, error: Error?) {
        print("didUpdateNotificationStateFor: \(characteristic.uuid.uuidString)")
        notificationHandler[characteristic]?(characteristic.value, error)
    }
    
    func didDiscoverDescriptorsFor(characteristic: CBCharacteristic, error: Error?) { }
    
    func didUpdateValueFor(descriptor: CBDescriptor, error: Error?) { }
    
    func didWriteValueFor(descriptor: CBDescriptor, error: Error?) { }
    
    
    
    
    
    
    
    
    
    

    /** Read value of characteristic */
    func readData(for characteristic: CBCharacteristic) {
//        guard let peripheral = peripheral else { return }
        peripheral.readValue(for: characteristic)
    }
    
    /** Write value for characteristic */
    func writeData(data: Data, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType = .withResponse) {
//        guard let peripheral = peripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    /** Set notification */
    func setNotify(enable: Bool, forCharacteristic characteristic: CBCharacteristic){
//        guard let peripheral = peripheral else { return }
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
