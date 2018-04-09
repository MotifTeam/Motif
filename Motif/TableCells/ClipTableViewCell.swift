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
    
    @IBOutlet weak var clipName: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var progressView: UIProgressView!
    
    var url: URL!
    var fileName: String! {
        didSet {
            clipName.text! = fileName
                .replace(target: "Motif-", withString: "")
                .replace(target: ".m4a", withString: "")
        }
    }
    var clipLibaryViewController: ClipLibraryViewController!
    var playingPositionSlider: AKSlider?
    var akFile: AKAudioFile!
    var player: AVAudioPlayer!
    var playing = false
    
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func playerAction() {
        if playing {
            UIView.animate(withDuration: 0.3) {
                self.playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                self.playing = !self.playing
            }
            pauseClip()
        } else {
            UIView.animate(withDuration: 0.3) {
                self.playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
                self.playing = !self.playing
            }
            playClip()
        }
    }
    
    func playClip() {
        print("Play button was pressed")
        if AudioManager.sharedInstance.getCurrentAudio() != url {
            AudioManager.sharedInstance
                .replaceAudioData(fileURL: self.url)
        }
        AudioManager.sharedInstance.playAudioData()
    }
    
    func pauseClip() {
        AudioManager.sharedInstance.pauseAudioData()
    }
}
