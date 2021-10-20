//
//  FolderViewController.swift
//  DronePhotoChecker
//
//  Created by Grant Matthias Hosticka on 9/24/21.
//

import UIKit
import DJISDK

class MediaListViewController: UIViewController, DJICameraDelegate, DJIMediaManagerDelegate, UITableViewDelegate, UITableViewDataSource {

    
    @IBOutlet var folderTableView: UITableView!
    @IBOutlet var loadingIndicator: UIActivityIndicatorView!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var loadingLabel: UILabel!
    @IBOutlet var proceedButton: UIBarButtonItem!
    
    var startDate = Date()
    var endDate = Date()
    var dateRange = ClosedRange<Date>(uncheckedBounds: (lower: Date(), upper: Date()))
    
    weak var mediaManager : DJIMediaManager?
    var mediaList = [MediaInfo]()
    
    var mediaProgressNumber = 0
    var loadingTimer = Timer()

    override var prefersStatusBarHidden : Bool {
        return false
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        loadingTimer.invalidate()
        guard let camera = fetchCamera() else { return }
        
        camera.setMode(DJICameraMode.shootPhoto, withCompletion: { (error: Error?) in
            if let error = error {
                showAlert(on: self, with: "Set CameraWorkModeShootPhoto Failed", message: "\(error.localizedDescription)")
            }
        })
        guard let cameraDelegate = camera.delegate else {
            return
        }
        if cameraDelegate.isEqual(self) {
            camera.delegate = nil
            self.mediaManager?.delegate = nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mediaProgressNumber = 0
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        self.title = ("\(dateFormatter.string(from: startDate)) - \(dateFormatter.string(from: endDate))")
        
        dateRange = startDate...endDate
        progressView.setProgress(0.0, animated: false)
        updateLoadingUI(loadedStatus: false, loadingText: "Loading Photos in Time Frame")
        
        let optionalCamera = fetchCamera()
        guard let camera = optionalCamera else {
            print("Couldn't fetch camera")
            return
        }
        camera.delegate = self
        self.mediaManager = camera.mediaManager
        self.mediaManager?.delegate = self
        camera.setMode(DJICameraMode.mediaDownload) { (error : Error?) in
            if let error = error {
                print("setMode failed: %@", error.localizedDescription)
            }
        }
        
        self.loadMediaList()
    }
    
    func updateLoadingUI(loadedStatus: Bool, loadingText: String) {
        loadingIndicator.isHidden = loadedStatus
        loadingLabel.isHidden = loadedStatus
        loadingLabel.text = loadingText
        progressView.isHidden = loadedStatus
        proceedButton.isEnabled = loadedStatus
        
        self.view.bringSubviewToFront(self.progressView)
        self.view.bringSubviewToFront(self.loadingLabel)
        self.view.bringSubviewToFront(self.loadingIndicator)
    }
    
    func loadMediaList() {
        if self.mediaManager?.sdCardFileListState == DJIMediaFileListState.syncing ||
            self.mediaManager?.sdCardFileListState == DJIMediaFileListState.deleting {
            print("Media Manager is busy. ")
        } else {
            self.mediaManager?.refreshFileList(of: DJICameraStorageLocation.sdCard, withCompletion: {[weak self] (error:Error?) in
                if let error = error {
                    print("Fetch Media File List Failed: %@", error.localizedDescription)
                } else {
                    print("Fetch Media File List Success.")
                    if let mediaFileList = self?.mediaManager?.sdCardFileListSnapshot() {
                        self?.updateMediaList(cameraMediaList:mediaFileList)
                    }
                    //start timer to load xmp information, otherwise media manager will be busy an ignore requests in a standard for loop
                    self?.loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
                        if let vc = self {
                            //check if all media have loaded xmp information
                            if vc.mediaProgressNumber == vc.mediaList.count{
                                timer.invalidate()
                                //then load thumbnails
                                //don't have this quite right as the table view populates before all thumbnails have loaded
                                if let mediaTaskScheduler = fetchCamera()?.mediaManager?.taskScheduler {
                                    mediaTaskScheduler.suspendAfterSingleFetchTaskFailure = false
                                    vc.mediaList.forEach({ (file: MediaInfo) in
                                        if file.mediaFile?.thumbnail == nil {
                                            let task = DJIFetchMediaTask(file: file.mediaFile!, content: DJIFetchMediaTaskContent.thumbnail) { (file: DJIMediaFile, content: DJIFetchMediaTaskContent, error: Error?) in
                                            }
                                            mediaTaskScheduler.moveTask(toEnd: task)
                                        }
                                    })

                                    mediaTaskScheduler.resume { error in
                                        if let error = error {
                                            print(error)
                                        }
                                    }
                                    vc.folderTableView.reloadData()
                                    vc.updateLoadingUI(loadedStatus: true, loadingText: "")
                                    return
                                }
                            } //check if current media has already loaded xmp information
                            else if vc.mediaList[vc.mediaProgressNumber].mediaFile?.xmpInformation != nil {
                                vc.progressView.setProgress(((Float(vc.mediaProgressNumber) / Float(vc.mediaList.count) / 2.0) + 0.5), animated: true)
                                vc.loadingLabel.text = "Collecting Metadata"
                                vc.mediaProgressNumber += 1
                            } //check if media manager is busy and then load xmp information
                            else if vc.mediaManager?.sdCardFileListState != DJIMediaFileListState.syncing &&
                                vc.mediaManager?.sdCardFileListState != DJIMediaFileListState.deleting{
                                vc.mediaList[vc.mediaProgressNumber].mediaFile?.fetchXMPFileData { error in
                                    if let error = error {
                                        print("fetch xmp error: \(error)")
                                    } else {
                                        vc.progressView.setProgress(((Float(vc.mediaProgressNumber) / Float(vc.mediaList.count) / 2.0) + 0.5), animated: true)
                                        vc.loadingLabel.text = "Collecting Metadata"
                                        //verify xmpinformation has been added before progressing to next media item
                                        if vc.mediaList[vc.mediaProgressNumber].mediaFile?.xmpInformation != nil {
                                            vc.mediaProgressNumber += 1
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                }
            })
        }
    }
    
    func updateMediaList(cameraMediaList:[DJIMediaFile]) {
        self.mediaList.removeAll()
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd' 'HH:mm:ss"
        
        for media in cameraMediaList {
            let mediaDate = dateFormatter.date(from:media.timeCreated)!
            if dateRange.contains(mediaDate){
                let mediaInfo = MediaInfo()
                mediaInfo.mediaFile = media
                self.mediaList.append(mediaInfo)
            }
        }
    }

    //MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection: Int) -> Int {
        return self.mediaList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "folder", for:indexPath)
    
        if let media = self.mediaList[indexPath.row].mediaFile {
            cell.textLabel?.text = media.fileName
            var detailText = ""//"Create Date: \(media.timeCreated)   "
            detailText.append(String(format: " Size: %0.1fMB", Double(media.fileSizeInBytes) / 1024.0 / 1024.0))

            cell.detailTextLabel?.text = detailText
        
            if let thumbnail = media.thumbnail {
                cell.imageView?.image = thumbnail
            } else {
                cell.imageView?.image = UIImage(named: "default")
            }
            
            if self.mediaList[indexPath.row].checked {
                cell.accessoryType = .checkmark
            } else{
                cell.accessoryType = .none
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if mediaList[indexPath.row].checked {
            mediaList[indexPath.row].checked = false
        } else {
            mediaList[indexPath.row].checked = true
        }
        folderTableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "photoToMap") {
            let destinationVC = segue.destination as! MapViewController
            destinationVC.mediaList = mediaList
        }
    }
}

