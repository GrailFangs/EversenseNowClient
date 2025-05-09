import HealthKit


extension HKUnit {
    static let milligramsPerDeciliter: HKUnit = {
        return HKUnit.gramUnit(with: .milli).unitDivided(by: HKUnit.literUnit(with: .deci))
    }()
}
