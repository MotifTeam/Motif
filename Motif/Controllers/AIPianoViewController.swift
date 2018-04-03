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
//import AudioKit
import WebKit
import AVFoundation

struct MIDIClip {
    let midiData: Data
    let creator: String
    let timestamp: Date
}


class AIPianoViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    
    var webView: WKWebView!
    
    @IBOutlet weak var placeholderView: UIView!
    var midiPlayer: AVMIDIPlayer?
    
    let eventNames = ["user", "ai"]
    var eventFunctions : Dictionary<String, (String)->Void> = Dictionary<String, (String)->Void>()
    
    var sessionClips: [MIDIClip] = []
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        webConfiguration.userContentController = controller
        
        eventFunctions["user"] = {(body) in
            if body.starts(with: "[77,84,") {
                let bytes = body.dropFirst().dropLast().split(separator: ",").map {UInt8($0)!}
                let clip = MIDIClip(midiData: Data(bytes:bytes), creator: "user", timestamp: Date())
                self.sessionClips.append(clip)
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
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
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
