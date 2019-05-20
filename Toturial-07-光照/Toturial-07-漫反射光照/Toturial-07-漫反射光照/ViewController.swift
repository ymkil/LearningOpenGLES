//
//  ViewController.swift
//  Toturial-07-漫反射光照
//
//  Created by mkil on 2019/5/16.
//  Copyright © 2019 黎宁康. All rights reserved.
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

