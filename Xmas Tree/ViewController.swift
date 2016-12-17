//
//  ViewController.swift
//  Xmas Tree
//
//  Created by Kegham Karsian on 12/18/16.
//  Copyright © 2016 appologi. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON
import SwiftGifOrigin
import SystemConfiguration

class ViewController: UIViewController {

    @IBOutlet var treeImageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func treeImageViewTapped(_ sender: UITapGestureRecognizer) {
        print("Tapped")
    }

}

