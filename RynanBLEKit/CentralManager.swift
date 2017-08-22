//
//  CentralManager.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import CoreBluetooth

// MARK: - CentralManager -

public class CentralManager : NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    private(set) var centralManager: CBCentralManager?
    var bluetoothDelegate: BluetoothDelegate?
    
    public var discoveredPeripherals = [CBPeripheral]()
    public var peripheralsInfo: [UUID : Dictionary<String, AnyObject>] = [UUID : Dictionary<String, AnyObject>]()
    
    var state: CBManagerState? {
        guard let manager = centralManager else { return nil }
        return CBManagerState(rawValue: manager.state.rawValue)
    }
    
    private let notificationCenter = NotificationCenter.default
    
    private(set) open var isScanning = false
    private var isConnecting = false
    private(set) var connected = false
    private(set) var connectedPeripheral: CBPeripheral? // Peripheral
    private(set) var connectedServices: [CBService]?
    
    private static let sharedInstance = CentralManager()
    static private var instance: CentralManager {
        return sharedInstance
    }
    
    static func getInstance() -> CentralManager {
        return instance
    }
    
    public var poweredOn: Bool {
        return centralManager?.state == .poweredOn
    }
    
    public var poweredOff: Bool {
        return centralManager?.state == .poweredOff
    }
    
    private override init() {
        super.init()
        var showPowerAlertKey : [String : Any] = Dictionary()
        showPowerAlertKey[CBCentralManagerOptionShowPowerAlertKey] = false
        centralManager = CBCentralManager(delegate: self, queue: nil, options: showPowerAlertKey)
    }
    
    convenience init(centralManager: CBCentralManager) {
        self.init()
        centralManager.delegate = self
        self.centralManager = centralManager
    }
    
    deinit {
        centralManager?.delegate = nil
    }
    
    /** Start scan peripheral */
    public func startScanPeripheral(withServices uuids: [CBUUID]? = nil, options: [String : Any]? = [CBCentralManagerScanOptionAllowDuplicatesKey: true]) {
        guard let manager = centralManager, !isScanning else { return }
        self.isScanning = true
        manager.scanForPeripherals(withServices: uuids, options: options)
        print("Start scanning....")
    }
    
    /** Stop scan peripheral */
    public func stopScanPeripheral() {
        guard let manager = centralManager, isScanning else { return }
        self.isScanning = false
        manager.stopScan()
        discoveredPeripherals.removeAll()
        peripheralsInfo.removeAll()
        print("Stop scan.!")
    }
    
    /** Connect to peripheral */
    func connectPeripheral(_ cbPeripheral: CBPeripheral) {
        guard let manager = centralManager, !isConnecting else { return }
        manager.cancelPeripheralConnection(cbPeripheral)
        self.isConnecting = true
        print("--->Connecting...: \(isConnecting)")
//        connectedPeripheral = Peripheral(peripheral: cbPeripheral)
        manager.connect(cbPeripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
    /** Disconnect peripheral */
    func disconnectPeripheral() {
        guard let manager = centralManager else { return }
        if connectedPeripheral != nil {
            manager.cancelPeripheralConnection(connectedPeripheral!)
//            startScanPeripheral()
            connectedPeripheral = nil
        }
    }

    func discoverCharacteristics() {
        if connectedPeripheral != nil {
            guard let services = connectedPeripheral?.services else { return }
            for service in services {
                connectedPeripheral?.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    /** Read value of characteristic */
    func readData(for characteristic: CBCharacteristic) {
        guard let peripheral = connectedPeripheral else { return }
        peripheral.readValue(for: characteristic)
    }
    
    /** Write value for characteristic */
    func writeData(data: Data, forCharacteristic characteristic: CBCharacteristic, type: CBCharacteristicWriteType = .withResponse) {
        guard let peripheral = connectedPeripheral else { return }
        peripheral.writeValue(data, for: characteristic, type: type)
    }
    
    /** Set notification */
    func setNotify(enable: Bool, forCharacteristic characteristic: CBCharacteristic){
        guard let peripheral = connectedPeripheral else { return }
        peripheral.setNotifyValue(enable, for: characteristic)
    }
    
    // MARK: CBCentralManagerDelegate
    
    /** Update state of central manager */
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOff:
            print("State: Powered Off")
        case .poweredOn:
            print("State: Powered On")
        case .resetting:
            print("State: Resetting")
        case .unauthorized:
            print("State: Unauthorized")
        case .unknown:
            print("State: Unknown")
        case .unsupported:
            print("State: Unsupported")
        }
        guard let delegate = bluetoothDelegate, let state = self.state else { return }
        delegate.didUpdateState?(state)
    }
    
    /** Discovery of peripheral by central */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        guard let delegate = bluetoothDelegate else { return }
//        print("Central Manager -> didDiscoverPeripheral, rssi:\(RSSI)")
        
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            
            peripheralsInfo[peripheral.identifier] = ["RSSI": RSSI, "advertisementData": advertisementData as AnyObject]
            print("advertisementData: \(advertisementData) rssi: \(RSSI)")
        } else {
            peripheralsInfo[peripheral.identifier]!["RSSI"] = RSSI
            peripheralsInfo[peripheral.identifier]!["advertisementData"] = advertisementData as AnyObject?
        }
        delegate.didDiscoverPeripheral?(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    /** Connection succeeded */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Central Manager -> didConnectPeripheral")
        guard let delegate = bluetoothDelegate else { return }
        isConnecting = false
        connected = true
        connectedPeripheral = peripheral
        delegate.didConnectedPeripheral?(peripheral)
//        self.stopScanPeripheral()
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    /** Connection failed */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didFailToConnectPeripheral")
        guard let delegate = bluetoothDelegate else { return }
        isConnecting = false
        connected = false
        delegate.failToConnectPeripheral?(peripheral, error: error!)
    }
    
    /** Peripheral has been disconnected */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didDisconnectPeripheral")
        guard let delegate = self.bluetoothDelegate else { return }
        connected = false
        delegate.didDisconnectPeripheral?(peripheral)
        notificationCenter.post(name: NSNotification.Name(rawValue: "DisconnectNotify"), object: self)
        discoveredPeripherals.removeAll()
    }
    
    /** Will restore state */
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        print("Central Manager -> willRestoreState")
    }
    
    // MARK: CBPeripheralDelegate
    
    /** Services were discoverd */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Central Manager -> didDiscoverServices")
        guard let delegate = self.bluetoothDelegate else { return }
        connectedPeripheral = peripheral
        if error != nil { return }
        
        delegate.didDiscoverServices?(peripheral)
    }
    
    /** Characteristics were discovered */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Central Manager -> didDiscoverCharacteristicsForService")
        guard let delegate = self.bluetoothDelegate else { return }
        guard error == nil else {
            delegate.didFailToDiscoverCharacteritics?(error!)
            return
        }
        delegate.didDiscoverCharacteritics?(service)
    }
    
    /** Discovery descriptor when the peripheral has found the descriptor for the characteristic */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("Central Manager -> didDiscoverDescriptorsForCharacteristic")
        guard let delegate = self.bluetoothDelegate else { return }
        guard error == nil else {
            delegate.didFailToDiscoverDescriptors?(error!)
            return
        }
        delegate.didDiscoverDescriptors?(characteristic)
    }
    
    /** Update value */
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Central Manager -> didUpdateValueForCharacteristic")
        guard let delegate = self.bluetoothDelegate else { return }
        guard error == nil else {
            delegate.didFailToReadValueForCharacteristic?(error!)
            return
        }
        delegate.didReadValueForCharacteristic?(characteristic)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Central Manager -> write successfully!")
    }
}
