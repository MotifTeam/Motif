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
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBOutlet weak var clipName: UILabel!
    var url: URL!
    
    var clipLibaryViewController: ClipLibraryViewController!
    var playingPositionSlider: AKSlider?
    
    var akFile: AKAudioFile!
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    var player: AVAudioPlayer!
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    @IBAction func playClip(_ sender: Any) {
        print("Play button was pressed")
        print(documentsDirectory.appendingPathComponent(clipName.text as! String))
        let song = documentsDirectory.appendingPathComponent(clipName.text as! String)

        
        do {
            let akFile = try AKAudioFile(forReading: url)
            print("File created")
            
            let player = try AKAudioPlayer(file: akFile)
            AudioKit.output = player
            try AudioKit.start()
            player.play()
            
        } catch let error as NSError {
            print("There's an error: \(error)")
        }
    }
}
