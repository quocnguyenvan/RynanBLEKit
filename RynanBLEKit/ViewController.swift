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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func btnScan(_ sender: Any) {
        centralManager.startScanPeripheral()
    }
    
    @IBAction func btnStop(_ sender: Any) {
        centralManager.stopScanPeripheral()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        centralManager.delegate = self
    }
    
    func didUpdateState(_ state: CBManagerState) {
        switch state {
        case .resetting:
            print("MainController -> State : Resetting")
        case .poweredOn:
            centralManager.startScanPeripheral()
            //            UnavailableView.hideUnavailableView()
            
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
            //            UnavailableView.showUnavailableView()
        }
    }
    
    func didDiscoverPeripheral(_ peripheral: CBPeripheral, advertisementData: [String : Any], RSSI: NSNumber) {
        if !peripheralsArray.contains(peripheral) {
            peripheralsArray.append(peripheral)
            
            peripheralsInfo[peripheral] = ["RSSI": RSSI, "advertisementData": advertisementData as AnyObject]
            
            print("advertisementData: \(advertisementData)")
        } else {
            peripheralsInfo[peripheral]!["RSSI"] = RSSI
            peripheralsInfo[peripheral]!["advertisementData"] = advertisementData as AnyObject?
        }
    }
    
    func didConnectedPeripheral(_ connectedPeripheral: CBPeripheral) {
        print("MainController -> didConnectedPeripheral")
    }

    func didDiscoverServices(_ peripheral: CBPeripheral) {
        if let services = peripheral.services {
            print("MainController -> didDiscoverService:\(services)")
        }
    }
}

