//
//  MIDIClipTableViewController.swift
//  Motif
//
//  Created by Andrew Martin on 4/3/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit

class MIDIClipTableViewCell: UITableViewCell {
    
}

class MIDIClipTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var clips: [MIDIClip] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "midiClipCell", for: indexPath)
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return clips.count
    }
    
    
    
}
