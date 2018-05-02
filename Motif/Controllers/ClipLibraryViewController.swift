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
import FirebaseStorage
import CoreData

let soundFontURL = Bundle.main.url(forResource: "gs_soundfont", withExtension: "sf2")!
let cellImageCache = NSCache<NSString, UIImage>()

class ClipLibraryViewController: UIViewController {

    
    @IBOutlet weak var slideOutConstraint: NSLayoutConstraint!
    @IBOutlet weak var slideOutView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var profileImage: UIImageView!
    
    private let refreshControl = UIRefreshControl()
    
    weak var player: AKAudioPlayer?
    var db: Firestore?
    var tableViewBool = true
    var songs = [NSManagedObject]()
    var clips: [MIDIClip] = []
    var initialTouchPoint: CGPoint = CGPoint(x: 0, y: 0)
    
    let cellNib = UINib(nibName: "ClipTableViewCell", bundle: nil)
    let midiNib = UINib(nibName: "MIDIClipViewCell", bundle: nil)
    let cellSpacingHeight: CGFloat = 5
    
    let storageRef = Storage.storage().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkAuth()
        setUpTable()
        setupDB()
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(gestureHandler(_:)))
        self.slideOutView.addGestureRecognizer(gestureRecognizer)
        
        profileImage.contentMode = .scaleAspectFit
        profileImage.layer.cornerRadius = self.profileImage.frame.width/2
        profileImage.layer.borderColor = UIColor.white.cgColor
        profileImage.layer.borderWidth = 2
        profileImage.layer.masksToBounds = true
        
        refreshControl.addTarget(self, action: #selector(refreshData(sender:)), for: .valueChanged)
        
    }
    
    @objc func refreshData(sender: Any) {
        if tableViewBool {
            updateAudioClips()
        } else {
            updateMIDIClips()
        }
        tableView.reloadData()
        
    }
    
    private func setupDB() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        updateMIDIClips()
        let uid = Auth.auth().currentUser?.uid ?? "0"
        db!.collection("users").document(uid).collection("midi_clips").addSnapshotListener { querySnapshot, error in
            var newClips: [MIDIClip] = []
            for document in querySnapshot!.documents {
                print("\(document.documentID) => \(document.data())")
                newClips.append(MIDIClip(midiData: document["midiData"] as! Data, creator: document["creator"] as! String, timestamp: document["time"] as! Date, documentRef: document.reference))
            }
            self.clips = newClips
            self.tableView.reloadData()
        }
    }
    
    private func updateMIDIClips() {
        let uid = Auth.auth().currentUser?.uid ?? "0"
    
        if let db = db { db.collection("users").document(uid).collection("midi_clips").order(by: "time").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }
                    self.clips = []
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        self.clips.append(MIDIClip(midiData: document["midiData"] as! Data, creator: document["creator"] as! String, timestamp: document["time"] as! Date, documentRef: document.reference))
                    }
                }
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
        tableView.refreshControl = refreshControl
        updateAudioClips()
        tableView.reloadData()
    }
    
    private func updateAudioClips() {
        songs = retrieveAudioClips()
        var clipsInLocalStorage = Dictionary<String, NSManagedObject>()
        for clip in songs {
            clipsInLocalStorage[(clip.value(forKey: "name") as! String)] = clip
        }
        print(clipsInLocalStorage)
        let dispatchGroup = DispatchGroup()
        let uid = Auth.auth().currentUser?.uid ?? "0"
        
        if let db = db { db.collection("users").document(uid).collection("audio_clips").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                if self.refreshControl.isRefreshing {
                    self.refreshControl.endRefreshing()
                }
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    let clip_name = document["name"] as! String
                    
                    if (clipsInLocalStorage[clip_name] == nil) {
                        clipsInLocalStorage[clip_name] = nil
                        //self.refreshControl.beginRefreshing()
                        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
                        let documentsDirectory = paths[0]
                        let fileRootPath = "file:\(documentsDirectory)/"
                        let filePath = fileRootPath + String(describing: clip_name)
                        if let clip_path = document["storageRef"] {
                            let storagePath = clip_path as! String
                            let fileURL = URL(string: filePath)
                            dispatchGroup.enter()
                            self.storageRef.child(clip_path as! String).write(toFile: fileURL!, completion: { (url, error) in
                                dispatchGroup.leave()
                                
                                if let error = error {
                                    print("Error downloading:\(error)")
                                    //self.statusTextView.text = "Download Failed"
                                    return
                                }
                                print("Download success")
                                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                let context = appDelegate.persistentContainer.viewContext
                                
                                let song = NSEntityDescription.insertNewObject(forEntityName: "Song",
                                                                               into: context)
                                song.setValue(clip_name, forKey: "name")
                                song.setValue(fileURL, forKey: "url")
                                song.setValue(document["duration"], forKey: "duration")
                                song.setValue(storagePath, forKey: "storageRef")
                                do {
                                    try context.save()
                                } catch {
                                    let nserror = error as NSError
                                    NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                                    abort()
                                }
                                self.songs = self.retrieveAudioClips()
                                self.tableView.reloadData()
                            })
                        }
                    }
                    
                }
               
            }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            do {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                try context.save()
                self.songs = self.retrieveAudioClips()
                self.tableView.reloadData()
                
            } catch {
                // If an error occurs
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
        
        
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
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

    @IBAction func logOut() {
        try! Auth.auth().signOut()
        
        guard let vc = UIStoryboard(name: "Login",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                return
        }
        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func goRecord() {
        let mode = UserDefaults.standard.bool(forKey: "recording")
        
        if mode {
            guard let vc = UIStoryboard(name: "Recording",
                                        bundle: nil)
                .instantiateViewController(withIdentifier: "micView") as? MicViewController else {
                    return
            }
            self.present(vc, animated: true, completion: nil)
        } else {
            guard let vc = UIStoryboard(name: "Recording",
                                        bundle: nil)
                .instantiateViewController(withIdentifier: "pianoView") as? PianoViewController else {
                    return
            }
            self.present(vc, animated: true, completion: nil)
        }
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
    
    @IBAction func openSideView(_ sender: Any) {
        UIView.animate(withDuration: 0.5) {
            self.slideOutConstraint.constant = 0
            self.view.layoutIfNeeded()

        }
    }
    @IBAction func closeSideView(_ sender: Any) {
        slideOutConstraint.constant = -220

        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func gestureHandler(_ sender: UIPanGestureRecognizer) {
        let viewTranslation = sender.translation(in: self.slideOutView)
        let label = sender.view!
        if sender.state == .began {
            initialTouchPoint = CGPoint(x: label.center.x + label.frame.width/2, y: label.center.y)
        }
        if viewTranslation.x < 0 {
            label.center = CGPoint(x: label.center.x + viewTranslation.x, y: label.center.y)
        }
        if sender.state == .ended {
            if abs(label.center.x) + initialTouchPoint.x > 100 {
                self.closeSideView(sender)
            } else {
                UIView.animate(withDuration: 0.3, animations: {
                    label.center = self.initialTouchPoint
                })
            }
        }
        sender.setTranslation(CGPoint.zero, in: self.slideOutView)
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
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let fileRootPath = "file:\(documentsDirectory)/"
        
        if tableViewBool {
            let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath as IndexPath) as! ClipTableViewCell
            
            var filePath = ""
            
            let curr_clip = songs[row]
            
            if let clip_name = curr_clip.value(forKey:"name") {
                cell.fileName = String(describing:clip_name)
                filePath = fileRootPath + String(describing: clip_name)
            }
            
            let fileURL = URL(string: filePath)
            cell.url = fileURL
            
            print("Cell URL")
            print(fileURL)
            if let clip_time = curr_clip.value(forKey:"duration") {
                cell.duration = clip_time as! Double
            }/*
            if !FileManager.default.fileExists(atPath: filePath) {
                if let clip_path = curr_clip.value(forKey:"storageRef") {
                    cell.storagePath = clip_path as! String
                    storageRef.child(clip_path as! String).write(toFile: fileURL!, completion: { (url, error) in
                        if let error = error {
                            print("Error downloading:\(error)")
                            //self.statusTextView.text = "Download Failed"
                            return
                        }
                        print("Download success")
                    })
                }
            }
            */
            cell.preservesSuperviewLayoutMargins = false
            cell.separatorInset = UIEdgeInsets.zero
            cell.layoutMargins = UIEdgeInsets.zero
            
            return cell

        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "midiCell", for: indexPath as IndexPath) as! MIDIClipViewCell
            print(row)
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
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let row = indexPath.row
            if tableViewBool {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let song = songs[row]
                let deletedSongName = song.value(forKey: "name") as! String
                let uid = Auth.auth().currentUser?.uid ?? "0"
                db!.collection("users").document(uid).collection("audio_clips").document(deletedSongName).delete()
                let storagePath = song.value(forKey: "storageRef") as! String
                storageRef.child(storagePath).delete()
                context.delete(song)
                songs.remove(at: row)
                
                tableView.reloadData()
            } else {
                clips[row].documentRef.delete()
                clips.remove(at: row)
                tableView.beginUpdates()
                let indexSet = IndexSet(arrayLiteral: indexPath.section)
                tableView.deleteSections(indexSet, with: .fade)
                tableView.endUpdates()
                tableView.reloadData()
                
            }
        }
        
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
