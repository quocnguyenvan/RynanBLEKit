//
//  ServicesController.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/21/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit
import CoreBluetooth

class ServicesController: UIViewController, BluetoothDelegate {

    let centralManager = CentralManager.getInstance()
    var services : [CBService]?
    var characteristicsDic = [CBUUID : [CBCharacteristic]]()
    
    var advertisementData : Dictionary<String, AnyObject>?
    var advertisementDataKeys : [String]?
    
    @IBOutlet weak var tblService: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager.discoverCharacteristics()
        services = centralManager.connectedPeripheral?.services
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Services"
        centralManager.bluetoothDelegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
//        self.navigationItem.title = " "
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    func didDiscoverCharacteritics(_ service: CBService) {
        print("Service.characteristics:\(String(describing: service.characteristics))")
        characteristicsDic[service.uuid] = service.characteristics
    }
}

extension ServicesController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (services?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
//        cell.textLabel?.text = "abc"
        let service = services?[indexPath.row].uuid.uuidString
        cell.textLabel?.text = service
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        return cell
    }
}

extension ServicesController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = storyboard?.instantiateViewController(withIdentifier: "CharacteristicsController") as! CharacteristicsController
        vc.characteristics = characteristicsDic[(services?[indexPath.row].uuid)!]
        navigationController?.pushViewController(vc, animated: true)
    }
}
