//
//  CharacteristicsController.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/21/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit
import CoreBluetooth

class CharacteristicsController: UIViewController, BluetoothDelegate {

    let centralManager = CentralManager.getInstance()
    var characteristics: [CBCharacteristic]?
    
    @IBOutlet weak var tblCharacteristic: UITableView!
    @IBOutlet weak var lblValue: UILabel!
    @IBOutlet weak var lblData: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager.bluetoothDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "Characteristics"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        self.navigationItem.title = ""
    }
    
    func showAlertWriteData(_ characteristic: CBCharacteristic) {
        let alert = UIAlertController(title: "Write data", message: "",preferredStyle: .alert)
        let write_6411 = UIAlertAction(title: "Write command_6411", style: .default, handler: { (action) -> Void in
            let command_6411 = NSData(bytes: [0x64, 0x11] as [UInt8], length: 2)
            self.centralManager.writeData(data: command_6411 as Data, forCharacteristic: characteristic)
        })
        let write_6412 = UIAlertAction(title: "Write command_6412", style: .default, handler: { (action) -> Void in
            let command_6412 = NSData(bytes: [0x64, 0x12] as [UInt8], length: 2)
            self.centralManager.writeData(data: command_6412 as Data, forCharacteristic: characteristic)
        })
        let write_6413 = UIAlertAction(title: "Write command_6413", style: .default, handler: { (action) -> Void in
            let command_6413 = NSData(bytes: [0x64, 0x13] as [UInt8], length: 2)
            self.centralManager.writeData(data: command_6413 as Data, forCharacteristic: characteristic)
        })
        let write_6414 = UIAlertAction(title: "Write command_6414", style: .default, handler: { (action) -> Void in
            let command_6414 = NSData(bytes: [0x64, 0x14] as [UInt8], length: 2)
            self.centralManager.writeData(data: command_6414 as Data, forCharacteristic: characteristic)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in })
        alert.view.tintColor = UIColor.brown
        alert.view.backgroundColor = UIColor.cyan
        alert.view.layer.cornerRadius = 25
        alert.addAction(write_6411)
        alert.addAction(write_6412)
        alert.addAction(write_6413)
        alert.addAction(write_6414)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}

extension CharacteristicsController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return (characteristics?.count)!
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = characteristics?[indexPath.row].uuid.uuidString
        cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
        return cell
    }
}

extension CharacteristicsController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let characteristic = self.characteristics?[indexPath.row]
        let alertCharacteristic = UIAlertController(title: "What would you like to do?", message: nil, preferredStyle: .actionSheet)
        let read = UIAlertAction(title: "Read data", style: .default, handler: { (action) -> Void in
            self.centralManager.readData(for: characteristic!)
        })
        let write = UIAlertAction(title: "Write data", style: .default, handler: { (action) -> Void in
            
            self.centralManager.setNotify(enable: true, forCharacteristic: characteristic!)
            self.showAlertWriteData(characteristic!)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in })
        alertCharacteristic.addAction(read)
        alertCharacteristic.addAction(write)
        alertCharacteristic.addAction(cancel)
        self.present(alertCharacteristic, animated: true, completion: nil)
    }
    
    func didDisconnectPeripheral(_ peripheral: CBPeripheral) {
        print("CharacteristicsController -> didDisconnectPeripheral")
        let alertController = UIAlertController(title: "Alert", message: "Disconnected", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func didReadValueForCharacteristic(_ characteristic: CBCharacteristic) {
        print("CharacteristicsController -> didReadValueForCharacteristic")
        if let value = characteristic.value {
            print("value: \(value)")
            self.lblValue.text = "\(value)"
            var data = [UInt8](repeating: 0, count: value.count)
            value.copyBytes(to: &data, count: data.count)
            print("Data: \(data)")
            self.lblData.text = "\(data)"
        }
    }
}
