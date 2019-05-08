//
//  ViewController.swift
//  Tutorial-05-多重纹理
//
//  Created by mkil on 2019/5/6.
//  Copyright © 2019 黎宁康. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var myView:UIView?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        myView = AGLKView()
        myView?.frame = self.view.bounds
        self.view.addSubview(myView!)
    }


}

