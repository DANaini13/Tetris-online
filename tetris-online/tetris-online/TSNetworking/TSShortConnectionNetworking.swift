//
//  TSShortConnectionNetworking.swift
//  tetris-online
//
//  Created by sean on 5/17/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import UIKit
import AFNetworking

class TSShortConnectionNetworking: NSObject {
    class func get(url: String, paras: Dictionary<String, String>?,
                   success: @escaping (Dictionary<String, Any?>?) -> Void,
                   failture:@escaping (String) -> Void){
        let manager = AFHTTPSessionManager()
        manager.responseSerializer = AFJSONResponseSerializer()
        manager.requestSerializer = AFJSONRequestSerializer()
        let _ = manager.get(url, parameters: paras, progress: nil, success: {
            (operation: URLSessionTask, resopnseObj: Any?) in
            if let value = resopnseObj! as? Dictionary<String, Any> {
                log.debug("JSON: " + "\(value)")
                success(value)
            }else{
            }
        }, failure:{
            (operation: URLSessionDataTask?, error: Error) in
            print(error.localizedDescription)
            failture(error.localizedDescription)
        })
    }}
