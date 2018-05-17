//
//  LoginViewController.swift
//  tetris-online
//
//  Created by sean on 5/17/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var accountTextField: UITextField!
    
    @IBAction func touchedLogin(_ sender: UIButton) {
        TSLongConnectionNetworking.sharedInstance.initNetwork()
        let args = ["command":"login",
                    "account":"test",
                    "password":"password"]
        TSShortConnectionNetworking.sharedInstance.get(args: args, success: { (result) in
            print(result)
        }) { (error) in
            print(error)
        }
    }
}
