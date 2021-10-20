//
//  Photo.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/30/21.
//

import UIKit
import MapKit

//for map annotation can't use struct and must inherit from NSObject
class Photo: NSObject, MKAnnotation {
    var title: String?
    var rtkStatus = "RTK Status Not Found"
    var rtkPinColor: UIColor?
    var gimbalPitchDegree = ""
    var relativeAltitudeFeet: Double?
    var thumbnail: UIImage?
    //coordinate required for annotation on map
    var coordinate: CLLocationCoordinate2D

    
    init(title: String, coordinate: CLLocationCoordinate2D, rtkStatus: String, rtkPinColor: UIColor, gimbalPitchDegree: String, relativeAltitudeFeet: Double, thumbnail: UIImage) {
        self.title = title
        self.coordinate = coordinate
        self.rtkStatus = rtkStatus
        self.rtkPinColor = rtkPinColor
        self.gimbalPitchDegree = gimbalPitchDegree
        self.relativeAltitudeFeet = relativeAltitudeFeet
        self.thumbnail = thumbnail
    }

}
