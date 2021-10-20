//
//  Utility.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/24/21.
//

import UIKit
import DJISDK

func showAlert(on vc:UIViewController,with title:String, message:String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
    DispatchQueue.main.async {
        vc.present(alert, animated: true, completion: nil)
    }
}

func fetchCamera () -> DJICamera? {
    let aircraft = DJISDKManager.product() as? DJIAircraft
    return aircraft?.camera
}

extension String {
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}

/*
//Show Common Alert like internet failure
func showInternetFailureAlert(on vc:UIViewController){
    showAlert(on: vc, with: internetAlertTitle, message: internetAlertMessage)
}
}
//Show Specific Alerts like Valid or Invalid
func showInternetFailureAlert(on vc:UIViewController){
    showAlert(on: vc, with: “Alert”, message: “Invalid”)
}
*/
