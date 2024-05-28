import Foundation

public struct RouterRequest {
    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: Data?

    public init(url: URL, method: String, headers: [String : String], body: Data?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }
}
