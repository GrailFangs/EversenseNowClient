//
//  NowClientPlugin.swift
//  NowClientPlugin
//
//  Created by Nathaniel Hamming on 2019-12-19.
//  Copyright © 2019 Mark Wilson. All rights reserved.
//

import os.log
import LoopKitUI
import NowClient
import NowClientUI

class NowClientPlugin: NSObject, CGMManagerUIPlugin {
    private let log = OSLog(category: "NowClientPlugin")
    
    public var cgmManagerType: CGMManagerUI.Type? {
        return NowClientManager.self
    }
    
    override init() {
        super.init()
        log.default("Instantiated")
    }
}
