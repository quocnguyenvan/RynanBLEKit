//
//  CentralManager.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import CoreBluetooth

// MARK: - CentralManager -

public class CentralManager : NSObject, CBCentralManagerDelegate {
    
    private(set) var centralManager : CBCentralManager?
    var delegate : BluetoothDelegate?
    
    var state: CBManagerState? {
        guard let manager = centralManager else { return nil }
        return CBManagerState(rawValue: manager.state.rawValue)
    }
    
    private var timeoutMonitor : Timer? /// Timeout monitor of connect to peripheral
    private var interrogateMonitor : Timer? /// Timeout monitor of interrogate the peripheral
    
    private let notificationCenter = NotificationCenter.default
    
    private(set) open var isScanning = false
    private var isConnecting = false
    private(set) var connected = false
    private(set) var connectedPeripheral : CBPeripheral? // Peripheral
    private(set) var connectedServices : [CBService]?
    
    private static let sharedInstance = CentralManager()
    // Save the single instance
    static private var instance : CentralManager {
        return sharedInstance
    }
    
    public var poweredOn: Bool {
        return centralManager?.state == .poweredOn
    }
    
    public var poweredOff: Bool {
        return centralManager?.state == .poweredOff
    }
    
    public var unSupported: Bool {
        return centralManager?.state == .unsupported
    }
    
    static func getInstance() -> CentralManager {
        return instance
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
    
    /** when interrogate peripheral is timeout */
    
//    @objc func integrrogateTimeout(_ timer: Timer) {
//        guard let delegate = delegate else { return }
//        disconnectPeripheral()
//        delegate.didFailedToInterrogate?((timer.userInfo as! CBPeripheral))
//    }
    
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
        print("Stop scanning....")
    }
    
    /** Connect to peripheral */
    func connectPeripheral(_ peripheral: CBPeripheral) {
        guard let manager = centralManager, !isConnecting else { return }
        self.isConnecting = true
        manager.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
//            timeoutMonitor = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.connectTimeout(_:)), userInfo: peripheral, repeats: false)
    }
    
    /** Disconnect peripheral */
    func disconnectPeripheral() {
        guard let manager = centralManager, connectedPeripheral != nil else { return }
        manager.cancelPeripheralConnection(connectedPeripheral!)
        startScanPeripheral()
        connectedPeripheral = nil
    }
    
    /** Discover descriptors */
    func discoverDescriptor(_ characteristic: CBCharacteristic) {
        guard let connectedPeripheral = connectedPeripheral else { return }
        connectedPeripheral.discoverDescriptors(for: characteristic)
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
        guard let delegate = delegate, let state = self.state else { return }
        delegate.didUpdateState?(state)
    }
    
    /** Discovery of peripheral by central */
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
//        print("Central Manager -> didDiscoverPeripheral, RSSI:\(RSSI)")
        guard let delegate = delegate else { return }
        delegate.didDiscoverPeripheral?(peripheral, advertisementData: advertisementData, RSSI: RSSI)
    }
    
    /** Connection succeeded */
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Central Manager -> didConnectPeripheral")
        guard let delegate = delegate else { return }
        isConnecting = false
        if timeoutMonitor != nil {
            timeoutMonitor!.invalidate()
            timeoutMonitor = nil
        }
        connected = true
        connectedPeripheral = peripheral
        delegate.didConnectedPeripheral?(peripheral)
        stopScanPeripheral()
//        peripheral.delegate = self
        peripheral.discoverServices(nil)
//        interrogateMonitor = Timer.scheduledTimer(timeInterval: 5.0, target: self, selector: #selector(self.integrrogateTimeout(_:)), userInfo: peripheral, repeats: false)
    }
    
    /** Connection failed */
    public func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didFailToConnectPeripheral")
        guard let delegate = delegate else { return }
        isConnecting = false
        if timeoutMonitor != nil {
            timeoutMonitor!.invalidate()
            timeoutMonitor = nil
        }
        connected = false
        delegate.failToConnectPeripheral?(peripheral, error: error!)
    }
    
    /** Peripheral has been disconnected */
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Central Manager -> didDisconnectPeripheral")
        guard let delegate = self.delegate else { return }
        connected = false
        delegate.didDisconnectPeripheral?(peripheral)
        notificationCenter.post(name: NSNotification.Name(rawValue: "DisconnectNotify"), object: self)
    }
    
    /** Will restore state */
    public func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
    }
}

