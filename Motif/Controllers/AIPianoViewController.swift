//
//  PianoViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import PianoView
import MusicTheorySwift
import AudioKit
import WebKit

class AIPianoViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    
    var webView: WKWebView!
    
    @IBOutlet weak var placeholderView: UIView!
    
    let eventNames = ["user", "ai"]
    var eventFunctions : Dictionary<String, (String)->Void> = Dictionary<String, (String)->Void>()
    
    override func loadView() {
        super.loadView()
        let webConfiguration = WKWebViewConfiguration()
        let controller = WKUserContentController()
        webConfiguration.userContentController = controller
        
        for eventname in eventNames {
            controller.add(self, name: eventname)
            eventFunctions[eventname] = {(body) in print(body)}
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
                                window.webkit.messageHandlers.ai.postMessage(base64);
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
    
    override func viewWillAppear(_ animated: Bool) {
        let color1 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.7)
        let color2 = UIColor(red: 0.00, green: 0.27, blue: 0.77, alpha: 0.0)
        //backgroundView.colors = [color1, color2]
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
}
