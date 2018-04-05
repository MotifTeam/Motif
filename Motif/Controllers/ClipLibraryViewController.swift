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

//class ClipTableViewCell: UITableViewCell, AKLiveViewController {
    //if let sound_clip = NSDataAsset(name:"rain-3")
//}

public var clip_names: [String] = ["rain-3"]

let textCellIdentifier = "songCell"




class ClipLibraryViewController: UIViewController {
    @IBOutlet weak var midiTableContainer: UIView!
    @IBOutlet weak var audioTableContainer: UIView!


    @IBAction func switchTable(_ sender: Any) {
        let segmentControl = sender as! UISegmentedControl
        let index = segmentControl.selectedSegmentIndex
        print(index)
        if index == 1 {
            audioTableContainer.alpha = 0
            midiTableContainer.alpha = 1
        }
        else {
            audioTableContainer.alpha = 1
            midiTableContainer.alpha = 0
        }
    }
    @IBOutlet weak var playbackControllerView: UIView!

    @IBOutlet weak var leadingConstraint: NSLayoutConstraint!

    @IBOutlet weak var goback: UIButton!
    var toggle = true
    var player: AKAudioPlayer?
    var db: Firestore!

    func updateSlider() {
        if (player != nil) {
            let playingPositionSlider = AKSlider(property: "Position",
                                                 value: player!.playhead,
                                                 range: 0 ... player!.duration,
                                                 format: "%0.2f s") { _ in }
            playbackControllerView.addSubview(playingPositionSlider)
            AKPlaygroundLoop(every: 1 / 60.0) {
                if self.player!.duration > 0 {
                    playingPositionSlider.value = self.player!.playhead
                }

            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        //goback.isEnabled = false

        // Do any additional setup after loading the view.
        // [START setup]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clip_names.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath as IndexPath) as! ClipTableViewCell

        let row = indexPath.row
        cell.clipName?.text = clip_names[row]
        cell.clipLibaryViewController = self
        return cell
    }

    @IBAction func toggleSlider() {
        UIView.animate(withDuration: 0.75) {
            if self.toggle {
                self.leadingConstraint.constant = 0
                self.goback.isEnabled = true
            } else {
                self.leadingConstraint.constant = -180
                self.goback.isEnabled = false
            }
        }

        toggle = !toggle
    }

    @IBAction func logOut() {

    }

    @IBAction func unwindtoClip(segue: UIStoryboardSegue) {
    }
}

class ClipTableViewCell: UITableViewCell {
    
    @IBOutlet weak var clipName: UILabel!
    var url: URL!
    
    var clipLibaryViewController: ClipLibraryViewController!
    var playingPositionSlider: AKSlider?
    
    var akFile: AKAudioFile!
    //var player: AVAudioPlayer!
    //var documentsDirectory: URL!
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var player: AVAudioPlayer!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        //akFile = try! AKAudioFile(readFileName: url, baseDir: .documents)
        //let player = try AVAudioPlayer(contentsOf: url)
        //var player = try! AVAudioPlayer(contentsOf: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    @IBAction func playClip(_ sender: Any) {
        print("Play button was pressed")
        //documentsDirectory.appendingPathComponent(clipName.text as! String)
        print(documentsDirectory.appendingPathComponent(clipName.text as! String))
        let song = documentsDirectory.appendingPathComponent(clipName.text as! String)
        //print(url.appendingPathComponent())
        //let path = Bundle.main.path(forResource: clipName.text, ofType: "wav")
        //let url = NSURL.fileURL(withPath: path!)
        
        // var akFile: AKAudioFile
        
        do {
            let akFile = try AKAudioFile(forReading: url)
            //let akFile = try AKAudioFile(readFileName: url, baseDir: .documents)
            print("File created")
            //print("File.sampleRate: \(akFile.duration)")
            
            let player = try AKAudioPlayer(file: akFile)
            //player.prepareToPlay()
            //player.volume = 1.0
            
            //guard let player = audioPlayer else { return }
            
            //clipLibaryViewController.player = audioPlayer
            //clipLibaryViewController.updateSlider()
            AudioKit.output = player
            try AudioKit.start()
            player.play()
            
        } catch let error as NSError {
            print("There's an error: \(error)")
        }
    }
}


class AudioClipViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let note_list = retrieveAudioClips()
        return note_list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: textCellIdentifier, for: indexPath as IndexPath) as! ClipTableViewCell
        
        let row = indexPath.row
        
        let fetched_results = retrieveAudioClips()
        let curr_clip = fetched_results[row]
        
        if let clip_name = curr_clip.value(forKey:"name") {
            cell.clipName?.text = String(describing:clip_name)
        }
        if let clip_url = curr_clip.value(forKey:"url") {
            cell.url = clip_url as! URL
        }
        
        //cell.textLabel?.text = teams[row]
        
        return cell
    }
    
    func retrieveAudioClips() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Song")
        var fetchedResults:[NSManagedObject]? = nil
        
        // Examples of filtering using predicates
        // let predicate = NSPredicate(format: "age = 35")
        // let predicate = NSPredicate(format: "name CONTAINS[c] 'ake'")
        // request.predicate = predicate
        
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
    
    
}


class MIDIClipViewCell: UITableViewCell {
    @IBOutlet weak var previewImageView: UIImageView!
    
    @IBOutlet weak var time: UILabel!
    @IBAction func rowTapped(_ sender: Any) {
        print("hi")
    }
}

class MIDIClipViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    var clips: [MIDIClip] = []

    var db: Firestore!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self

        let settings = FirestoreSettings()

        Firestore.firestore().settings = settings
        // [END setup]
        db = Firestore.firestore()

        let uid = Auth.auth().currentUser?.uid ?? "0"
        db.collection("users").document(uid).collection("clips").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    self.clips.append(MIDIClip(midiData: document.data()["midiData"] as! Data, creator: document.data()["creator"] as! String, timestamp: Date()))
                    print(self.clips.count)
                }
                self.tableView.reloadData()
            }

        }
        tableView.reloadData()
        print(clips)

    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "midiCell", for: indexPath) as! MIDIClipViewCell
        let index = indexPath.row
        
        DispatchQueue.global().async {
            let image = self.clips[index].createMIDIPreviewImage(size: cell.frame.size, color: .blue)
            DispatchQueue.main.async {
                cell.previewImageView.image = image
            }
        }
        
        
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clips.count
    }

}
