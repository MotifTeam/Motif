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
    
    
    
    var parentVC: MIDIClipViewController!
    var clip: MIDIClip?
    var player: AVMIDIPlayer?
    @IBOutlet weak var previewImageView: UIImageView!
    @IBOutlet weak var time: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    
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
