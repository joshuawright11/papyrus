import Foundation

public struct AuthorizationHeader {
    public let value: String

    public init(value: String) {
        self.value = value
    }

    public static func bearer(_ token: String) -> AuthorizationHeader {
        AuthorizationHeader(value: "Bearer \(token)")
    }

    public static func basic(username: String, password: String) -> AuthorizationHeader {
        let unencoded = username + ":" + password
        let base64Encoded = Data(unencoded.utf8).base64EncodedString()
        return AuthorizationHeader(value: "Basic \(base64Encoded)")
    }
}
