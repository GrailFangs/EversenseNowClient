import Foundation
import HealthKit
import LoopKit

enum GlucoseLimits {
    static var minimum: UInt16 = 40
    static var maximum: UInt16 = 400
}

extension NowGlucose: GlucoseValue {
    public var startDate: Date {
        return timestamp
    }

    public var quantity: HKQuantity {
        return HKQuantity(unit: .milligramsPerDeciliter, doubleValue: Double(min(max(glucose, GlucoseLimits.minimum), GlucoseLimits.maximum)))
    }
}


extension NowGlucose: GlucoseDisplayable {
    public var isStateValid: Bool {
        return glucose >= 39 && glucose < 400
    }

    public var trendType: GlucoseTrend? {
        return GlucoseTrend(rawValue: Int(trend))
    }

    public var trendRate: HKQuantity? {
        return nil
    }

    public var isLocal: Bool {
        return false
    }
    
    // TODO Placeholder. This functionality will come with LOOP-1311
    public var glucoseRangeCategory: GlucoseRangeCategory? {
        return nil
    }
}

extension NowGlucose {
    public var condition: GlucoseCondition? {
        if glucose < GlucoseLimits.minimum {
            return .belowRange
        } else if glucose > GlucoseLimits.maximum {
            return .aboveRange
        } else {
            return nil
        }
    }
}

extension GlucoseDisplayable {
    public var stateDescription: String {
        if isStateValid {
            return LocalizedString("OK", comment: "Sensor state description for the valid state")
        } else {
            return LocalizedString("Needs Attention", comment: "Sensor state description for the non-valid state")
        }
    }
}
