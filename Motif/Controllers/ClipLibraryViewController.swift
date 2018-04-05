//
//  ClipLibraryViewController.swift
//  Motif
//
//  Created by Jaime Munoz on 3/21/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI
import Firebase
import AVFoundation

//class ClipTableViewCell: UITableViewCell, AKLiveViewController {
    //if let sound_clip = NSDataAsset(name:"rain-3")
//}
let soundFontURL = Bundle.main.url(forResource: "gs_soundfont", withExtension: "sf2")!
let cellImageCache = NSCache<NSData, UIImage>()


public var clip_names: [String] = ["rain-3"]

let textCellIdentifier = "songCell"

class ClipTableViewCell: UITableViewCell {

    @IBOutlet weak var clipName: UILabel!

    var clipLibaryViewController: ClipLibraryViewController!
    var playingPositionSlider: AKSlider?

    var akFile: AKAudioFile!
    var player: AKAudioPlayer!

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        akFile = try! AKAudioFile(readFileName: "rain-03.wav", baseDir: .resources)
        player = try! AKAudioPlayer(file: akFile)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }


    @IBAction func playClip(_ sender: Any) {
        print("Play button was pressed")
        //let path = Bundle.main.path(forResource: clipName.text, ofType: "wav")
        //let url = NSURL.fileURL(withPath: path!)

        // var akFile: AKAudioFile
        do {
            let akFile = try AKAudioFile(readFileName: "rain-03.wav", baseDir: .resources)
            print("File created")
            print("File.sampleRate: \(akFile.duration)")

            let player = try AKAudioPlayer(file: akFile) {
                print("completion callback has been triggered!")
            }
            clipLibaryViewController.player = player
            clipLibaryViewController.updateSlider()
            AudioKit.output = player
            try AudioKit.start()
            player.play()

        } catch let error as NSError {
            print("There's an error: \(error)")
        }
    }
}

class MIDIClipViewCell: UITableViewCell {
    var parentVC: MIDIClipViewController!
    var clip: MIDIClip?
    var player: AVMIDIPlayer?
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var time: UILabel!
    
    @IBAction func playClip(_ sender: Any) {
        AudioManager.sharedInstance.playMIDIData(data: clip!.midiData)
    }
    
    func populate(_ clip: MIDIClip) {
        self.clip = clip
        time.text = clip.timestamp.description
        let imageSize = previewImageView.frame.size
        DispatchQueue.global().async {
            let color: UIColor = clip.creator == "ai" ? .orange : .blue
            var image: UIImage = UIImage()
            if let cachedImage = cellImageCache.object(forKey: clip.midiData as NSData) {
                image = cachedImage
            }
            else {
                image = clip.createMIDIPreviewImage(size: imageSize, color: color)
                cellImageCache.setObject(image, forKey: clip.midiData as NSData)
            }
            DispatchQueue.main.async {
                self.previewImageView.image = image
            }
        }
    }
}


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
    weak var player: AKAudioPlayer?
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

class MIDIClipViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var midiPlayer: AVMIDIPlayer?
    var clipPlaying: MIDIClip?

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
        db.collection("users").document(uid).collection("clips").order(by: "time").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    self.clips.append(MIDIClip(midiData: document["midiData"] as! Data, creator: document["creator"] as! String, timestamp: document["time"] as! Date))
                    //print(self.clips.count)
                }
                self.tableView.reloadData()
            }

        }
        tableView.reloadData()
        //print(clips)

    }
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "midiCell", for: indexPath) as! MIDIClipViewCell
        let row = indexPath.row
        cell.parentVC = self
        cell.populate(clips[row])
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clips.count
    }

}
