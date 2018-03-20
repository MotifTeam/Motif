//
//  MicViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/7/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit
import AudioKitUI

class MicViewController: UIViewController {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var circleButtonView: CircleBackgroundView!
    @IBOutlet var backgroundView: RadialGradientView!
    
    @IBOutlet weak var inputWave: AKNodeOutputPlot!
    
    let mic = AKMicrophone()
    
    var micMixer: AKMixer!
    var micBooster: AKBooster!
    var recorder: AKNodeRecorder!
    
    var isRecording = false
    var musicTimer: Timer!
    var time: Double = 0
    var startTime: Double = 0
    var endTime: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        AKAudioFile.cleanTempDirectory()
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .record)
        } catch {
            AKLog("Could not set session category.")
        }
        mic.stop()
        inputWave.plotType = .rolling
        inputWave.shouldFill = true
        inputWave.shouldMirror = true
        inputWave.color = .red
        inputWave.gain = 8
        
        micMixer = AKMixer(mic)
        micBooster = AKBooster(micMixer)
        
        micBooster.gain = 0
        recorder = try? AKNodeRecorder(node: micMixer)
        
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
        let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
        backgroundView.colors = [color1, color2]
        
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
    
    @IBAction func startRecording() {
        isRecording = !isRecording
        
        if isRecording {
           start()
        } else {
            stop()
        }
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func start() {
        // let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        inputWave.node = mic

        inputWave.resetHistoryBuffers()
        mic.start()
        startTime = Date().timeIntervalSinceReferenceDate
        musicTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        
        do {
            try recorder.record()
        } catch {
            print("Errored recording.")
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            let color1 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.7)
            let color2 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.0)
            self.backgroundView.colors = [color1, color2]
            self.circleButtonView.backgroundColor = .red
            self.circleButtonView.layer.cornerRadius = 10
            self.circleButtonView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        })
            
        
        
    }
    
    func stop() {
        mic.stop()
        musicTimer.invalidate()
        inputWave.node = nil
        recorder.stop()
        
        UIView.animate(withDuration: 0.25, animations: {
            let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
            let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
            self.backgroundView.colors = [color1, color2]
            self.circleButtonView.backgroundColor = UIColor(red: 0.33, green: 0.64, blue: 0.95, alpha: 1.0)
            self.circleButtonView.layer.cornerRadius = self.circleButtonView.bounds.size.width / 2
            self.circleButtonView.transform = CGAffineTransform.identity
        })
    }
}
