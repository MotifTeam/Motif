//
//  ClipTableViewCell.swift
//  Motif
//
//  Created by Michael Asper on 4/6/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI
import AVFoundation

class ClipTableViewCell: UITableViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
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
