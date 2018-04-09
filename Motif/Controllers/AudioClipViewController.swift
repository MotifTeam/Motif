//
//  AudioClipViewController.swift
//  Motif
//
//  Created by Michael Asper on 4/6/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import CoreData

class AudioClipViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let cellNib = UINib(nibName: "ClipTableViewCell", bundle: nil)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTable()
    }
    
    private func setUpTable() {
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(cellNib, forCellReuseIdentifier: "clipCell")
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.reloadData()
    }
    
    func retrieveAudioClips() -> [NSManagedObject] {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName:"Song")
        var fetchedResults:[NSManagedObject]? = nil
        
        // Examples of filtering using predicates
        // let predicate = NSPredicate(format: "age = 35")
        // let predicate = NSPredicate(format: "name CONTAINS[c] 'ake'")
        // request.predicate = predicate
        
        do {
            try fetchedResults = context.fetch(request) as? [NSManagedObject]
        } catch {
            // If an error occurs
            let nserror = error as NSError
            NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
            abort()
        }
        return(fetchedResults)!
    }
}

extension AudioClipViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let note_list = retrieveAudioClips()
        return note_list.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "clipCell", for: indexPath as IndexPath) as! ClipTableViewCell
        
        cell.preservesSuperviewLayoutMargins = false
        cell.separatorInset = UIEdgeInsets.zero
        cell.layoutMargins = UIEdgeInsets.zero
        
        let row = indexPath.row
        
        let fetched_results = retrieveAudioClips()
        let curr_clip = fetched_results[row]
        
        if let clip_name = curr_clip.value(forKey:"name") {
            cell.clipName?.text = String(describing:clip_name)
        }
        if let clip_url = curr_clip.value(forKey:"url") {
            cell.url = clip_url as! URL
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }
    
}

