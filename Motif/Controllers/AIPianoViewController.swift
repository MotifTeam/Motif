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
    
    func addClip(from data: Data, creator: String) {
        let newClipRef = self.clipsCollection.document()
        let clip = MIDIClip(midiData: data, creator: creator, timestamp: Date(), documentRef: newClipRef)
        self.sessionClips.append(clip)
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
                self.addClip(from: Data(bytes:bytes), creator: "user")
            }
        }
        
        eventFunctions["ai"] = {(body) in
            if body.starts(with: "TVRoZ") {
                self.addClip(from: Data(base64Encoded: body)!, creator: "ai")
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
        clipsCollection = db.collection("users").document(uid).collection("midi_clips")
        
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
