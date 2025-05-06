//
//  NowClient.h
//  NowClient
//
//  Created by Mark Wilson on 5/7/16.
//  Copyright © 2016 Mark Wilson. All rights reserved.
//

import Foundation
import LoopKit

public struct NowGlucose {
    public let glucose: UInt16
    public let trend: UInt8
    public let timestamp: Date
}



public enum NowError: Error {
    case httpError(Error)
    case dataError(reason: String)
}


public class NowClient {
    private let tokenStorage: KeychainManager

    public init(tokenStorage: KeychainManager) {
        self.tokenStorage = tokenStorage
    }

    private static let defaultSession = URLSession(configuration: .default)

    /// Authenticates with the Eversense Now API and stores the bearer token
    public func authenticate(completion: @escaping (Error?) -> Void) {
        guard let (username, password, url) = tokenStorage.getEversenseNowCredentials() else {
            completion(NSError(domain: "NowClient", code: 0, userInfo: [NSLocalizedDescriptionKey: "Username or password not set in KeychainStorage"]))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded;charset=UTF-8", forHTTPHeaderField: "Content-Type")
        request.setValue("Eversense%20NOW/35 CFNetwork/3826.400.120 Darwin/24.3.0", forHTTPHeaderField: "User-Agent")
        
        let usernamePart = "username=\(username)"
        let passwordPart = "password=\(password)"
        let grantTypePart = "grant_type=password"
        let clientIdPart = "client_id=eversenseMMAiOS"
        let clientSecretPart = #"client_secret=vYL4yrvM_E"K"# 
        let bodyString = [
            usernamePart,
            passwordPart,
            grantTypePart,
            clientIdPart,
            clientSecretPart
        ].joined(separator: "&")        
        request.httpBody = bodyString.data(using: .utf8)
        
        print("Sending authentication request")
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(error)
                return
            }
            
            guard let data = data else {
                completion(NSError(domain: "NowClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                return
            }
            
            if let tokenResponse = try? JSONDecoder().decode(NowToken.self, from: data) {
                do {
                    try self.tokenStorage.setEversenseNowAccessToken(tokenResponse.accessToken)
                    completion(nil)
                } catch {
                    completion(error)
                }
            } else {
                completion(NSError(domain: "NowClient", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid token response"]))
            }
        }
        task.resume()
    }


    public func fetchFollowingPatientList( completion: @escaping (Error?, PatientData?) -> Void) {
        guard let token = tokenStorage.getEversenseNowAccessToken() else {
            completion(NowError.dataError(reason: "Not authenticated"), nil)
            return
        }
        
        let url = URL(string: "https://usapialpha.eversensedms.com/api/care/GetFollowingPatientList")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("*/*", forHTTPHeaderField: "Accept")
        request.setValue("gzip, deflate, br", forHTTPHeaderField: "Accept-Encoding")
        request.setValue("Eversense%20NOW/35 CFNetwork/3826.400.120 Darwin/24.3.0", forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in

            guard let data = data else {
                completion(NowError.dataError(reason: "No data received"), nil)
                return
            }
            
            do {
                let patientData = try JSONDecoder().decode(PatientData.self, from: data)
                completion(nil, patientData)
            } catch {
                completion(NowError.dataError(reason: "Failed to decode response: \(error)"), nil)
            }
        }
        task.resume()
    }
    public func fetchLast(callback: @escaping (NowError?, NowGlucose?) -> Void) {
        fetchFollowingPatientList { (error, patientData) in
            if let error = error {
                print("Error fetching patient list: \(error.localizedDescription)")
                callback(NowError.dataError(reason: error.localizedDescription), nil)
            } else if let patientData = patientData {
                if let patient = patientData.first {
                    do {
                        let timestamp = try self.parseDate(patient.cgTime)
                        callback(
                            nil,
                            NowGlucose(
                                glucose: UInt16(patient.currentGlucose),
                                trend: UInt8(patient.glucoseTrend),
                                timestamp: timestamp
                            )
                        )
                    } catch {
                        callback(NowError.dataError(reason: "Failed to parse date: \(error)"), nil)
                    }
                } else {
                    print("No patient data available")
                    callback(NowError.dataError(reason: "No patient data available"), nil)
                }
            }
        }
    }
    
    private func parseDate(_ cgTime: String) throws -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: cgTime) {
            return date
        }
        return Date()
        }
}
