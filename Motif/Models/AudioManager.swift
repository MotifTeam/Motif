//
//  AudioManager.swift
//  Motif
//
//  Created by Michael Asper on 4/3/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import Foundation
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
        
        do {
             recorder = try AKNodeRecorder(node: micMixer)
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
    
    func stopRecording() -> AKAudioFile? {
        recorder.stop()
        return recorder.audioFile
    }
    
    func getMic() -> AKMicrophone {
        return microphone
    }
    
}
