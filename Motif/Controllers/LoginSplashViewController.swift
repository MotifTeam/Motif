//
//  LoginSplashViewController.swift
//  Motif
//
//  Created by Michael Asper on 2/21/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit

class LoginSplashViewController: UIViewController {
    
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
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
        signUpButton.layer.cornerRadius = 5
        signUpButton.layer.masksToBounds = true
        signUpButton.layer.borderColor = UIColor.white.cgColor
        signUpButton.layer.borderWidth = 2
        loginButton.layer.cornerRadius = 5
        loginButton.layer.masksToBounds = true
        loginButton.layer.borderColor = UIColor.white.cgColor
        loginButton.layer.borderWidth = 2
    }


}
