//
//  Extensions.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/16/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth

extension CBPeripheral {
    
    class func deviceServiceUUID() -> CBUUID {
        return CBUUID(string:"181C")
    }
    
    class func deviceCharacteristicUUID() -> CBUUID {
        return CBUUID(string:"2A99")
    }
    
    public var isConnected: Bool {
        return state == .connected
    }
    
    public var peripheralName: String? {
        return name ?? "Unknown"
    }
}

extension UIAlertController {
    
    class func alert(title: String? = nil, error: Swift.Error, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: title ?? "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: handler))
        return alert
    }
    
    class func alertOnErrorWithMessage(_ message: String, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Error", message:message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler))
        return alert
    }
    
    class func alert(message: String, handler: ((UIAlertAction?) -> Void)? = nil) -> UIAlertController {
        let alert = UIAlertController(title: "Alert", message:message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler:handler))
        return alert
    }
}
