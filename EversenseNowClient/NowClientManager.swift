//
//  NowClientManager.swift
//  Loop
//
//  Copyright © 2018 LoopKit Authors. All rights reserved.
//

import LoopKit
import HealthKit


public class NowClientManager: CGMManager {

    public static let pluginIdentifier = "NowClient"

    public init() {
        nowService = NowService(keychainManager: keychain)
    }

    required convenience public init?(rawState: CGMManager.RawStateValue) {
        self.init()
    }

    public var rawState: CGMManager.RawStateValue {
        return [:]
    }

    public let isOnboarded = true   // No distinction between created and onboarded

    private let keychain = KeychainManager()

    public var nowService: NowService {
        didSet {
            try! keychain.setEversenseNowCredentials(username: nowService.username, password: nowService.password)
        }
    }

    public let localizedTitle = LocalizedString("Eversense Now", comment: "Title for the CGMManager option")

    public let appURL: URL? = nil

    public var cgmManagerDelegate: CGMManagerDelegate? {
        get {
            return delegate.delegate
        }
        set {
            delegate.delegate = newValue
        }
    }

    public var delegateQueue: DispatchQueue! {
        get {
            return delegate.queue
        }
        set {
            delegate.queue = newValue
        }
    }

    public let delegate = WeakSynchronizedDelegate<CGMManagerDelegate>()

    public let providesBLEHeartbeat = false

    public let shouldSyncToRemoteService = false

    public var glucoseDisplay: GlucoseDisplayable? {
        return latestBackfill
    }
    
    public var cgmManagerStatus: CGMManagerStatus {
        return CGMManagerStatus(hasValidSensorSession: hasValidSensorSession, device: device)
    }

    public var hasValidSensorSession: Bool {
        return nowService.isAuthorized
    }

    public let managedDataInterval: TimeInterval? = nil

    public private(set) var latestBackfill: NowGlucose?

    public func fetchNewDataIfNeeded(_ completion: @escaping (CGMReadingResult) -> Void) {
        guard let nowClient = nowService.client else {
            completion(.noData)
            return
        }

        // If our last glucose was less than 4.5 minutes ago, don't fetch.
        if let latestGlucose = latestBackfill, latestGlucose.startDate.timeIntervalSinceNow > -TimeInterval(minutes: 4.5) {
            completion(.noData)
            return
        }

        nowClient.fetchLast { (error, patientData) in
            if let error = error {
                completion(.error(error))
                return
            }
            guard let patientData = patientData else {
                completion(.noData)
                return
            }
            
            let startDate = self.delegate.call { (delegate) -> Date? in
                return delegate?.startDateToFilterNewData(for: self)?.addingTimeInterval(TimeInterval(minutes: 1))
            } 

            let newGlucose = [patientData].filterDateRange(startDate, nil)

            let newSamples = newGlucose.filter({ $0.isStateValid }).map {
                return NewGlucoseSample(date: $0.startDate, quantity: $0.quantity, condition: $0.condition, trend: $0.trendType, trendRate: $0.trendRate, isDisplayOnly: false, wasUserEntered: false, syncIdentifier: "\(Int($0.startDate.timeIntervalSince1970))", device: self.device)
            }

            self.latestBackfill = newGlucose.first

            if newSamples.count > 0 {
                completion(.newData(newSamples))
            } else {
                completion(.noData)
            }
        }
    }

    public var device: HKDevice? = nil

    public var debugDescription: String {
        return [
            "## NowClientManager",
            "latestBackfill: \(String(describing: latestBackfill))",
            ""
        ].joined(separator: "\n")
    }
}

// MARK: - AlertResponder implementation
extension NowClientManager {
    public func acknowledgeAlert(alertIdentifier: Alert.AlertIdentifier, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}

// MARK: - AlertSoundVendor implementation
extension NowClientManager {
    public func getSoundBaseURL() -> URL? { return nil }
    public func getSounds() -> [Alert.Sound] { return [] }
}
