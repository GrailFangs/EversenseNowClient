import Foundation
import LoopKit

extension KeychainManager {
    private var eversenseNowLabel: String { "com.eversense.nowclient.credentials" }
    private var eversenseNowURL: URL { URL(string: "https://usiamapi.eversensedms.com/connect/token")! }
    private var eversenseNowTokenService: String { "com.eversense.nowclient.token" }

    func setEversenseNowCredentials(username: String?, password: String?) throws {
        let credentials: InternetCredentials?
        if let username = username, let password = password {
            credentials = InternetCredentials(username: username, password: password, url: eversenseNowURL)
        } else {
            credentials = nil
        }
        try replaceInternetCredentials(nil, forURL: eversenseNowURL)
        try replaceInternetCredentials(credentials, forLabel: eversenseNowLabel)
    }

    func getEversenseNowCredentials() -> (username: String, password: String, url: URL)? {
        do {
            do {
                let credentials = try getInternetCredentials(label: eversenseNowLabel)
                return (username: credentials.username, password: credentials.password, url: credentials.url)
            } catch KeychainManagerError.copy {
                let credentials = try getInternetCredentials(url: eversenseNowURL)
                try setEversenseNowCredentials(username: credentials.username, password: credentials.password)
                return (username: credentials.username, password: credentials.password, url: credentials.url)
            }
        } catch {
            return nil
        }
    }

    func setEversenseNowAccessToken(_ token: String?) throws {
        try replaceGenericPassword(token, forService: eversenseNowTokenService)
    }

    func getEversenseNowAccessToken() -> String? {
        do {
            return try getGenericPasswordForService(eversenseNowTokenService)
        } catch {
            return nil
        }
    }
}
