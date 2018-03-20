//
//  PianoViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import PianoView
import MusicTheorySwift
import AudioKit

class PianoViewController: UIViewController {
    
    @IBOutlet var backgroundView: RadialGradientView!
    @IBOutlet weak var pianoView: PianoView!
    
    var midi = AudioKit.midi
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(midi.inputNames)

        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(_ animated: Bool) {
        let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
        let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
        backgroundView.colors = [color1, color2]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
    func updateKeys(x: CGFloat) {
        let keyWidth = Int(pianoView.frame.width) / pianoView.keyCount
        let keyChoice = Int(Int(x)/keyWidth)
        var notes = NoteType.all.map({ Note(type: $0, octave: 0) })
        notes.append(contentsOf: NoteType.all.map({ Note(type: $0, octave: 1) }))
        let selectedNote = notes[keyChoice]
        pianoView?.deselectAll()
        pianoView?.selectNote(note: selectedNote)
        
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        for item in touches {
            if item.location(in: pianoView).x > 0 && item.location(in: pianoView).y > 0 {
                let x = item.location(in: pianoView).x
                updateKeys(x: x)
            }
        }
//        let notes = NoteType.all.map({ Note(type: $0, octave: 0) })
//        let randomNote = notes[Int(arc4random_uniform(UInt32(notes.count)))]
        //pianoView?.deselectAll()
//        pianoView?.selectNote(note: randomNote)
    }
}
