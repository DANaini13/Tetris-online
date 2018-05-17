//
//  TSShortConnectionNetworking.swift
//  tetris-online
//
//  Created by sean on 5/17/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import UIKit

class TSShortConnectionNetworking: NSObject, TSSocketDelegate {
    
    func connected() {
        
    }
    
    func disconnected(error: Error?) {
        
    }
    
    func gotPacket(content: String) {
        waitingLock.lock()
        waiting = false
        self.packet = content
        waitingLock.unlock()
    }
    
    static let sharedInstance:TSShortConnectionNetworking = {
        let instance = TSShortConnectionNetworking()
        instance.tsSocket.delegate = instance
        return instance
    }()
    
    private let tsSocket: TSScoketService
    private let queue: DispatchQueue
    private let waitingLock: NSRecursiveLock
    private var waiting: Bool
    private var packet: String?
    
    private override init() {
        tsSocket = TSScoketService()
        queue = DispatchQueue(label: "shortConnectionQueue")
        waitingLock = NSRecursiveLock()
        waiting = false
        super.init()
        tsSocket.delegate = self
    }
    
    func get(args: Dictionary<String, Any>, success: (Dictionary<String, Any>) -> Void, failed: (String) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: .prettyPrinted)
            if let jsonObj = String.init(data: jsonData, encoding: .utf8) {
                print(jsonObj)
                queue.async {
                    [weak self] in
                    self?.tsSocket.connect(host: HOST, port: SHORT_CON_PORT);
                    self?.tsSocket.sendPacket(packet: jsonObj)
                    self?.waitingLock.lock()
                    self?.waiting = true
                    self?.waitingLock.unlock()
                    while(self?.waiting)! {
                        usleep(200000)
                    }
                    log.debug(self?.packet)
                    self?.packet = nil
                    self?.tsSocket.closeConnection()
                }
            }
            else {
                failed("unknow error!")
            }
        } catch {
            failed(error.localizedDescription)
            return
        }
    }
}
