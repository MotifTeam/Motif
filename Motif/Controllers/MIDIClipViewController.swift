//
//  MIDIClipViewController.swift
//  Motif
//
//  Created by Michael Asper on 4/6/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import AudioKit
import Firebase
/*
class MIDIClipViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var midiPlayer: AVMIDIPlayer?
    var clipPlaying: MIDIClip?
    
    var clips: [MIDIClip] = []
    
    var db: Firestore!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.estimatedRowHeight = 70.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
        
        let uid = Auth.auth().currentUser?.uid ?? "0"
        db.collection("users").document(uid).collection("clips").order(by: "time").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    self.clips.append(MIDIClip(midiData: document["midiData"] as! Data, creator: document["creator"] as! String, timestamp: document["time"] as! Date, documentRef: document.reference))
                }
                self.tableView.reloadData()
            }
        }
        tableView.reloadData()
    }
}


extension MIDIClipViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "midiCell", for: indexPath) as! MIDIClipViewCell
        let row = indexPath.row
        cell.parentVC = self
        cell.populate(clips[row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { (rowAction: UITableViewRowAction, indexPath: IndexPath) -> Void in
            let row = indexPath.row
            let clipToDelete = self.clips[row]
            clipToDelete.documentRef.delete () { (err: Error?) in
                
            }
            print("deleted row \(row)")
            self.clips.remove(at: row)
            self.tableView.deleteRows(at: [indexPath], with: .fade)
            
            self.tableView.reloadData()
        }
        return [deleteAction]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clips.count
    }
}*/
