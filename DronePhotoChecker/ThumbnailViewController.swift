//
//  ThumbnailViewController.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 10/16/21.
//

import UIKit

class ThumbnailViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var thumbnailImageView: UIImageView!
    var thumbnail = UIImage()
    var imageName = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = imageName
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
        
        let image = thumbnail

        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailImageView.image = image
        thumbnailImageView.contentMode = .scaleAspectFit
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return thumbnailImageView
    }

}
