//
//  ViewController.swift
//  SwiftHRM
//
//  Created by Tim Fenton on 1/13/15.
//  Copyright (c) 2015 Tim Fenton. All rights reserved.
//
//  Based on objective C code from here:
//      http://www.raywenderlich.com/52080/introduction-core-bluetooth-building-heart-rate-monitor
//

import UIKit

let heartBeatKey = "heartBeat:"

class ViewController: UIViewController {

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.btle = BTLE()
    }

    @IBOutlet var hrmLabel : UILabel!
    @IBOutlet var rssiLabel : UILabel!
    
    var btle: BTLE!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "heartBeatNotification:", name: heartBeatKey, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // called when there's a notification from the model
    func heartBeatNotification(notification: NSNotification){
        let userInfo:Dictionary<String,String!> = notification.userInfo as Dictionary<String,String!>
        let messageString = userInfo["heartRate"]
        let rssiString = userInfo["RSSI"]
        hrmLabel.text = messageString
        rssiLabel.text = rssiString
    }
    
}

