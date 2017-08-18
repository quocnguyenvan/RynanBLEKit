//
//  ViewController.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralsController: UIViewController, BluetoothDelegate {

    var stopScanButton       : UIBarButtonItem?
    var startScanButton      : UIBarButtonItem?
    var refreshControl       : UIRefreshControl!
    var scanEnabled          : Bool = false
    var didReset             : Bool = false
    
    var activityView: ActivityView?
    let centralManager = CentralManager.getInstance()
    var peripheralsArray : [CBPeripheral] = []
    var peripheralsInfo : [CBPeripheral:Dictionary<String, AnyObject>] = [CBPeripheral:Dictionary<String, AnyObject>]()
    
    @IBOutlet weak var tblScanned: UITableView!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder:aDecoder)
        
        self.stopScanButton = UIBarButtonItem(barButtonSystemItem:.stop, target:self, action: #selector(PeripheralsController.toggleScan(_:)))
        self.startScanButton = UIBarButtonItem(title:"Scan", style: .plain, target:self, action:#selector(PeripheralsController.toggleScan(_:)))
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setScanButton()
        
        self.refreshControl = UIRefreshControl()
        self.refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        self.refreshControl.addTarget(self, action: #selector(PeripheralsController.refreshTable(_:)), for: .valueChanged)
        if #available(iOS 10.0, *) {
            self.tblScanned.refreshControl = refreshControl
        } else {
            self.tblScanned.addSubview(self.refreshControl)
        }
    }
    
    func refreshTable(_ sender: AnyObject) {
        self.startScan()
        self.refreshControl.endRefreshing()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if centralManager.connectedPeripheral != nil {
            centralManager.disconnectPeripheral()
        }
        centralManager.bluetoothDelegate = self
//        centralManager.peripheralsInfo.removeAll()
//        centralManager.discoveredPeripherals.removeAll()
    }
    
    func toggleScan(_ sender: AnyObject) {
        guard centralManager.poweredOn else {
            present(UIAlertController.alert(message: "Bluetooth is not enabled"), animated:true, completion:nil)
            return
        }
        if scanEnabled {
            print("Scan toggled off")
            scanEnabled = false
            stopScan()
//            self.tblScanned.reloadData()
        } else {
            print("Scan toggled on")
            scanEnabled = true
            startScan()
        }
        setScanButton()
    }
    
    func setScanButton() {
        if scanEnabled {
            self.navigationItem.setRightBarButton(self.stopScanButton, animated:false)
        } else {
            self.navigationItem.setRightBarButton(self.startScanButton, animated:false)
        }
    }
    
    func startScan() {
        print("isScanning: \(centralManager.isScanning)")
        guard scanEnabled else { return }
        guard !centralManager.isScanning else { return }
        centralManager.startScanPeripheral()
    }
    
    func stopScan() {
        scanEnabled = false
        centralManager.stopScanPeripheral()
        centralManager.disconnectPeripheral()
        self.tblScanned.reloadData()
    }
    
    func didUpdateState(_ state: CBManagerState) {
        switch state {
        case .resetting:
            print("MainController -> State : Resetting")
        case .poweredOn:
            print("MainController -> State : Powered On")
            BluetoothRequireView.hide()
//            centralManager.startScanPeripheral()
        case .poweredOff:
            print("MainController -> State : Powered Off")
            BluetoothRequireView.show()
            self.scanEnabled = false
            self.setScanButton()
            centralManager.discoveredPeripherals.removeAll()
            centralManager.peripheralsInfo.removeAll()
            tblScanned.reloadData()
        case .unauthorized:
            print("MainController -> State : Unauthorized")
        case .unknown:
            print("MainController -> State : Unknown")
        case .unsupported:
            print("MainController -> State : Unsupported")
            BluetoothRequireView.show()
        }
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        tblScanned.reloadData()
    }
    
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("MainController -> didConnectedPeripheral")
        print("--->Connected..!")
        activityView?.messageLabel.text = "Connected!"
    }

    func didDiscoverServices(_ peripheral: CBPeripheral) {
        if let services = peripheral.services {
            print("MainController -> didDiscoverService:\(services)")
            ActivityView.hide()
            let peripheralController = storyboard?.instantiateViewController(withIdentifier: "PeripheralController") as! PeripheralController
            let peripheralInfo = centralManager.peripheralsInfo[peripheral]
            peripheralController.lastAdvertisementData = peripheralInfo!["advertisementData"] as? Dictionary<String, AnyObject>
            self.navigationController?.pushViewController(peripheralController, animated: true)
            
//            for service in services {
//                let thisService = service as CBService
//                if thisService.uuid.uuidString == "181C" {
//                    centralManager.discoverCharacteristics()
//                    peripheral.discoverCharacteristics(nil, for: thisService)
//                    print("thisService: \(thisService)")
//                }
//            }
        }
    }
}

extension PeripheralsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return centralManager.discoveredPeripherals.count// peripheralsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath) as! PeripheralCell
        
        let peripheral = centralManager.discoveredPeripherals[indexPath.row]
        let peripheralInfo = centralManager.peripheralsInfo[peripheral]
        //        if let peripheralCell = cell as? ScannedPeripheralCell {
        //            peripheralCell.configure(with: peripheral)
        //        }
        cell.nameLabel.text = peripheral.peripheralName
        
        if let serviceUUIDs = peripheralInfo!["advertisementData"]!["kCBAdvDataServiceUUIDs"] as? NSArray {
            let count = serviceUUIDs.count
            cell.servicesLabel.text = "\(count) service" + (count > 1 ? "s" : "")
        } else {
            cell.servicesLabel.text = "No service"
        }
        
        let RSSI = peripheralInfo!["RSSI"]! as! NSNumber
        updateRSSI(RSSI, forCell: cell)
        return cell
    }
}

extension PeripheralsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let peripheral = centralManager.discoveredPeripherals[indexPath.row]
        activityView = ActivityView.show()
        print("Connecting to: \(String(describing: peripheral.name))")
        centralManager.connectPeripheral(peripheral)
//        centralManager.stopScanPeripheral()
    }
}

func updateRSSI(_ RSSI: NSNumber, forCell cell: PeripheralCell) {
    let rssiImage: UIImage
    switch labs(RSSI.intValue) {
    case 0...40:
        rssiImage = #imageLiteral(resourceName: "blue_full")
    case 41...53:
        rssiImage = #imageLiteral(resourceName: "blue_04")
    case 54...65:
        rssiImage = #imageLiteral(resourceName: "blue_03")
    case 66...77:
        rssiImage = #imageLiteral(resourceName: "blue_02")
    case 77...89:
        rssiImage = #imageLiteral(resourceName: "blue_01")
    default:
        rssiImage = #imageLiteral(resourceName: "blue_00")
    }
    cell.rssiImage.image = rssiImage
    cell.rssiLabel.text = "\(RSSI) dBm"
}
