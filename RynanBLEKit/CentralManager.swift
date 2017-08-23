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
    
    public var discoveredPeripherals = [Peripheral]()
    public var peripheralsInfo: [UUID : Dictionary<String, AnyObject>] = [UUID : Dictionary<String, AnyObject>]()
    
    fileprivate var scanChangesHandler: ((Peripheral) -> Void)?
    fileprivate var scanCompleteHandler: (([Peripheral]) -> Void)?
    
    open var scannedDevices = Set<Peripheral>()
    fileprivate var connectedDevices = [String:Peripheral]()
    
    private let DEVICE_SERVICE_UUID = "181C"
    private let DEVICE_CHARACTERISTIC_UUID = "2A99"
    
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
    
//    public var isScanning: Bool {
//        return centralManager!.isScanning
//    }
    
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
    public func startScanPeripheral(withServices uuids: [CBUUID]? = nil, timeout: TimeInterval = .infinity, options: [String : Any]? = [CBCentralManagerScanOptionAllowDuplicatesKey: true]) {
        guard let manager = centralManager, !isScanning else { return }
        self.isScanning = true
        manager.scanForPeripherals(withServices: uuids, options: options)
        print("Start scanning....")
//        Timer.scheduledTimer(timeInterval: timeout!, target: self, selector: #selector(self.stopScanPeripheral), userInfo: nil, repeats: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            self.stopScanPeripheral()
        }
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
    func connectPeripheral(_ cbPeripheral: Peripheral) {
        guard let manager = centralManager, !isConnecting else { return }
        manager.cancelPeripheralConnection(cbPeripheral.peripheral)
        self.isConnecting = true
        print("--->Connecting...: \(isConnecting)")
//        connectedPeripheral = Peripheral(peripheral: cbPeripheral)
        connectedDevices[cbPeripheral.id] = cbPeripheral
        
        manager.connect(cbPeripheral.peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
    }
    
    /** Disconnect peripheral */
    func disconnectPeripheral(_ peripheral: Peripheral) {
        guard let manager = centralManager else { return }
//        if connectedPeripheral != nil {
//            manager.cancelPeripheralConnection(connectedPeripheral!)
////            startScanPeripheral()
//            connectedPeripheral = nil
//        }
        print("Disconnecting from device - \(peripheral.id)")
        connectedDevices[peripheral.id] = peripheral
        manager.cancelPeripheralConnection(peripheral.peripheral)
    }
    
    //    func connect(to device: Peripheral) {
    //        connectedDevices[device.id] = device
    //        centralManager?.connect(device.peripheral, options: nil)
    //    }
    //
    //    func disconnect(from device: Peripheral) {
    //        connectedDevices[device.id] = device
    //        print("Disconnecting from device - \(device.id)")
    //        centralManager?.cancelPeripheralConnection(device.peripheral)
    //    }

    func discoverCharacteristics() {
        if connectedPeripheral != nil {
            guard let services = connectedPeripheral?.services else { return }
            for service in services {
                let thisCharacteristic = [CBUUID(string: DEVICE_CHARACTERISTIC_UUID)]
                connectedPeripheral?.discoverCharacteristics(thisCharacteristic, for: service)
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
        
        let discoveredPeripheral = Peripheral(centralManager: self, peripheral: peripheral)
        let index = discoveredPeripherals.index { $0.identifier.uuidString == discoveredPeripheral.identifier.uuidString }
        if let index = index {
            discoveredPeripherals[index] = discoveredPeripheral
            peripheralsInfo[discoveredPeripheral.identifier]!["RSSI"] = RSSI
            peripheralsInfo[discoveredPeripheral.identifier]!["advertisementData"] = advertisementData as AnyObject?
        } else {
            discoveredPeripherals.append(discoveredPeripheral)
            peripheralsInfo[discoveredPeripheral.identifier] = ["RSSI": RSSI, "advertisementData": advertisementData as AnyObject]
            print("advertisementData: \(advertisementData) rssi: \(RSSI)")
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
//        peripheral.delegate = self
//        peripheral.discoverServices([CBUUID(string: DEVICE_SERVICE_UUID)]) // nil
        
        connectedDevices[peripheral.identifier.uuidString]?.didConnect()
    }
    
    /** Connection failed */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didFailToConnectPeripheral")
        guard let delegate = bluetoothDelegate else { return }
        isConnecting = false
        connected = false
        delegate.failToConnectPeripheral?(peripheral, error: error!)
        
        connectedDevices[peripheral.identifier.uuidString]?.didDisconnect()
    }
    
    /** Peripheral has been disconnected */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didDisconnectPeripheral")
        guard let delegate = self.bluetoothDelegate else { return }
        connected = false
        delegate.didDisconnectPeripheral?(peripheral)
//        notificationCenter.post(name: NSNotification.Name(rawValue: "DisconnectNotify"), object: self)
        connectedPeripheral?.delegate = nil
        discoveredPeripherals.removeAll()
        
        connectedDevices[peripheral.identifier.uuidString]?.didDisconnect()
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
//        connectedPeripheral = peripheral
//        if error != nil { return }
        
        delegate.didDiscoverServices?(peripheral)
        
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverServices(error: error)
    }
    
    /** Characteristics were discovered */
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        print("Central Manager -> didDiscoverCharacteristicsForService")
        guard let delegate = self.bluetoothDelegate else { return }
//        guard error == nil else {
//            delegate.didFailToDiscoverCharacteritics?(error!)
//            return
//        }
        delegate.didDiscoverCharacteritics?(service)
        connectedDevices[peripheral.identifier.uuidString]?.didDiscoverCharacteristicsFor(service: service, error: error)
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
//        guard let delegate = self.bluetoothDelegate else { return }
//        guard error == nil else {
//            delegate.didFailToReadValueForCharacteristic?(error!)
//            return
//        }
//        if characteristic.uuid.uuidString == DEVICE_CHARACTERISTIC_UUID {
//            delegate.didReadValueForCharacteristic?(characteristic)
//        }
        
        connectedDevices[peripheral.identifier.uuidString]?.didUpdateValueFor(characteristic: characteristic, error: error)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Central Manager -> write successfully!")
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) { }
}
