//
//  LoginViewController.swift
//  Motif
//
//  Created by Michael Asper on 2/23/18.
//  Copyright © 2018 Motif. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

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
    }

}
