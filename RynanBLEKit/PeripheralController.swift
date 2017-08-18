//
//  PeripheralController.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/14/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralController: UIViewController {

    @IBOutlet weak var lblService: UILabel!
    
    var lastAdvertisementData : Dictionary<String, AnyObject>?
    let centralManager = CentralManager.getInstance()
    
    var services : [CBService]?
    var characteristicsDic = [CBUUID : [CBCharacteristic]]()
    var advertisementDataKeys : [String]?
    
    @IBAction func btnDisCoverCharactic(_ sender: UIButton) {
        print("discoverCharacteristic")
        centralManager.discoverCharacteristics()
        
        let characteristics = services?[0].characteristics
        for characteristic in characteristics! {
            print(characteristic)
            if characteristic.uuid.uuidString == "2A99" {
                print("2A99")
            }
        }
    }
    
    @IBAction func btnWrite(_ sender: UIButton) {
        print("write value")
      _ = ActivityView.show()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let lastAdvertisementData = lastAdvertisementData {
            advertisementDataKeys = ([String](lastAdvertisementData.keys)).sorted()
        }
        services = centralManager.connectedPeripheral?.services
        lblService.text = String(describing: services)
        print("uuid: \(centralManager.connectedPeripheral?.identifier.uuidString)")
        print("Name: \(centralManager.connectedPeripheral?.name)")
    }
}
