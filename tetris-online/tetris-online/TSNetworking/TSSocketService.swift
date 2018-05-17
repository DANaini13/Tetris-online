//
//  TSSocketService.swift
//  tetris-online
//
//  Created by sean on 5/12/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

protocol TSSocketDelegate: class {
    func connected()
    func disconnected(error: Error?)
    func gotPacket(content: String)
}

class TSScoketService: NSObject, GCDAsyncSocketDelegate {
    
    static let sharedInstance: TSScoketService = {
        let instance = TSScoketService()
        instance.asSocket = GCDAsyncSocket.init(delegate: instance, delegateQueue: DispatchQueue.main)
        return instance
    }()
    
    weak var delegate: TSSocketDelegate?
    private var data: Data = Data()
    
    func sendPacket(packet: String) -> Bool {
        guard (self.asSocket?.isConnected)! else {
            return false
        }
 //       self.asSocket?.write(packet.javaUTF8()!, withTimeout: 2, tag: 1)
        return true
    }
    
    private override init() {
        super.init()
    }
    
    func connect() {
        do {
            try asSocket!.connect(toHost: host, onPort: port, withTimeout: 10)
        }catch let error{
            print(error)
        }
    }
    
    private var asSocket: GCDAsyncSocket? = nil
    
    internal func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.delegate?.connected()
        self.asSocket?.readData(withTimeout: -1, tag: 0)
    }
    
    internal func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        self.delegate?.disconnected(error: err)
    }
    
    internal func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        self.delegate?.gotPacket(content: String.init(data: data, encoding: .utf8)!)
        self.asSocket?.readData(withTimeout: -1, tag: 0)
    }
    
}

extension String {
    func javaUTF8() -> Data? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        let length = self.lengthOfBytes(using: .utf8)
        var buffer = [UInt8]()
        buffer.append(UInt8(0xff & (length >> 8)))
        buffer.append(UInt8(0xff & length))
        var outdata = Data()
        outdata.append(buffer, count: buffer.count)
        outdata.append(data)
        return outdata
    }
}
