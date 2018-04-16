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
import AudioKitUI

class PianoViewController: UIViewController, AKKeyboardDelegate {

    
    @IBOutlet var backgroundView: RadialGradientView!
    @IBOutlet weak var pianoView: AKKeyboardView!
    @IBOutlet weak var circleButtonView: CircleBackgroundView!
    @IBOutlet weak var timerLabel: UILabel!
    var musicTimer: Timer!
    var isRecording = false
    var time: Double = 0
    var startTime: Double = 0
    var endTime: Double = 0
    
//    var midi = AudioKit.midi
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pianoView.delegate = self

        pianoView.keyOnColor = .blue
        pianoView.firstOctave = 1
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
    
    @IBAction func recording() {
        isRecording = !isRecording
        
        if isRecording {
            start()
        } else {
            stop()
        }
    }
    
    @objc func updateTimer() {
        
        // Calculate total time since timer started in seconds
        time = Date().timeIntervalSinceReferenceDate - startTime
        
        // Calculate minutes
        let minutes = UInt8(time / 60.0)
        time -= (TimeInterval(minutes) * 60)
        
        // Calculate seconds
        let seconds = UInt8(time)
        time -= TimeInterval(seconds)
        
        
        // Format time vars with leading zero
        let strMinutes = String(format: "%01d", minutes)
        let strSeconds = String(format: "%02d", seconds)
        
        timerLabel.text = "\(strMinutes):\(strSeconds)"
    }
    
    func start() {
        timerLabel.text = "0:00"
        
        startTime = Date().timeIntervalSinceReferenceDate
        musicTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        AudioManager.sharedInstance.recordPiano()
        setUpRecordingUI()
    }
    
    func stop() {
        // Stop Timing
        musicTimer.invalidate()
        
        AudioManager.sharedInstance.stopPiano()
        
        setUpPostRecordingUI()
    }
    
    func setUpPostRecordingUI() {
        UIView.animate(withDuration: 0.25, animations: {
            let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
            let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
            self.backgroundView.colors = [color1, color2]
            self.circleButtonView.backgroundColor = UIColor(red: 0.33, green: 0.64, blue: 0.95, alpha: 1.0)
            self.circleButtonView.layer.cornerRadius = self.circleButtonView.bounds.size.width / 2
            self.circleButtonView.transform = CGAffineTransform.identity
        })
    }
    
    func setUpRecordingUI() {
        UIView.animate(withDuration: 0.25, animations: {
            let color1 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.7)
            let color2 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.0)
            self.backgroundView.colors = [color1, color2]
            self.circleButtonView.backgroundColor = .red
            self.circleButtonView.layer.cornerRadius = 10
            self.circleButtonView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        })
    }
    
    func noteOn(note: MIDINoteNumber) {
        
        AudioManager.sharedInstance.pianoNode.trigger(frequency: note.midiNoteToFrequency())
        
    }
    
    func noteOff(note: MIDINoteNumber) {
        AudioManager.sharedInstance.pianoNode.trigger(frequency: note.midiNoteToFrequency(), amplitude: 0)
    }
}
