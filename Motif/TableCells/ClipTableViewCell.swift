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
import Firebase

class ClipTableViewCell: UITableViewCell {

    @IBOutlet weak var clipName: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var url: URL!
    var storagePath: String!
    var playing = false
    var playingPositionSlider: AKSlider!
    var playTimer: Timer!
    
    var fileName: String! {
        didSet {
            clipName.text! = fileName
                .replace(target: "Motif-", withString: "")
                .replace(target: ".m4a", withString: "")
        }
    }
    var duration: Double! {
        didSet {
            playingPositionSlider.range = 0 ... duration
        }
    }

    
    let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let margins = layoutMarginsGuide
        let playMargins = playButton.layoutMarginsGuide
        playingPositionSlider =
            AKSlider(property: "",
                     value: 0,
                     range: 0 ... 1,
                     format: "%.02fs")
        playingPositionSlider.translatesAutoresizingMaskIntoConstraints = false
        addSubview(playingPositionSlider)

        playingPositionSlider.heightAnchor.constraint(equalToConstant: 40).isActive = true
        playingPositionSlider.leadingAnchor.constraint(equalTo: playMargins.trailingAnchor, constant: 32).isActive = true
        playingPositionSlider.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: -8).isActive = true
        playingPositionSlider.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: -8).isActive = true
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
        playTimer = Timer.scheduledTimer(timeInterval: 1/30, target: self, selector: #selector(updateSlider), userInfo: nil, repeats: true)
    }
    
    func pauseClip() {
        playTimer.invalidate()
        AudioManager.sharedInstance.pauseAudioData()
    }
    
    @objc func updateSlider() {
        playingPositionSlider.value = AudioManager.sharedInstance.playerValue()
        
    }
}
