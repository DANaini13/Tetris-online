//
//  TSNetworking.swift
//  tetris-online
//
//  Created by sean on 5/12/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import Foundation

class TSLongConnectionNetworking: NSObject, TSSocketDelegate {
    
    enum NetworkStatus {
        case notInitialized
        case connected
        case disconnected
        case connecting
        case reconnecting
    }
    
    static let sharedInstance:TSLongConnectionNetworking = {
        let instance = TSLongConnectionNetworking()
        instance.tsSocket.delegate = instance
        return instance
    }()
    
    var networkStatus:NetworkStatus {
        return status
    }
    
    func initNetwork() {
        guard status == .notInitialized else {
            return
        }
        self.tsSocket.connect(host: HOST, port: LONG_CON_PORT)
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
        
    }
    
    private override init() {
        tsSocket = TSScoketService()
        statusLock = NSRecursiveLock()
        statusLock.lock()
        status = .notInitialized
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
            self?.tsSocket.connect(host: HOST, port: LONG_CON_PORT)
            self?.reconnectionCount += 1
            log.debug("=====trying to reconnecting=====")
        })
    }
    
    
    //=============================================
    private var syncBuffer: [String: Dictionary<String, Any?>] = [:]
    private var requestBuffer: [Int: Dictionary<String, Any?>] = [:]
    private var timerBuffer: [Int: Timer] = [:]
    private var idBuffer: [Int] = []
    private var maxId = 0
    
    private func getRequestId() -> Int {
        if idBuffer.count > 0 {
            return idBuffer.removeFirst()
        }else {
            maxId += 1
            return maxId - 1
        }
    }
    
    private func checkBuffer(withID id: Int ) -> Dictionary<String, Any?>? {
        if let result = requestBuffer[id] {
            let buffer = result
            requestBuffer.removeValue(forKey: id)
            return buffer
        } else {
            return nil
        }
    }
    
    private func stopTimer(withID id: Int) {
        timerBuffer[id]?.invalidate()
        timerBuffer.removeValue(forKey: id)
    }
    
    func CGIRequest(args: Dictionary<String, Any?>, response:@escaping (Dictionary<String, Any?>) -> Void) {
        guard status == .connected else {
            let res = ["error" : "server unreachable!"]
            response(res)
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: .prettyPrinted)
            if let jsonObj = String.init(data: jsonData, encoding: .utf8) {
                tsSocket.sendPacket(packet: jsonObj)
            }
            let requestId = getRequestId()
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) {
                [weak self] (_) in
                if let packet = self?.checkBuffer(withID: requestId) {
                    self?.stopTimer(withID: requestId)
                    response(packet)
                }
            }
            timerBuffer[requestId] = timer
        }catch {
            let error = ["error": error.localizedDescription]
            response(error)
        }
    }
    
    func PUSHRequest(args: Dictionary<String, Any?>, response:@escaping (Dictionary<String, Any?>) -> Void) {
        guard status == .connected else {
            let error = ["error": "server unreachable!"]
            response(error)
            return
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: args, options: .prettyPrinted)
            if let jsonObj = String.init(data: jsonData, encoding: .utf8) {
                tsSocket.sendPacket(packet: jsonObj)
            }
        }catch {
            let error = ["error": error.localizedDescription]
            response(error)
        }
    }
}
