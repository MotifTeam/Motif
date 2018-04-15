//
//  AudioManager.swift
//  Motif
//
//  Created by Michael Asper on 4/3/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import Foundation
import AVFoundation
import AudioKit
import AudioKitUI

class AudioManager{
    
    enum RecordingType {
        case piano
        case microphone
    }
    
    static let sharedInstance = AudioManager()
    private var microphone: AKMicrophone!
    private var tracker: AKFrequencyTracker!
    private var silence: AKBooster!
    private var micMixer: AKMixer!
    private var mainMixer: AKMixer!
    private var micBooster: AKBooster!
    private var recorder: AKNodeRecorder!
    private var midiRecorder: AKNodeRecorder!
    private var player: AKAudioPlayer!
    private var midiPlayer: AKAudioPlayer!
    private var moogLadder: AKMoogLadder!
    private var tape: AKAudioFile?
    private var oscillator: AKOscillator!
    private var oscMixer: AKMixer!
    
    private var currentAmplitude = 0.1
    private var currentRampTime = 0.2
    
    var midiPlayers: [Int:AVMIDIPlayer] = [:]
    
    init() {
        AudioKit.disconnectAllInputs()
        AKAudioFile.cleanTempDirectory()
        AKSettings.bufferLength = .medium
        
        do {
            try AKSettings.setSession(category: .playAndRecord)
        } catch {
            AKLog("Could not set session category.")
        }
        
        AKSettings.audioInputEnabled = true
        microphone = AKMicrophone()
        micMixer = AKMixer(microphone)
        micBooster = AKBooster(micMixer)
        tracker = AKFrequencyTracker(microphone)
        silence = AKBooster(tracker, gain: 0)
        micBooster.gain = 0
        
        oscillator = AKOscillator(waveform: AKTable(.sawtooth))
        oscMixer = AKMixer(oscillator)
        
        do {
            midiRecorder = try AKNodeRecorder(node: oscMixer)
            recorder = try AKNodeRecorder(node: micMixer)
        } catch {
            print("Couldn't start recorder")
        }
        
        if let file = recorder.audioFile {
            player = try? AKAudioPlayer(file: file)
        }
        
        if let file = midiRecorder.audioFile {
            midiPlayer = try? AKAudioPlayer(file: file)
        }
        
        moogLadder = AKMoogLadder(player)
        mainMixer = AKMixer(moogLadder, micBooster)

        
        AudioKit.output = mainMixer
        
        do {
            try AudioKit.start()
        } catch {
            print(error)
        }
        
        resetRecording()
    }
    
    func recordPiano() {
        let mixer = AKMixer(midiPlayer)
        AudioKit.output = mixer
        do {
            try midiRecorder.record()
        } catch {
            print(error)
        }
    }
    
    func stopPiano() {
        midiRecorder.stop()
        AudioKit.output = mainMixer
    }
    
    func startRecording() {
        do {
            try recorder.record()
        } catch {
            print(error)
        }
    }

    func stopRecording() {
        recorder.stop()
    }
    
    func resetRecording() {
        try! recorder.reset()
    }
    
    func saveSong(fileName: String, completionHandler: @escaping (Bool, URL, Double) -> Void) {
        
        tape = recorder.audioFile
        if let tape = tape {
            tape.exportAsynchronously(name: "Motif-\(fileName)",
                                      baseDir: .documents,
                                      exportFormat: .m4a) {file, exportError in
                if let error = exportError {
                    print("Export Failed \(error)")
                    completionHandler(false,  tape.url, -1)
                } else {
                    print("Export succeeded")
                    completionHandler(true, file!.url, file!.duration)
                }
            }
        }
                                    
    }
    
    func getMic() -> AKMicrophone {
        return microphone
    }
    
    func playMIDIData(data: Data) {
        if let player = midiPlayers[data.hashValue] {
            player.currentPosition = 0
            player.play(nil)
            
        } else {
            do {
                let player = try AVMIDIPlayer(data: data, soundBankURL: soundFontURL)
                player.prepareToPlay()
                midiPlayers[data.hashValue] = player
                player.play(nil)
                
            } catch {
                print("Error creating midiplayer: \(error.localizedDescription)")
            }
        }
    }
    
    func replaceAudioData(fileURL: URL) {
        do {
            let akFile = try AKAudioFile(forReading: fileURL)
            try player.replace(file: akFile)
        } catch {
            print(error)
        }
    }
    
    func getCurrentAudio() -> URL {
        if let tape = tape {
            return tape.url
        } else {
            return URL(fileURLWithPath: "")
        }
    }
    
    func playAudioData() {
        player.play()
    }
    
    func playerValue() -> Double {
        return player.playhead
    }
    
    func pauseAudioData() {
        player.pause()
    }
}
