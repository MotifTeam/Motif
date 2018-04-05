//
//  MIDIClip.swift
//  Motif
//
//  Created by Andrew Martin on 4/4/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit

struct MIDIClip: Equatable {
    let midiData: Data
    let creator: String
    let timestamp: Date
    
    func createMIDIPreviewImage(size: CGSize, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let tempFileURL = TemporaryFileURL(extension: "mid")
        do {
            try midiData.write(to: tempFileURL.contentURL, options: [.atomic])
        }
        catch {
            print("DIDN'T WRITE TO MIDI")
            print(error)
        }
        let outputFileUrl = TemporaryFileURL(extension: "txt")
        //print(tempFileURL.contentURL.path)
        tempFileURL.contentURL.withUnsafeFileSystemRepresentation { (midiPath) in
            outputFileUrl.contentURL.withUnsafeFileSystemRepresentation{ (outPath) in
                let args = ["midi-json"]
                //print(args)
                //print(midiData.base64EncodedString())
                var cargs = args.map { strdup($0) }
                let result = midiJSONMainWrapper(Int32(cargs.count), &cargs, midiPath, outPath)
                for ptr in cargs { free(ptr) }
                //print(result)
                //try? print(try String(contentsOfFile: outputFileUrl.contentURL.path, encoding: String.Encoding.ascii))
            }
            
        }
    
        //try print(try! FileHandle(forReadingFrom: outputFileUrl.contentURL).readDataToEndOfFile())
        let decoded = try? JSONDecoder().decode([MIDIEvent].self, from: Data(contentsOf:outputFileUrl.contentURL))
        
        var notesOn: [Int8:Int64] = [:]
        var notesPlayed: [NoteInterval] = []
        if decoded != nil {
            for event in decoded! {
                print (event)
                if let noteNum = event.note {
                    if let startTime = notesOn[noteNum] {
                        let note = NoteInterval(noteNumber: noteNum, startTime: startTime, endTime: event.time!)
                        notesPlayed.append(note)
                        notesOn[noteNum] = nil
                    }
                    else {
                        notesOn[noteNum] = event.time!
                    }
                }
            }
            //print(notesPlayed)
            var maxNote = Int8(71)
            if let maxPlayed = (notesPlayed.map {$0.noteNumber}.max()) {
                maxNote = max(maxPlayed, maxNote)
            }
            var minNote = Int8(48)
            if let minPlayed = (notesPlayed.map {$0.noteNumber}.min()) {
                minNote = min(minPlayed, minNote)
            }
            
            let endTime = notesPlayed.map {$0.endTime}.max()
            let noteHeight = size.height / (CGFloat(maxNote)-CGFloat(minNote)+1)
            color.setFill()
            for note in notesPlayed {
                
                let x = (CGFloat(note.startTime)/CGFloat(endTime!)) * size.width
                let y = (CGFloat(maxNote)-CGFloat(note.noteNumber)) * CGFloat(noteHeight)
                
                let width = size.width * CGFloat(note.endTime - note.startTime) / CGFloat(endTime!)
                let noteRect = CGRect(x:x, y:y, width:width, height:noteHeight)
                UIRectFill(noteRect)
                
            }
        }
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    static func == (lhs: MIDIClip, rhs: MIDIClip) -> Bool {
        return
            lhs.midiData == rhs.midiData &&
                lhs.timestamp == rhs.timestamp &&
                lhs.creator == rhs.creator
    }
}

public final class TemporaryFileURL {
    public let contentURL: URL
    public init(extension ext: String) {
        contentURL = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(ext)
    }
    deinit {
        DispatchQueue.global(qos: .utility).async { [contentURL = self.contentURL] in
            try? FileManager.default.removeItem(at: contentURL)
        }
    }
}

struct NoteInterval {
    let noteNumber: Int8
    let startTime: Int64
    let endTime: Int64
}

struct MIDIEvent {
    let trackNum: Int8
    let time: Int64?
    let type: String?
    let number: Int?
    let note: Int8?
    let vel: Int8?
    
    enum CodingKeys: String, CodingKey {
        case trackNum = "track_no"
        case time = "abs_time"
        case type
        case number
        case note
        case vel
    }
    
}

extension MIDIEvent: Decodable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.trackNum = try container.decodeIfPresent(Int8.self, forKey: .trackNum) ?? 0
        self.time = try container.decodeIfPresent(Int64.self, forKey: .time) ?? nil
        self.type = try container.decodeIfPresent(String.self, forKey: .type) ?? nil
        self.number = try container.decodeIfPresent(Int.self, forKey: .number) ?? nil
        self.note = try container.decodeIfPresent(Int8.self, forKey: .note) ?? nil
        self.vel = try container.decodeIfPresent(Int8.self, forKey: .vel) ?? nil
    }
}
