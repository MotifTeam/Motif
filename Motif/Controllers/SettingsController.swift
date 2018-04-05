//
//  SettingsController.swift
//  Motif
//
//  Created by Michael Asper on 4/4/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit

class SettingsController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.tableFooterView = UIView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 2
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
    }

    @IBAction func exitView() {
        print("triggerd")
        guard let vc = UIStoryboard(name: "ClipLibrary",
                                    bundle: nil)
            .instantiateViewController(withIdentifier: "ClipLibrary") as? ClipLibraryViewController else {
                return
        }
        self.present(vc, animated: true, completion: nil)
    }
}
