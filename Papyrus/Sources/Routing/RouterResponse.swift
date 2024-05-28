import Foundation

public struct RouterResponse {
    public let status: Int
    public let headers: [String: String]
    public let body: Data?

    public init(_ status: Int, headers: [String: String] = [:], body: Data? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}
