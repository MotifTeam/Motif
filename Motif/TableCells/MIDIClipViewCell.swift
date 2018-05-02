//
//  MIDIClipViewCell.swift
//  Motif
//
//  Created by Michael Asper on 4/6/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit

class MIDIClipViewCell: UITableViewCell {
    
    var clip: MIDIClip?
    var player: AVMIDIPlayer?
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    var playing = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    @IBAction func playerAction(_ sender: Any) {
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
    
    func pauseClip() {
        AudioManager.sharedInstance.pauseAudioData()
    }
    
    
    func playClip() {
        AudioManager.sharedInstance.playMIDIData(data: clip!.midiData, completion: {
                DispatchQueue.main.sync {
                    UIView.animate(withDuration: 0.3) {
                        self.playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
                        self.playing = false
                    }
                
                }
        })
    }
    
    func populate(_ clip: MIDIClip) {
        self.clip = clip
        time.text = clip.creator
        let imageSize = previewImageView.frame.size
        let color: UIColor = clip.creator == "ai" ? .orange : .blue
        var image: UIImage = UIImage()
        if let cachedImage = cellImageCache.object(forKey: clip.documentRef.documentID as NSString) {
            image = cachedImage
            print("cached, doc ID: \(clip.documentRef.documentID)")
        }
        else {
            DispatchQueue.global().async {
                image = clip.createMIDIPreviewImage(size: imageSize, color: color)
                print("generated")
                DispatchQueue.main.async {
                    cellImageCache.setObject(image, forKey: clip.documentRef.documentID as NSString)
                    self.previewImageView.image = image
                }
            }
        }
            

        
        
    }
}
