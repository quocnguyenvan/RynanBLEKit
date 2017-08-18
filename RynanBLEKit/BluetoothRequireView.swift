
import UIKit

class BluetoothRequireView : UIView {
    
    struct Static {
        static var requireView = BluetoothRequireView()
    }
    
    init() {
        super.init(frame:UIScreen.main.bounds)
        self.backgroundColor = UIColor(white: 0.0, alpha: 0.5)
        // Create the top ImageView
        let imgView = UIImageView(image: UIImage(named: "bluetooth_icon"))
        imgView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(imgView)
        
        // Create and add the constraints for the ImageView
        let imgCenterX = imgView.centerXAnchor.constraint(equalTo: self.centerXAnchor)
        let imgCenterY = imgView.centerYAnchor.constraint(equalTo: self.centerYAnchor, constant: -60)
        let imgWidth = imgView.widthAnchor.constraint(equalToConstant: 120)
        let imgHeight = imgView.heightAnchor.constraint(equalTo: imgView.widthAnchor, multiplier: 1.0)
        NSLayoutConstraint.activate([imgCenterX, imgCenterY, imgWidth, imgHeight])
        
        // Create the title label
        let lblTitle = UILabel()
        lblTitle.translatesAutoresizingMaskIntoConstraints = false
        lblTitle.text = "This app requires Bluetooth"
        lblTitle.font = UIFont.systemFont(ofSize: 17, weight: UIFontWeightThin)
        lblTitle.textColor = UIColor.white
        self.addSubview(lblTitle)
        
        // Create and add the constraints for the title label
        let lblTop = lblTitle.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 10)
        let lblCenterX = lblTitle.centerXAnchor.constraint(equalTo: imgView.centerXAnchor)
        let lblWidth = lblTitle.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        NSLayoutConstraint.activate([lblTop, lblCenterX, lblWidth])
        
        // Create the detail label
        let lblDetail = UILabel()
        lblDetail.translatesAutoresizingMaskIntoConstraints = false
        lblDetail.text = "Please enable Bluetooth to continue!"
        lblDetail.font = UIFont.systemFont(ofSize: 12, weight: UIFontWeightLight)
        lblDetail.textColor = UIColor.white
        self.addSubview(lblDetail)
        
        // Create and add constraints for the detail label
        let lbl2Top = lblDetail.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 8)
        let lbl2CenterX = lblDetail.centerXAnchor.constraint(equalTo: lblTitle.centerXAnchor)
        let lbl2Width = lblDetail.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        NSLayoutConstraint.activate([lbl2Top, lbl2CenterX, lbl2Width])
        
        // Add a white line
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        line.backgroundColor = UIColor.white
        self.addSubview(line)
        
        // Create and add constraints for it
        let lineTop = line.topAnchor.constraint(equalTo: lblDetail.bottomAnchor, constant: 8)
        let lineCenterX = line.centerXAnchor.constraint(equalTo: lblDetail.centerXAnchor)
        let lineWidth = line.widthAnchor.constraint(equalToConstant: UIScreen.main.bounds.width * (4/5))
        let lineHeight = line.heightAnchor.constraint(equalTo: lblDetail.heightAnchor, multiplier: 0.05)
        NSLayoutConstraint.activate([lineTop, lineCenterX, lineWidth, lineHeight])
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Show bluetooth require view
    static func show() {
        if let window = UIApplication.shared.keyWindow {
            window.addSubview(Static.requireView)
        }
    }
    // Hide it
    static func hide() {
        Static.requireView.removeFromSuperview()
    }
}
