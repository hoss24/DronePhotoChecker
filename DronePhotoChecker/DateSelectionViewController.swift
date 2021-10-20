//
//  DateSelectionViewController.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/25/21.
//

import UIKit

class DateSelectionViewController: UIViewController, UITextFieldDelegate {
    
    //User Selections
    var startDate = Date()
    var endDate = Date()
    var altitudePreference = Double()
    var rtkPreference = true
    var gimbalPitchPreference = true
    
    @IBOutlet var altitudeTextField: UITextField!
    @IBOutlet var proceedButton: UIBarButtonItem!
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.altitudeTextField.delegate = self
        
        //add button to number keyboard
        altitudeTextField.addDoneButtonToKeyboard(myAction:  #selector(self.altitudeTextField.resignFirstResponder))
        
        defaults.set(rtkPreference, forKey: "rtkPreference")
        defaults.set(gimbalPitchPreference, forKey: "gimbalPitchPreference")
        // Do any additional setup after loading the view.
    }
    
    @IBAction func startDateChanged(_ sender: UIDatePicker) {
        startDate = sender.date
        dateCheck()
    }
    
    @IBAction func endDateChanged(_ sender: UIDatePicker) {
        endDate = sender.date
        dateCheck()
    }
    
    func dateCheck(){
        if startDate > endDate {
            proceedButton.isEnabled = false
            self.title = "Start Date must be earlier then End Date"
        } else {
            proceedButton.isEnabled = true
            self.title = "Settings"
        }
    }
    
    @IBAction func rtkPreferenceChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            rtkPreference = true
        } else {
            rtkPreference = false
        }
        defaults.set(rtkPreference, forKey: "rtkPreference")
    }
    
    @IBAction func gimbalPitchPreferenceChanged(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            gimbalPitchPreference = true
        } else {
            gimbalPitchPreference = false
        }
        defaults.set(gimbalPitchPreference, forKey: "gimbalPitchPreference")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            self.view.endEditing(true)
            return false
    }
    
    @IBAction func altitudeChanged(_ sender: UITextField) {
        guard let textString = sender.text else { return }
        altitudePreference = Double(textString) ?? 0.0
        defaults.set(altitudePreference, forKey: "altitudePreference")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "dateToPhoto") {
            let destinationVC = segue.destination as! MediaListViewController
            destinationVC.startDate = startDate
            destinationVC.endDate = endDate
        }
    }
    
}

extension UITextField{
////add button to number keyboard
 func addDoneButtonToKeyboard(myAction:Selector?){
    let doneToolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
    doneToolbar.barStyle = UIBarStyle.default

    let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
    let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: myAction)

    var items = [UIBarButtonItem]()
    items.append(flexSpace)
    items.append(done)

    doneToolbar.items = items
    doneToolbar.sizeToFit()
    self.inputAccessoryView = doneToolbar
 }
}
