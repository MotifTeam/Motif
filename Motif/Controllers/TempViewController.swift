//
//  TempViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import Firebase
import AudioKit

class TempViewController: UIViewController {

    @IBOutlet weak var switchTable: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!
    
    var songList = [Song]()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent // .default
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        Auth.auth().addStateDidChangeListener { auth, user in
            if user != nil {
                print("user is logged in")
            } else {
                guard let vc = UIStoryboard(name: "Login",
                                            bundle: nil)
                    .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                        return
                }
                self.present(vc, animated: true, completion: nil)
            }
        }
        
        
        
        switchTable.tintColor = .white
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.estimatedRowHeight = 85.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        tableView.separatorInset = UIEdgeInsets.zero
    }
    
    @IBAction func unwindToTemp(segue: UIStoryboardSegue) {
    }
    
    @IBAction func logout() {
        try! Auth.auth().signOut()
        
        guard let vc = UIStoryboard(name: "Login",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: "loginSplash") as? LoginSplashViewController else {
                return
        }
        self.present(vc, animated: true, completion: nil)
        
    }
    
    func play() {
        print("Play button was pressed")
        //let path = Bundle.main.path(forResource: clipName.text, ofType: "wav")
        //let url = NSURL.fileURL(withPath: path!)
        
        // var akFile: AKAudioFile
        do {
            let akFile = try AKAudioFile(readFileName: "rain-03.wav", baseDir: .resources)
            print("File created")
            print("File.sampleRate: \(akFile.duration)")
            
            let player = try AKAudioPlayer(file: akFile) {
                print("completion callback has been triggered!")
            }
            //TempViewController.player = player
            //clipLibaryViewController.updateSlider()
            AudioKit.output = player
            try AudioKit.start()
            player.play()
            
        } catch let error as NSError {
            print("There's an error: \(error)")
        }
    }
}

extension TempViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count+1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath as IndexPath)
        cell.separatorInset = UIEdgeInsets.zero
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75.0
        
    }
    
}
