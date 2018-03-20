//
//  SignUpViewController.swift
//  Motif
//
//  Created by Michael Asper on 2/23/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import TransitionButton
import UIKit
import Firebase

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var registerButton: TransitionButton!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    let gradientLayer: CAGradientLayer = {
        let color1 = UIColor(red: 0.21,
                             green: 0.82,
                             blue: 0.86,
                             alpha: 1.0)
        let color2 = UIColor(red: 0.36,
                             green: 0.53,
                             blue: 0.90,
                             alpha: 1.0)
        let layer = CAGradientLayer()
        layer.colors = [color1.cgColor, color2.cgColor]
        layer.locations = [0, 1]
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 1)
        return layer
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gradientLayer.frame = view.frame
        view.layer.insertSublayer(gradientLayer, at: 0)
        registerButton.layer.cornerRadius = 5
        registerButton.layer.masksToBounds = true
        registerButton.layer.borderColor = UIColor.white.cgColor
        registerButton.layer.borderWidth = 2
        nameField.layer.cornerRadius = 0
       
    }
    @IBAction func registerAction(_ sender: TransitionButton) {
        guard let name = nameField.text,
            let password = passwordField.text,
            let email = emailField.text else {
            abort()
        }
        
        print(name)
        
        registerButton.startAnimation() // 2: Then start the animation when the user tap the button
        let qualityOfServiceClass = DispatchQoS.QoSClass.background
        let backgroundQueue = DispatchQueue.global(qos: qualityOfServiceClass)
        backgroundQueue.async(execute: {
            
            
            Auth.auth().createUser(withEmail: email, password: password) { (user,error) in
                
                if error != nil {
                    print(error!)
                    abort()
                }
                
                
                DispatchQueue.main.async(execute: { () -> Void in
                    // 4: Stop the animation, here you have three options for the `animationStyle` property:
                    // .expand: useful when the task has been compeletd successfully and you want to expand the button and transit to another view controller in the completion callback
                    // .shake: when you want to reflect to the user that the task did not complete successfly
                    // .normal
                    self.registerButton.stopAnimation()
                })
            }
        })
    }
}
