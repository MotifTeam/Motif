//
//  PianoViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//
import Foundation
import UIKit
//import PianoView
//import MusicTheorySwift
//import AudioKit
import CoreData
import Firebase
import WebKit
import AVFoundation


struct MIDIClip {
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
        print(tempFileURL.contentURL.path)
        tempFileURL.contentURL.withUnsafeFileSystemRepresentation { (midiPath) in
            outputFileUrl.contentURL.withUnsafeFileSystemRepresentation{ (outPath) in
                let args = ["midi-json"]
                print(args)
                print(midiData.base64EncodedString())
                var cargs = args.map { strdup($0) }
                let result = midiJSONMainWrapper(Int32(cargs.count), &cargs, midiPath, outPath)
                for ptr in cargs { free(ptr) }
                print(result)
                try? print(try String(contentsOfFile: outputFileUrl.contentURL.path, encoding: String.Encoding.ascii))
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
            print(notesPlayed)
            let maxNote = notesPlayed.map {$0.noteNumber}.max()
            let minNote = notesPlayed.map {$0.noteNumber}.min()
            let endTime = notesPlayed.map {$0.endTime}.max()
            let noteHeight = size.height / (CGFloat(maxNote!)-CGFloat(minNote!)+1)
            color.setFill()
            for note in notesPlayed {
                let x = (CGFloat(note.startTime)/CGFloat(endTime!)) * size.width
                let y = (CGFloat(maxNote!)-CGFloat(note.noteNumber)) * CGFloat(noteHeight)
                let width = size.width * CGFloat(note.endTime - note.startTime) / CGFloat(endTime!)
                let noteRect = CGRect(x:x, y:y, width:width, height:noteHeight)
                UIRectFill(noteRect)
                
            }
        }
        
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
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


class AIPianoViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    var aiImageView: UIImageView!
    var userImageView: UIImageView!
    var webView: WKWebView!
    
    @IBOutlet weak var placeholderView: UIView!
    var midiPlayer: AVMIDIPlayer?
    
    var db: Firestore!
    
    let eventNames = ["user", "ai"]
    var eventFunctions : Dictionary<String, (String)->Void> = Dictionary<String, (String)->Void>()
    
    var sessionClips: [MIDIClip] = []
    var clipsCollection: CollectionReference!
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        webConfiguration.userContentController = controller
        aiImageView = UIImageView(frame: CGRect(x:50, y:50, width: 200, height: 50))
        userImageView = UIImageView(frame: CGRect(x:50, y:100, width: 200, height: 50))
        eventFunctions["user"] = {(body) in
            if body.starts(with: "[77,84,") {
                let bytes = body.dropFirst().dropLast().split(separator: ",").map {UInt8($0)!}
                let clip = MIDIClip(midiData: Data(bytes:bytes), creator: "user", timestamp: Date())
                self.sessionClips.append(clip)
                let newClipRef = self.clipsCollection.document()
                newClipRef.setData([
                    "creator": clip.creator,
                    "midiData": clip.midiData,
                    "time": clip.timestamp]) {err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                }
                
            }
        }
        
        eventFunctions["ai"] = {(body) in
            if body.starts(with: "TVRoZ") {
                let clip = MIDIClip(midiData: Data(base64Encoded: body)!, creator: "ai", timestamp: Date())
                self.sessionClips.append(clip)
                
                
            }
        }
        
        for eventname in eventNames {
            controller.add(self, name: eventname)
        }
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        //view = webView
        webView.frame = placeholderView.frame
        placeholderView.addSubview(webView)
        placeholderView.addSubview(aiImageView)
        placeholderView.addSubview(userImageView)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showClips" {

        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        let uid = Auth.auth().currentUser?.uid ?? "0"
        clipsCollection = db.collection("users").document(uid).collection("clips")
        
        let myURL = URL(string: "https://experiments.withgoogle.com/ai/ai-duet/view/")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
        webView.evaluateJavaScript("""
                (function(send) {
                    XMLHttpRequest.prototype.send = function(body) {
                        var self = this
                        window.webkit.messageHandlers.user.postMessage(body);
                      
                        function onReadyStateChange() {
                            if (self.readyState == 4) {
                                console.log(self.response);
                                var base64 = btoa(new Uint8Array(self.response).reduce((data, byte) => data + String.fromCharCode(byte), ''));
                                if (base64.startsWith('TVRoZ')) { // Standard MIDI file format header
                                    window.webkit.messageHandlers.ai.postMessage(base64);
                                }
                                
                            }
                        }
                        this.addEventListener("readystatechange", onReadyStateChange, false);
                        send.call(this, body);
                    };
                })(XMLHttpRequest.prototype.send);
            """, completionHandler: nil)
        //let _ = placeholderView
        let button = UIButton(frame: CGRect(x: 320, y: 20, width:30, height:24))
        button.setImage(UIImage(named: "microphone"), for: .normal)
        
    }
    
    
    func createAVMIDIPlayerFromMIDIFIleDLS() {
        
        let midiString = ""
        var midiFileURL: URL!
        
        guard let bankURL = Bundle.main.url(forResource: "gs_soundfont", withExtension: "sf2" ) else {
            fatalError("\"gs_soundfont.sf2\" file not found.")
        }
        
        do {
            try self.midiPlayer = AVMIDIPlayer(contentsOf: midiFileURL, soundBankURL: bankURL)
            print("created midi player with sound bank url \(bankURL)")
        } catch let error as NSError {
            print("Error \(error.localizedDescription)")
        }
        
        self.midiPlayer?.prepareToPlay()
    }
    
    
    
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let contentBody = message.body as? String{
            if let eventFunction = eventFunctions[message.name] {
                eventFunction(contentBody)
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
}
