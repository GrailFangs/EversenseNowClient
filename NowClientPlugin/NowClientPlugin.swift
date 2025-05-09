import os.log
import LoopKitUI
import EversenseNowClient
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
