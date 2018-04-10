//
//  ClipLibraryViewController.swift
//  Motif
//
//  Created by Jaime Munoz on 3/21/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit
import AVFoundation
import AudioKitUI
import Firebase
import CoreData

let soundFontURL = Bundle.main.url(forResource: "gs_soundfont", withExtension: "sf2")!
let cellImageCache = NSCache<NSData, UIImage>()

class ClipLibraryViewController: UIViewController {

    
    @IBOutlet weak var tableView: UITableView!
    
    weak var player: AKAudioPlayer?
    var db: Firestore!
    var tableViewBool = true
    var songs = [NSManagedObject]()
    var clips: [MIDIClip] = []
    
    let cellNib = UINib(nibName: "ClipTableViewCell", bundle: nil)
    let midiNib = UINib(nibName: "MIDIClipViewCell", bundle: nil)
    let cellSpacingHeight: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAuth()
        setUpTable()
    }
    
    private func setupDB() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        updateMIDIClips()
    }
    
    private func updateMIDIClips() {
        let uid = Auth.auth().currentUser?.uid ?? "0"
        db.collection("users").document(uid).collection("clips").order(by: "time").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    self.clips.append(MIDIClip(midiData: document["midiData"] as! Data, creator: document["creator"] as! String, timestamp: document["time"] as! Date))
                }
                self.tableView.reloadData()
            }
        }
    }
    
    private func setUpTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellNib, forCellReuseIdentifier: "clipCell")
        tableView.register(midiNib, forCellReuseIdentifier: "midiCell")
        tableView.estimatedRowHeight = 140
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        updateAudioClips()
        tableView.reloadData()
    }
    
    private func updateAudioClips() {
        songs = retrieveAudioClips()
    }
    
    private func checkAuth(){
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                print("user is logged in")
            } else {
                guard let vc = UIStoryboard(name: "Login",
                                            bundle: nil)
                    .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                        return
                }
                self.present(vc, animated: true, completion: nil)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func retrieveAudioClips() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Song")
        var fetchedResults:[NSManagedObject]? = nil
        
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
        } catch {
            // If an error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
        return(fetchedResults)!
    }
    
//    func updateSlider() {
//        if (player != nil) {
//            let playingPositionSlider = AKSlider(property: "Position",
//                                                 value: player!.playhead,
//                                                 range: 0 ... player!.duration,
//                                                 format: "%0.2f s") { _ in }
//            playbackControllerView.addSubview(playingPositionSlider)
//            _ = AKPlaygroundLoop(every: 1 / 60.0) {
//                if self.player!.duration > 0 {
//                    playingPositionSlider.value = self.player!.playhead
//                }
//
//            }
//        }
//    }

    @IBAction func logOut() {
        try! Auth.auth().signOut()
        
        guard let vc = UIStoryboard(name: "Login",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                return
        }
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func unwindtoClip(segue: UIStoryboardSegue) {}
    
    @IBAction func switchTable(_ sender: Any) {
        let segmentControl = sender as! UISegmentedControl
        let index = segmentControl.selectedSegmentIndex
        print(index)
        if index == 1 {
            tableViewBool = false
            updateMIDIClips()
            tableView.reloadData()
        }
        else {
            tableViewBool = true
            updateAudioClips()
            tableView.reloadData()
        }
    }
}

extension ClipLibraryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if tableViewBool {
            return songs.count
        } else {
            return clips.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = indexPath.section
        if tableViewBool {
            let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath as IndexPath) as! ClipTableViewCell
            
            let curr_clip = songs[row]
            
            if let clip_name = curr_clip.value(forKey:"name") {
                cell.fileName = String(describing:clip_name)
            }
            if let clip_url = curr_clip.value(forKey:"url") {
                cell.url = clip_url as! URL
                print("cell URL: \(cell.url)")
            }
            
            let audioAsset = AVURLAsset.init(url: cell.url, options: nil)
            let duration = audioAsset.duration
            let durationInSeconds = CMTimeGetSeconds(duration)
            
            cell.timeLabel.text = "\(durationInSeconds)"
            
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "midiCell", for: indexPath as IndexPath) as! MIDIClipViewCell
            let row = indexPath.row
            cell.populate(clips[row])
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return cellSpacingHeight
    }
    
    // Make the background color show through
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        return headerView
    }

}
