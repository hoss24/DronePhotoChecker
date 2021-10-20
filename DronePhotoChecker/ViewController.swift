//
//  ViewController.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/24/21.
//

import Foundation
import UIKit
import DJISDK

class ViewController: UIViewController, DJISDKManagerDelegate {
    
    fileprivate let connectViaBridge = false
    fileprivate let bridgeAppIP = ""
    
    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var modelNameLabel: UILabel!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    
    var product : DJIBaseProduct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        DJISDKManager.registerApp(with: self)
        if let product = self.product {
            self.updateStatusBasedOn(product:product);
        }
    }
    
    func initUI() {
        //Hide label, show indicator until connected
        modelNameLabel.isHidden = true
        loadingIndicator.isHidden = false
        //Disable the connect button by default
        connectButton.isHidden = true
        
        product = nil
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        if let product = product {
            self.product = product
        }
        
        updateStatusBasedOn(product: product)
    }
    
    func productDisconnected() {
        let message = "Connection lost. Return to Main Menu."
        let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)
        let backAction = UIAlertAction.init(title: "Return", style: UIAlertAction.Style.default) { (action: UIAlertAction) in
            self.navigationController?.popToRootViewController(animated: true)
        }
        let alertViewController = UIAlertController.init(title: nil, message: message, preferredStyle: UIAlertController.Style.alert)
        alertViewController.addAction(cancelAction)
        alertViewController.addAction(backAction)
        
        present(alertViewController, animated: true, completion: nil)
        
        initUI()
    }
    
    func updateStatusBasedOn(product:DJIBaseProduct?) {
        self.connectStatusLabel.text = NSLocalizedString("Product Connected", comment: "")
        if let model = product?.model  {
            if model == DJIAircraftModelNamePhantom4RTK || model == DJIAircraftModelNameMatrice300RTK {
                modelNameLabel.text = "\(model)"
                modelNameLabel.isHidden = false
                connectButton.isHidden = false
                loadingIndicator.isHidden = true
            } else {
                connectStatusLabel.text = "Product Not Connected"
                modelNameLabel.text = "Model Unknown"
            }
        }
    }
    
    func appRegisteredWithError(_ error: Error?) {
        if let error = error {
            showAlert(on: self, with: "Registration Error", message: error.localizedDescription)
        } else {
            showAlert(on: self, with: "Registration Success", message: "")
            if connectViaBridge {
                DJISDKManager.enableBridgeMode(withBridgeAppIP: bridgeAppIP)
            } else {
                DJISDKManager.startConnectionToProduct()
            }
        }
    }
    
    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {
        print("Don't Call")
    }
}

