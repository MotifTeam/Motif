//
//  TempViewController.swift
//  Motif
//
//  Created by Michael Asper on 3/20/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit
import Firebase

class TempViewController: UIViewController {

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

    }

}
