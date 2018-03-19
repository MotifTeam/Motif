//
//  MicViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/7/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AVFoundation

class MicViewController: UIViewController {

    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var circleButtonView: CircleBackgroundView!
    @IBOutlet var backgroundView: RadialGradientView!
    
    var isRecording = false
    var musicTimer: Timer!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var time: Double = 0
    var startTime: Double = 0
    var endTime: Double = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { allowed in
                DispatchQueue.main.async {
                    if allowed {
                        // self.loadRecordingUI()
                        print("we can record")
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
        let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
        backgroundView.colors = [color1, color2]
        
    }

    @objc func updateTimer() {
        
        audioRecorder.updateMeters()

        //print to the console if we are beyond a threshold value. Here I've used -7
        if audioRecorder.averagePower(forChannel: 1) > -160 {

            print(" level I'm hearin' you in dat mic ")
            print(audioRecorder.averagePower(forChannel: 0))
        }
                
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
        let audioFilename = getDocumentsDirectory().appendingPathComponent("recording.m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.isMeteringEnabled = true

            audioRecorder.record()
            startTime = Date().timeIntervalSinceReferenceDate
            musicTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            
            UIView.animate(withDuration: 0.25, animations: {
                let color1 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.7)
                let color2 = UIColor(red: 1, green: 0, blue: 0, alpha: 0.0)
                self.backgroundView.colors = [color1, color2]
                self.circleButtonView.backgroundColor = .red
                self.circleButtonView.layer.cornerRadius = 10
                self.circleButtonView.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            })
            
        } catch {
            finishRecording(success: false)
        }
        
    }
    
    func stop() {
        musicTimer.invalidate()
        finishRecording(success: true)
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

extension MicViewController: AVAudioRecorderDelegate {
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            print("success")
        } else {
            print("failed")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
}
