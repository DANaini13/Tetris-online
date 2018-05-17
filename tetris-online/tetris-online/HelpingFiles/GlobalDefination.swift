//
//  globalDefination.swift
//  tetris-online
//
//  Created by sean on 5/12/18.
//  Copyright © 2018 nasoftware. All rights reserved.
//

import Foundation
import XCGLogger

let CACHE_FILE_PATH = FileManager.default.urls(for: .cachesDirectory,
                                         in: .userDomainMask)[0]
let LOG_URL = CACHE_FILE_PATH.appendingPathComponent("log.txt")
let log = XCGLogger.default

let HOST = "localhost"
let LONG_CON_PORT : UInt16 = 2022
let SHORT_CON_PORT : UInt16 = 2023
