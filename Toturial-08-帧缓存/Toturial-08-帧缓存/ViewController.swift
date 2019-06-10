//
//  ViewController.swift
//  Toturial-08-帧缓存
//
//  Created by mkil on 2019/6/9.
//  Copyright © 2019 mkil. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var myView:UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        myView = AGLKView()
        myView?.frame = self.view.bounds
        self.view.addSubview(myView!)
    }
}

