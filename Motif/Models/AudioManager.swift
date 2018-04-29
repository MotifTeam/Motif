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
    private var oscMixer: AKMixer!
    private var pianoMixer: AKMixer!
    private var tempTime: Double!
    private var startTime: Double!

    private var sequencer: AKSequencer!

    var midiPlayers: [Int:AVMIDIPlayer] = [:]
    var oscillator: AKOscillator!
    var currentAmplitude = 0.1
    var currentRampTime = 0.2
    
    var tempTrack: AKMusicTrack!
    var pianoNode: AKRhodesPiano!
    
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
        
        pianoNode = AKRhodesPiano()
        sequencer = AKSequencer()
        pianoMixer = AKMixer(pianoNode)
        
        do {
            midiRecorder = try AKNodeRecorder(node: pianoMixer)
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
    
    func recordPiano(time: Double) {
        let booster = AKBooster(pianoMixer)
        let mixer = AKMixer(midiPlayer, booster)
        AudioKit.output = mixer
        startTime = time
        sequencer.newTrack()
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
        try! midiRecorder.reset()
        try! recorder.reset()
    }
    
//    func getURLwithMIDIFileData() -> URL? {
//        guard let seq = seq,
//            let data = seq.genData() else { return nil }
//        let fileName = "ExportedMIDI.mid"
//        do {
//            let tempPath = URL(fileURLWithPath: NSTemporaryDirectory().appending(fileName))
//            try data.write(to: tempPath as URL)
//            return tempPath
//        } catch {
//            print("couldn't write to URL")
//        }
//        return nil
//    }
    
    func saveSong(fileName: String, mode: RecordingType, completionHandler: @escaping (Bool, URL, Double) -> Void) {
        
        
        if mode == .microphone {
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
        } else {
            tape = midiRecorder.audioFile
            let data = sequencer.genData()
            let fileName = "Motif-\(fileName).mid"
            
            do {
                print(AKAudioFile.BaseDirectory.documents)
                let filePath = URL(fileURLWithPath: "\(AKAudioFile.BaseDirectory.documents)")
                    .appendingPathComponent(fileName)
                try data?.write(to: filePath)
                completionHandler(true, filePath, tape!.duration)
            } catch {
                completionHandler(false, URL(fileURLWithPath: ""), -1)
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
    
    func playNote(note: MIDINoteNumber, time: Double) {
        tempTime  = time
        pianoNode.trigger(frequency: note.midiNoteToFrequency())

    }
    
    func stopNote(note: MIDINoteNumber, time: Double) {
        pianoNode.trigger(frequency: note.midiNoteToFrequency(), amplitude: 0)
        sequencer.tracks[0].add(noteNumber: note,
                                velocity: 127,
                                position: AKDuration(seconds: time-startTime),
                                duration: AKDuration(seconds: time-tempTime))
        
        
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
