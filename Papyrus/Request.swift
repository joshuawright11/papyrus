import Foundation

public protocol Request {
    var url: URL? { get set }
    var method: String { get set }
    var headers: [String: String] { get set }
    var body: Data? { get set }
}

extension Request {
    public var request: URLRequest {
        self as! URLRequest
    }
}

extension URLRequest: Request {
    public var body: Data? {
        get { httpBody }
        set { httpBody = newValue }
    }

    public var method: String {
        get { httpMethod ?? "" }
        set { httpMethod = newValue }
    }

    public var headers: [String: String] {
        get { allHTTPHeaderFields ?? [:] }
        set { allHTTPHeaderFields = newValue }
    }
}
