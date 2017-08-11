//
//  ViewController.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/11/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, BluetoothDelegate {

    let centralManager = CentralManager.getInstance()
    var peripheralsArray : [CBPeripheral] = []
    var peripheralsInfo : [CBPeripheral:Dictionary<String, AnyObject>] = [CBPeripheral:Dictionary<String, AnyObject>]()
    
    @IBOutlet weak var tblScanned: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblScanned.delegate = self
        tblScanned.dataSource = self
    }
    
    @IBAction func btnScan(_ sender: Any) {
        centralManager.startScanPeripheral()
    }
    
    @IBAction func btnStop(_ sender: Any) {
        centralManager.stopScanPeripheral()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if centralManager.connectedPeripheral != nil {
            centralManager.disconnectPeripheral()
        }
        centralManager.delegate = self
    }
    
    func didUpdateState(_ state: CBManagerState) {
        switch state {
        case .resetting:
            print("MainController -> State : Resetting")
        case .poweredOn:
            centralManager.startScanPeripheral()
            // UnavailableView.hideUnavailableView()
            
        case .poweredOff:
            print("MainController ->State : Powered Off")
            fallthrough
        case .unauthorized:
            print("MainController -> State : Unauthorized")
            fallthrough
        case .unknown:
            print("MainController -> State : Unknown")
            fallthrough
        case .unsupported:
            print("MainController -> State : Unsupported")
            centralManager.stopScanPeripheral()
            centralManager.disconnectPeripheral()
        }
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        if !peripheralsArray.contains(peripheral) {
            peripheralsArray.append(peripheral)
            
            peripheralsInfo[peripheral] = ["RSSI": RSSI, "advertisementData": advertisementData as AnyObject]
            print("advertisementData: \(advertisementData) rssi: \(RSSI)")
            
        } else {
            peripheralsInfo[peripheral]!["RSSI"] = RSSI
            peripheralsInfo[peripheral]!["advertisementData"] = advertisementData as AnyObject?
        }
        tblScanned.reloadData()
    }
    
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("MainController -> didConnectedPeripheral")
    }

    func didDiscoverServices(_ peripheral: CBPeripheral) {
        if let services = peripheral.services {
            print("MainController -> didDiscoverService:\(services)")
            for service in services {
                let thisService = service as CBService
                
                if service.uuid.uuidString == "181C" {
                    peripheral.discoverCharacteristics(nil, for: thisService)
                    print("thisService: \(thisService)")
                }
            }
        }
    }
}

extension ViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripheralsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PeripheralCell", for: indexPath) as! PeripheralCell
        
        let peripheral = peripheralsArray[indexPath.row]
        let peripheralInfo = peripheralsInfo[peripheral]
        //        if let peripheralCell = cell as? ScannedPeripheralCell {
        //            peripheralCell.configure(with: peripheral)
        //        }
        cell.nameLabel.text = peripheral.name == nil || peripheral.name == ""  ? "Unnamed" : peripheral.name
        
        let serviceUUIDs = peripheralInfo!["advertisementData"]!["kCBAdvDataServiceUUIDs"] as? NSArray
        if serviceUUIDs != nil && serviceUUIDs?.count != 0 {
            cell.servicesLabel.text = "\((serviceUUIDs?.count)!) service" + ((serviceUUIDs?.count)! > 1 ? "s" : "")
        } else {
            cell.servicesLabel.text = "No service"
        }
        
        let RSSI = peripheralInfo!["RSSI"]! as! NSNumber
        updateRSSI(RSSI, forCell: cell)
        return cell
    }
}

extension ViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //        let peripheralDetail = storyboard?.instantiateViewController(withIdentifier: "PeripheralDetail") as! ServicesController
        
        //        peripheralDetail.scannedPeripheral = peripheralsArray[indexPath.row]
        //        peripheralDetail.manager = manager
        //        navigationController?.pushViewController(peripheralDetail, animated: true)
        let peripheral = peripheralsArray[indexPath.row]
//        connectingView = ConnectingView.showConnectingView()
//        connectingView?.tipNameLbl.text = peripheral.name
        centralManager.connectPeripheral(peripheral)
        centralManager.stopScanPeripheral()
    }
}

func updateRSSI(_ RSSI: NSNumber, forCell cell: PeripheralCell) {
    let rssiImage: UIImage
    switch labs(RSSI.intValue) {
    case 0...40:
        rssiImage = #imageLiteral(resourceName: "RSSI-5")
    case 41...53:
        rssiImage = #imageLiteral(resourceName: "RSSI-4")
    case 54...65:
        rssiImage = #imageLiteral(resourceName: "RSSI-3")
    case 66...77:
        rssiImage = #imageLiteral(resourceName: "RSSI-2")
    case 77...89:
        rssiImage = #imageLiteral(resourceName: "RSSI-1")
    default:
        rssiImage = #imageLiteral(resourceName: "RSSI-0")
    }
    cell.rssiImage.image = rssiImage
    cell.rssiLabel.text = "\(RSSI)"
}
