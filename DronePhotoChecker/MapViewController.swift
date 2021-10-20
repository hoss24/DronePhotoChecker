//
//  MapViewController.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/30/21.
//

import UIKit
import MapKit
import DJISDK

class MapViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet var mapView: MKMapView!
    var mediaList = [MediaInfo]()
    var annotations = [MKAnnotation]()
    var rtkStatus = String()
    var rtkPinColor = UIColor()
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Map Type", style: .plain, target: self, action: #selector(determineMapType))
        fillMediaList()
    }
    
    func fillMediaList() {
        let rtkPreference = defaults.object(forKey: "rtkPreference") as? Bool ?? true
        let gimbalPitchPreference = defaults.object(forKey: "gimbalPitchPreference") as? Bool ?? true
        let altitudePreference = defaults.object(forKey: "altitudePreference") as? Double ?? nil
        
        for media in mediaList{
            if media.checked {
                //get information from xmp information
                let lat = Double(media.mediaFile?.xmpInformation?.slice(from: "dji:GpsLatitude=\"", to: "\"\n   drone-dji:GpsLongtitude=\"") ?? "0") ?? 0.0
                let lon = Double(media.mediaFile?.xmpInformation?.slice(from: "dji:GpsLongtitude=\"", to: "\"\n   drone-dji:GimbalRollDegree=\"") ?? "0") ?? 0.0
                let rtkStatusNumber = Int(media.mediaFile?.xmpInformation?.slice(from: "dji:RtkFlag=\"", to: "\"\n   drone-dji:RtkStdLon=\"") ?? "-1") ?? -1
                var gimbalPitchDegree = String(media.mediaFile?.xmpInformation?.slice(from: "dji:GimbalPitchDegree=\"", to: "\"\n   drone-dji:FlightRollDegree") ?? "")
                let relativeAltitudeMeters = Double(media.mediaFile?.xmpInformation?.slice(from: "dji:RelativeAltitude=\"", to: "\"\n   drone-dji:GpsLatitude") ?? "0") ?? 0.0
                let relativeAltitudeFeet =  relativeAltitudeMeters * 3.281
                let thumbnail = media.mediaFile?.thumbnail ?? UIImage(named: "default")!
                
                rtkPinColor = .green
                
                if rtkStatusNumber == 0 {
                    rtkStatus = "RtkFlag = 0 (No RTK Positioning)"
                    if rtkPreference{
                        rtkPinColor = .red
                    }
                } else if rtkStatusNumber == 16 {
                    rtkStatus = "RtkFlag = 16 (Single)"
                    if rtkPreference{
                        rtkPinColor = .red
                    }
                } else if rtkStatusNumber == 34 {
                    rtkStatus = "RtkFlag = 34 (Float)"
                    if rtkPreference{
                        rtkPinColor = .red
                    }
                } else if rtkStatusNumber == 50 {
                    rtkStatus = "RtkFlag = 50 (Fix)"
                    print("5000 \(rtkStatus)")
                } else {
                    rtkStatus = "Error finding RtkFlag"
                    rtkPinColor = .red
                }
                
                if gimbalPitchDegree.count > 0 {
                    if let decGimbalPitchDegree = Double(gimbalPitchDegree.dropFirst()) {
                        if decGimbalPitchDegree < 88.0{
                            if gimbalPitchPreference {
                                rtkPinColor = .red
                            }
                        }
                    }
                } else{
                    gimbalPitchDegree = "Error finding Gimbal Pitch"
                    rtkPinColor = .red
                }
                
                if lat == 0 || lon == 0 {
                    rtkPinColor = .red
                }
                
                if let safeAltitudePreference = altitudePreference {
                    if relativeAltitudeFeet != 0 {
                        let minAltitudePreference = safeAltitudePreference - 5
                        let maxAltitudePreference = safeAltitudePreference + 5
                        if relativeAltitudeFeet < minAltitudePreference || relativeAltitudeFeet > maxAltitudePreference {
                            rtkPinColor = .purple
                        }
                    } else {
                        rtkPinColor = .yellow
                    }
                }
                
                
                
                //create annotation
                let title = "\(media.mediaFile?.fileName ?? "File Name Not Found")"
                let annotation = Photo(title: title, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon), rtkStatus: rtkStatus, rtkPinColor: rtkPinColor, gimbalPitchDegree: gimbalPitchDegree, relativeAltitudeFeet: relativeAltitudeFeet, thumbnail: thumbnail)
                
                print(annotation.coordinate)
                print(annotation.rtkStatus)
                
                annotations.append(annotation)
            }
        }
        for annotation in annotations{
            mapView.addAnnotation(annotation)
        }
        mapView.showAnnotations(mapView.annotations, animated: true)
        

    }
    

