import Foundation
public struct PatientDatum: Codable {
    let userID: Int? = 0
    let followerID: String? = ""
    let followerCode: String? = ""
    let followerEmail: String? = ""
    let referenceName: String? = ""
    let removedDate: String? = ""
    let invitationDate: String? = ""
    let acceptedDate: String? = ""
    let otherInfo: String? = ""
    let followerUserID: Int? = 0
    let status: Int? = 0
    let userName: String? = ""
    let firstName: String? = ""
    let lastName: String? = ""
    let profileImage: String? = ""
    let currentGlucose, glucoseTrend: Int
    let cgTime: String
    let units: Int
    let isTransmitterConnected: Bool
    let txConnectionStatusTimestamp: String? = ""

    enum CodingKeys: String, CodingKey {
        case currentGlucose = "CurrentGlucose"
        case glucoseTrend = "GlucoseTrend"
        case cgTime = "CGTime"
        case units = "Units"
        case isTransmitterConnected = "IsTransmitterConnected"
    }
}

struct NowToken: Codable {
    let accessToken: String
    let expiresIn: Int
    let tokenType, expires, lastLogin: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case expires, lastLogin
    }
}

public typealias PatientData = [PatientDatum]

