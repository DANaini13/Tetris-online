//
//  LoginViewController.swift
//  tetris-online
//
//  Created by sean on 5/17/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        TSLongConnectionNetworking.sharedInstance.initNetwork()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private var idList:[Int] = []

    @IBAction func touchedRegister(_ sender: UIButton) {
        let id = TSLongConnectionNetworking.sharedInstance.registerSyncHandler(command: "test") { (response) in
            log.debug(response)
        }
        self.idList.append(id)
    }
    
    
    @IBAction func touchedUnregister(_ sender: UIButton) {
        guard idList.count > 0 else {
            return
        }
        TSLongConnectionNetworking.sharedInstance.unregisterSyncHandler(handlerID: idList.removeLast())
    }
}
