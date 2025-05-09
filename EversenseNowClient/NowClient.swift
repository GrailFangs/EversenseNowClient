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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(NSError(domain: "NowClient", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid response type"]))
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


    public func fetchFollowingPatientList(completion: @escaping (Error?, PatientData?) -> Void) {
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
           
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(NowError.dataError(reason: "Invalid response type"), nil)
                return
            }

            if httpResponse.statusCode == 401  {
                // Token expired, attempt to refresh
                self.authenticate { error in
                    if let error = error {
                        completion(error, nil)
                        return
                    }
                    completion(nil,nil)
                    return
                }
            }
            
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
                    if patient.isTransmitterConnected == true{
                        do {
                            let timestamp = try self.parseDate(patient.cgTime)
                            let trend: Int?
                            if let nowTrend = patient.glucoseTrend as? Int{
    //                            # public final class GlucoseTrendArrow {
    //                            #     private static final int STALE = 0;
    //
    //                            #     /* renamed from: Companion, reason: from kotlin metadata */
    //                            #     public static final Companion INSTANCE = new Companion(null);
    //                            #     private static final int FALLING_FAST = 1;
    //                            #     private static final int FALLING = 2;
    //                            #     private static final int FLAT = 3;
    //                            #     private static final int RISING = 4;
    //                            #     private static final int RISING_FAST = 5;
    //                            #     private static final int FALLING_RAPID = 6;
    //                            #     private static final int RAISING_RAPID = 7;
                                let trendmap = [0: 0, 7: 1, 5: 2, 4: 3, 3: 4, 2: 5, 1: 6, 6: 7]
                                trend = trendmap[nowTrend, default: 0]
                            } else {
                                trend = patient.glucoseTrend
                            }
                            callback(
                                nil,
                                NowGlucose(
                                    glucose: UInt16(patient.currentGlucose),
                                    trend: UInt8(trend ?? 0),
                                    timestamp: timestamp
                                )
                            )
                        } catch {
                            callback(NowError.dataError(reason: "Failed to parse date: \(error)"), nil)
                        }
                    } else {
                        print("Transmitter not connected")
                        callback(NowError.dataError(reason: "Transmitter not connected"), nil)
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
