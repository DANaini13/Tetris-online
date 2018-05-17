//
//  TSNetworking.swift
//  tetris-online
//
//  Created by sean on 5/12/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import Foundation

class TSNetworking: NSObject, TSSocketDelegate {
    
    enum NetworkStatus {
        case connected
        case disconnected
        case connecting
        case reconnecting
    }
    
    static let sharedInstance:TSNetworking = {
        let instance = TSNetworking()
        instance.tsSocket.delegate = instance
        return instance
    }()
    
    var networkStatus:NetworkStatus {
        return status
    }
    
    func initNetwork() {
        self.tsSocket.connect()
        statusLock.lock()
        status = .connecting
        statusLock.unlock()
        log.debug("=====trying to connect with server=====")
    }
    
    internal func connected() {
        statusLock.lock()
        status = .connected
        statusLock.unlock()
        timer?.invalidate()
        timer = nil
        log.debug("=====long connection built=====")
    }
    
    internal func disconnected(error: Error?) {
        if timer == nil{
            statusLock.lock()
            status = .disconnected
            statusLock.unlock()
            log.debug("=====disconnected=====")
            reconnect()
        } else {
            statusLock.lock()
            status = .reconnecting
            statusLock.unlock()
        }
    }
    
    internal func gotPacket(content: String) {
        log.debug(content)
    }
    
    private override init() {
        tsSocket = TSScoketService.sharedInstance
        statusLock = NSRecursiveLock()
        statusLock.lock()
        status = .disconnected
        statusLock.unlock()
        reconnectionCount = 0
        super.init()
    }
    
    private var status: NetworkStatus
    private var statusLock: NSRecursiveLock
    private var tsSocket: TSScoketService
    private var timer: Timer?
    private var reconnectionCount: Int
    
    private func reconnect() {
        statusLock.lock()
        status = .reconnecting
        statusLock.unlock()
        reconnectionCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: {
            [weak self] (_) in
            self?.tsSocket.connect()
            self?.reconnectionCount += 1
            log.debug("=====trying to reconnecting=====")
        })
    }
}
