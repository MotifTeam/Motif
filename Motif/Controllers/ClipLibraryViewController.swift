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

//class ClipTableViewCell: UITableViewCell, AKLiveViewController {
    //if let sound_clip = NSDataAsset(name:"rain-3")
//}

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


class ClipLibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var playbackControllerView: UIView!
    
    var player: AKAudioPlayer?
    
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
        tableView.delegate = self
        tableView.dataSource = self
        // Do any additional setup after loading the view.
        
        
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
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
