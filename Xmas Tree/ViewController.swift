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

protocol Utilities {
    
}

class ViewController: UIViewController {
    
    var treeFrames = [UIImage]()
    var key: String!
    
    let mode = (0,1)  //0 is input   1 is output
    let pin = 7 // pin number on arduino board
    let toggle = (0,1,2) //0 is off   1 is on   2 is toggleing
    
    var setDigitalURL: URL!
    var getDigitalURL: URL!
    var definePinModeURL: URL!
    var getInputURL: URL!

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var indicator: UILabel!
    @IBOutlet var treeImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeActive), name: NSNotification.Name.UIApplicationDidBecomeActive, object: nil)
        
        activityIndicator.hidesWhenStopped = true
        activityIndicator.center = view.center
        //activityIndicator.layer.cornerRadius = 5
        initialize()

        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func treeImageViewTapped(_ sender: UITapGestureRecognizer) {
        
        callTelduino(pin: pin, toggle: toggle.2, key: key, method: .post)

    }
    
    //Observer function fires when app loads
    func didBecomeActive() {
        
        //Check if phone has internet connection and is not on flight mode.
        if currentReachabilityStatus == ReachabilityStatus.notReachable {
            alertMessage(title: "Connection Error", message: "No connection found. Please check your phone connection status.")

            return
            
        } else {
            
            activityIndicator.startAnimating()
            
            getInputValue(key: key, method: .post) { (status, newValue, msg) in
                
                if status == 200 {
                    
                    //Change button colors according to value
                    if newValue == 0 {
                        self.treeImageView.stopAnimating()
                        self.indicator.text = "Off"
                    } else {
                        self.treeImageView.startAnimating()
                        self.indicator.text = "On"
                    }
                    
                } else {
                    
                    print("Error getting pin values")
                    
                    self.alertMessage(title: "Connection Error", message: "Failed retrieving pin values")
                    return
                }
                self.activityIndicator.stopAnimating()
            }
        }
        
    }
    
    func callTelduino(pin:Int, toggle:Int, key:String, method:HTTPMethod) {
        
        activityIndicator.startAnimating()
        setDigitalURL = URL(string: "https://us01.proxy.teleduino.org/api/1.0/328.php?k=\(key)&r=setDigitalOutput&pin=\(pin)&output=\(toggle)&expire_time=0&save=1")
        
        Alamofire.request(setDigitalURL, method: method, parameters: [:], encoding: JSONEncoding.default, headers: [:])
            .validate(statusCode: 200..<300)
            .responseJSON(completionHandler: { (response) in
                switch response.result{
                case .success( _):
                    //   print("Success \(data)")
                    self.activityIndicator.stopAnimating()
                    
                    if self.treeImageView.isAnimating {
                        self.treeImageView.stopAnimating()
                        self.indicator.text = "Off"
                    } else {
                        self.treeImageView.startAnimating()
                        self.indicator.text = "On"
                    }
                    
                case .failure(let err):
                    print("Error: \(err)")
                    self.alertMessage(title: "Connection Error", message: "Failed in sending request")
                }
                
            })
        
    }
    
    func getInputValue(key:String, method:HTTPMethod, completion:@escaping (_ status:Int, _ values:Int?, _ msg:String?)->())  {
        
        var theValue = Int()
        
        getInputURL = URL(string:"https://us01.proxy.teleduino.org/api/1.0/328.php?k=\(key)&r=getDigitalInput&pin=\(pin)")
        
        Alamofire.request(getInputURL, method: method, parameters: [:], encoding: JSONEncoding.default, headers: [:])
            .validate(statusCode: 200..<300)
            .responseJSON(completionHandler: { (response) in
                switch response.result{
                case .success(let data):
                    //print("Success \(data)")
                    // print(data)
                    let json = JSON(data)
                    for (_ ,subJson):(String, JSON) in json {
                        //    print(subJson)
                        for value in subJson["values"].arrayValue {
                              //print(value)
                            theValue = value.int!
                        }
                    }
                    completion(200, theValue, "OK")
                case .failure(let err):
                    print("Error: \(err)")
                    completion(500, nil, "Failed")
                    
                }
            })
        
    }

    
    // Defining which pins are for output and which for input
    func definingPinModes(pin: Int, mode: Int) {
        
        
        definePinModeURL = URL(string: "https://us01.proxy.teleduino.org/api/1.0/328.php?k=\(key!)&r=definePinMode&pin=\(pin)&mode=\(mode)")
        
        Alamofire.request(definePinModeURL, method: .post, parameters: [:], encoding: JSONEncoding.default, headers: [:])
            .validate(statusCode: 200..<300)
            .responseJSON { (response) in
                switch response.result {
                case .success(_):
                    print("Success pin definition")
                    
                case .failure(let err):
                    // SwiftSpinner.show(duration: 2.0, title: "Connection Error")
                    print("Error initialization: \(err)")
                  
                    // self.alertMessage(title: "Connection Error", message: "Failed to initialize app")
                    
                    return
                }
                
        }
        
    }

    
    func initialize() {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        key = appDelegate.key
        
        let treeGif = UIImage.gif(name: "christmasTreeGIF")
        
        treeImageView.animationImages = treeGif?.images
//        for i in 0...100 {
//            
//            treeFrames.append(UIImage(named: "christmasTreeGIF-\(i)")!)
//        }
        treeImageView.image = UIImage(named: "christmasTreeJPG")
        //treeImageView.startAnimating()
        treeImageView.animationDuration = (treeGif?.duration)!
        
        definingPinModes(pin: pin, mode: mode.1)
    }
    
    
    //Alert error messages
    func alertMessage(title:String, message:String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .default) { (action) in
            alert.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(action)
        
        self.activityIndicator.stopAnimating()
        
        if presentedViewController == nil {
            self.present(alert, animated: true, completion: nil)
        }else {
            self.dismiss(animated: false, completion: {
                self.present(alert, animated: true, completion: nil)
            })
        }
    }
    
    
    

}

// Checking reachability status using SCNetworkReachabilityFlags
extension NSObject:Utilities {
    
    enum ReachabilityStatus {
        case notReachable
        case reachableViaWWAN
        case reachableViaWiFi
    }
    
    var currentReachabilityStatus: ReachabilityStatus {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return .notReachable
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return .notReachable
        }
        
        if flags.contains(.reachable) == false {
            // The target host is not reachable.
            return .notReachable
        }
        else if flags.contains(.isWWAN) == true {
            // WWAN connections are OK if the calling application is using the CFNetwork APIs.
            return .reachableViaWWAN
        }
        else if flags.contains(.connectionRequired) == false {
            // If the target host is reachable and no connection is required then we'll assume that you're on Wi-Fi...
            return .reachableViaWiFi
        }
        else if (flags.contains(.connectionOnDemand) == true || flags.contains(.connectionOnTraffic) == true) && flags.contains(.interventionRequired) == false {
            // The connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs and no [user] intervention is needed
            return .reachableViaWiFi
        }
        else {
            return .notReachable
        }
    }
    
}


