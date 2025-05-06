import LoopKit
import Combine
import Foundation

public class NowService: ServiceAuthentication {
    
    public var isAuthorized: Bool = false
    private let keychain: KeychainManager
    private let queue = DispatchQueue(label: "com.eversense.nowservice")
    private var credentials: (username: String?, password: String?, url: URL?)?
    public var credentialValues: [String?]

    public let title: String = LocalizedString("Eversense Now", comment: "The title of the Eversense Now service")
    
    public init(keychain: KeychainManager = KeychainManager()) {
        self.keychain = keychain
        self.client = NowClient(tokenStorage: keychain)
        isAuthorized = keychain.getEversenseNowAccessToken() != nil
        credentials = keychain.getEversenseNowCredentials()
        credentialValues = [
            credentials?.username,
            credentials?.password,
            credentials?.url?.absoluteString
        ]
    }

    // The now client, if credentials are present
    private(set) var client: NowClient?

    public var username: String? {
        return credentialValues[0]
    }

    var password: String? {
        return credentialValues[1]
    }

    var url: URL? {
        guard let urlString = credentialValues[2] else {
            return nil
        }

        return URL(string: urlString)
    }

    public func verify(_ completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        guard let client = client else {
            completion(false, NSError(domain: "NowService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Client is not initialized"]))
            return
        }

        client.authenticate { error in
            if let error = error {
                print("Authentication failed: \(error.localizedDescription)")
                completion(false, error)
            } else {
                print("Authentication succeeded")
                self.isAuthorized = true
                completion(true, nil)
            }
        }

    }
                
    public func reset() {
        try? keychain.setEversenseNowCredentials(username: nil, password: nil)
        isAuthorized = false
    }
}

extension NowService {
    public convenience init(keychainManager: KeychainManager = KeychainManager()) {
        self.init(keychain: keychainManager)
    }
}

