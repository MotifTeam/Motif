//
//  PianoViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
//import PianoView
//import MusicTheorySwift
import AudioKit
import AudioKitUI
import CoreData
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
    
    @IBAction func keepRecording() {
        let alert = UIAlertController(title: "Keep Recording", message: "Label recording", preferredStyle: .alert)
        
        alert.addTextField { (textField) in
            textField.placeholder = "My Song Name"
        }
        
        alert.addTextField { (textField) in
            textField.placeholder = "tag1, tag2,..."
        }
        
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            if let songName = textField?.text {
                AudioManager.sharedInstance.saveSong(fileName: songName.replace(target: " ", withString: "_"), mode: .microphone) { result, url, duration in
                    if result {
                        print(duration)
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.saveSong(name: "Motif-\(songName)", location: url, duration: duration) // changed ext
                        })
                    } else {
                        print("failed")
                    }
                    
                    AudioManager.sharedInstance.resetRecording()
                    
                }
                
            } else {
                print("Failed")
            }
            //self.resetUI()
            
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action: UIAlertAction!) in
            
            print("Cancelled")
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func saveSong(name: String, location: URL, duration: Double) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let song = NSEntityDescription.insertNewObject(forEntityName: "Song",
                                                       into: context)
        song.setValue(name, forKey: "name")
        song.setValue(location, forKey: "url")
        song.setValue(duration, forKey: "duration")
        
        
        do {
            try context.save()
        } catch {
            // If an error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
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
        
        AudioManager.sharedInstance.recordPiano(time: startTime)
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
        AudioManager.sharedInstance.playNote(note: note, time: Date().timeIntervalSinceReferenceDate)
        
    }
    
    func noteOff(note: MIDINoteNumber) {
        AudioManager.sharedInstance.stopNote(note: note, time: Date().timeIntervalSinceReferenceDate)
    }
}
