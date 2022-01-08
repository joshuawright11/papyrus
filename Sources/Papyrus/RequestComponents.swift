import Foundation

public struct RequestComponents {
    public let url: String
    public let parameters: [String: String]
    public let headers: [String: String]
    public let body: Data?
    public let urlComponents: URLComponents
    public var query: String { urlComponents.query ?? "" }
    
    public init(url: String, parameters: [String : String] = [:], headers: [String : String] = [:], body: Data? = nil) {
        self.url = url
        self.parameters = parameters
        self.headers = headers
        self.body = body
        self.urlComponents = URLComponents(string: url) ?? URLComponents()
    }
}
