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
        guard let json = content.parseJSONString else {
            return
        }
        guard let type = json["type"] as? String else {
            return
        }
        switch type {
        case "CGI":
            guard let requestStr = json["requestID"] as? String else {
                return
            }
            guard let requestID = Int(requestStr) else {
                return
            }
            requestBufferLock.lock()
            requestBuffer[requestID] = json
            requestBufferLock.unlock()
            idBufferLock.lock()
            idBuffer.append(requestID)
            idBufferLock.unlock()
        case "SYNC":
            guard let command = json["command"] as? String else {
                return
            }
            syncBufferLock.lock()
            syncBuffer[command] = json
            syncBufferLock.unlock()
        default:
            return
        }
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
    private var syncBuffer: [String: Dictionary<String, Any>] = [:]
    private var syncBufferLock: NSRecursiveLock = NSRecursiveLock()
    private var syncHandlerBuffer: [Int: (String, (Dictionary<String, Any>) -> Void)] = [:]
    private var syncHandlerLock: NSRecursiveLock = NSRecursiveLock()
    private var checkTimer: Timer? = nil
    
    private var requestBuffer: [Int: Dictionary<String, Any>] = [:]
    private var requestBufferLock: NSRecursiveLock = NSRecursiveLock()
    private var timerBuffer: [Int: Timer] = [:]
    private var idBuffer: [Int] = []
    private var idBufferLock: NSRecursiveLock = NSRecursiveLock()
    private var maxId = 0
    private func getRequestId() -> Int {
        idBufferLock.lock()
        if idBuffer.count > 0 {
            let result = idBuffer.removeFirst()
            idBufferLock.unlock()
            return result
        }else {
            maxId += 1
            idBufferLock.unlock()
            return maxId - 1
        }
    }
    
    private func checkBuffer(withID id: Int ) -> Dictionary<String, Any>? {
        requestBufferLock.lock()
        if let result = requestBuffer[id] {
            let buffer = result
            requestBuffer.removeValue(forKey: id)
            requestBufferLock.unlock()
            return buffer
        } else {
            requestBufferLock.unlock()
            return nil
        }
    }
    
    private func startSyncChecker() {
        self.checkTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) {
            [weak self] (_) in
            if (self?.syncHandlerBuffer.count)! <= 0 {
                self?.checkTimer?.invalidate()
            }
            for packet in (self?.syncBuffer)! {
                for handler in (self?.syncHandlerBuffer)! {
                    if packet.key == handler.value.0 {
                        handler.value.1(packet.value)
                        self?.syncBuffer.removeValue(forKey: packet.key)
                    }
                }
            }
        }
    }
    
    private func stopTimer(withID id: Int) {
        timerBuffer[id]?.invalidate()
        timerBuffer.removeValue(forKey: id)
    }
    
    func CGIRequest(args: Dictionary<String, Any?>, response:@escaping (Dictionary<String, Any>) -> Void) {
        guard status == .connected else {
            let res = ["error" : "server unreachable!"]
            response(res)
            return
        }
        do {
            let requestId = getRequestId()
            var request = args
            request["requestID"] = requestId
            request["requestType"] = "CGI"
            let jsonData = try JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
            if let jsonObj = String.init(data: jsonData, encoding: .utf8) {
                tsSocket.sendPacket(packet: jsonObj)
            }
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
    
    func PUSHRequest(args: Dictionary<String, Any?>, response:@escaping (Dictionary<String, Any>) -> Void) {
        guard status == .connected else {
            let error = ["error": "server unreachable!"]
            response(error)
            return
        }
        do {
            var request = args
            request["requestType"] = "PUSH"
            let jsonData = try JSONSerialization.data(withJSONObject: request, options: .prettyPrinted)
            if let jsonObj = String.init(data: jsonData, encoding: .utf8) {
                tsSocket.sendPacket(packet: jsonObj)
            }
        }catch {
            let error = ["error": error.localizedDescription]
            response(error)
        }
    }
    
    func registerSyncHandler(command: String, response:@escaping (Dictionary<String, Any>) -> Void) -> Int {
        syncHandlerLock.lock()
        let requestId = getRequestId()
        syncHandlerBuffer[requestId] = (command, response)
        syncHandlerLock.unlock()
        if syncHandlerBuffer.count <= 1 {
            startSyncChecker()
        }
        return requestId
    }
    
    func unregisterSyncHandler(handlerID: Int) {
        syncHandlerLock.lock()
        syncHandlerBuffer.removeValue(forKey: handlerID)
        syncHandlerLock.unlock()
        idBufferLock.lock()
        idBuffer.append(handlerID)
        idBufferLock.unlock()
    }
}
