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
    weak var player: AKAudioPlayer?
    var db: Firestore!

    func updateSlider() {
        if (player != nil) {
            let playingPositionSlider = AKSlider(property: "Position",
                                                 value: player!.playhead,
                                                 range: 0 ... player!.duration,
                                                 format: "%0.2f s") { _ in }
            playbackControllerView.addSubview(playingPositionSlider)
            _ = AKPlaygroundLoop(every: 1 / 60.0) {
                if self.player!.duration > 0 {
                    playingPositionSlider.value = self.player!.playhead
                }

            }
        }
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        self.goback.isEnabled = false
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
        print("click")
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
        try! Auth.auth().signOut()
        
        guard let vc = UIStoryboard(name: "Login",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                return
        }
        self.present(vc, animated: true, completion: nil)
    }

    @IBAction func unwindtoClip(segue: UIStoryboardSegue) {
    }
}
