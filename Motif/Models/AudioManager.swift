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


class AudioManager{
    
    static let sharedInstance = AudioManager()
    private var microphone: AKMicrophone!
    private var tracker: AKFrequencyTracker!
    private var silence: AKBooster!
    private var micMixer: AKMixer!
    private var mainMixer: AKMixer!
    private var micBooster: AKBooster!
    private var recorder: AKNodeRecorder!
    private var player: AKAudioPlayer!
    private var moogLadder: AKMoogLadder!
    private var tape: AKAudioFile!
    
    var midiPlayer: AVMIDIPlayer?
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
        do {
            tape = try AKAudioFile()
            recorder = try AKNodeRecorder(node: micMixer, file: tape)
        } catch {
            print("Couldn't start recorder")
        }
        
        if let file = recorder.audioFile {
            player = try? AKAudioPlayer(file: file)
        }
        
        moogLadder = AKMoogLadder(player)
        mainMixer = AKMixer(moogLadder, micBooster)

        
        AudioKit.output = mainMixer
        
        do {
            try AudioKit.start()
        } catch {
            print(error)
        }
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
        
        recorder.stop()

        tape = recorder.audioFile
        
        tape.exportAsynchronously(name: "Motif-\(fileName)",
                                  baseDir: .documents,
                                  exportFormat: .m4a) {file, exportError in
            if let error = exportError {
                print("Export Failed \(error)")
                completionHandler(false,  self.tape.url, -1)
            } else {
                print("Export succeeded")
                completionHandler(true, file!.url, file!.duration)
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
        return tape.directoryPath
    }
    
    func playAudioData() {
        player.play()
    }
    
    func pauseAudioData() {
        player.pause()
    }
}