func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    //1 is annotation from Photo? if not return nil so iOS uses a default view
    guard annotation is Photo else { return nil }
    
    //2 define reuse identifier
    let identifier = "Photo"
    
    //3 dequeue annotation view from the map view's pool of unused views
    //cast as MKPinAnnotationView to be able to change pin tint color
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKPinAnnotationView
    
    if annotationView == nil {
        //4 if unable to find, create a new one, and allow to show popup with the city name
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true

        if let annotation = annotation as? Photo {
            annotationView?.loadCustomLines(customLines: ["\(annotation.rtkStatus)", "Gimbal Pitch Degree: \(annotation.gimbalPitchDegree)", "Lat: \(annotation.coordinate.latitude)", "Lon: \(annotation.coordinate.longitude)", "Rel. Altitude (ft): \(annotation.relativeAltitudeFeet!)"])
            annotationView?.pinTintColor = annotation.rtkPinColor
        }
        
        //5 create button
        let btn = UIButton(type: .detailDisclosure)
        annotationView?.rightCalloutAccessoryView = btn
    } else {
        if let annotation = annotation as? Photo {
            annotationView?.loadCustomLines(customLines: ["\(annotation.rtkStatus)", "Gimbal Pitch Degree: \(annotation.gimbalPitchDegree)", "Lat: \(annotation.coordinate.latitude)", "Lon: \(annotation.coordinate.longitude)", "Rel. Altitude (ft): \(annotation.relativeAltitudeFeet!)"])
            annotationView?.pinTintColor = annotation.rtkPinColor
        }
        //6 if able to find, reuse view to update annotation
        annotationView?.annotation = annotation
    }
    return annotationView
}



func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    // This gets the selected pin.
    if let photoButtonClicked = view.annotation as? Photo {
        // This gets the view controller from your storyboard
        guard let vc = self.storyboard?.instantiateViewController(withIdentifier: "ThumbnailViewController") as? ThumbnailViewController else { return }
        
        // This passes the locations pin to the review view controller
        vc.thumbnail = photoButtonClicked.thumbnail ?? UIImage(named: "default")!
        vc.imageName = photoButtonClicked.title ?? "Photo"
        // This shows the review view controller
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

@objc func determineMapType() {
    print("bop")
    let ac = UIAlertController(title: "Map View", message: "How would you like to view the map?", preferredStyle: .actionSheet)
    ac.addAction(UIAlertAction(title: "Hybrid", style: .default, handler: { _ in
        self.mapView.mapType = .hybrid
    }))
    ac.addAction(UIAlertAction(title: "Hybrid Flyover", style: .default, handler: { _ in
        self.mapView.mapType = .hybridFlyover
    }))
    ac.addAction(UIAlertAction(title: "Muted Standard", style: .default, handler: { _ in
        self.mapView.mapType = .mutedStandard
    }))
    ac.addAction(UIAlertAction(title: "Satellite", style: .default, handler: { _ in
        self.mapView.mapType = .satellite
    }))
    ac.addAction(UIAlertAction(title: "Satellite Flyover", style: .default, handler: { _ in
        self.mapView.mapType = .satelliteFlyover
    }))
    ac.addAction(UIAlertAction(title: "Standard", style: .default, handler: { _ in
        self.mapView.mapType = .standard
    }))
    
    present(ac, animated: true)
    
    
}


}

extension MKAnnotationView {

    func loadCustomLines(customLines: [String]) {
        let stackView = self.stackView()
        for line in customLines {
            let label = UILabel()
            label.text = line
            stackView.addArrangedSubview(label)
        }
        self.detailCalloutAccessoryView = stackView
    }



    private func stackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        return stackView
    }
}
