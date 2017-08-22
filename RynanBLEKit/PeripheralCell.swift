//
//  PeripheralCell.swift
//  RynanBLEKit
//
//  Created by Quoc Nguyen on 8/16/17.
//  Copyright © 2017 RynanTeam. All rights reserved.
//

import UIKit

class PeripheralCell : UITableViewCell {

    @IBOutlet var rssiImage: UIImageView!
    @IBOutlet var rssiLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var connectLabel: UILabel!
    @IBOutlet var addressLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.connectLabel.layer.masksToBounds = true
        self.connectLabel.layer.cornerRadius = 15
        
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 0/255, green: 111/255, blue: 255/255, alpha: 0.35)
        self.selectedBackgroundView = selectedView
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
}
