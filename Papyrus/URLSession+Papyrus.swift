@_exported import Foundation
#if os(Linux)
// URLSession isn't supported on Linux. If you need to target Linux, please use https://github.com/joshuawright11/papyrus-async-http-client instead.
#else
@_exported import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            urlSession: URLSession = .shared,
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = []) {
        self.init(baseURL: baseURL, http: urlSession, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `HTTPService` Conformance

extension URLSession: HTTPService {
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> Request {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        return _Request(request: request)
    }

    public func request(_ req: Request) async -> Response {
        let urlRequest = req.urlRequest
        do {
            let (data, res) = try await data(for: urlRequest)
            return _Response(request: urlRequest, response: res, error: nil, body: data)
        } catch {
            return _Response(request: urlRequest, response: nil, error: error, body: nil)
        }
    }

    public func request(_ req: Request, completionHandler: @escaping (Response) -> Void) {
        let urlRequest = req.urlRequest
        dataTask(with: urlRequest) {
            completionHandler(_Response(request: urlRequest, response: $1, error: $2, body: $0))
        }.resume()
    }
}

// MARK: `Response` Conformance

extension Response {
    public var urlRequest: URLRequest { (self as! _Response).request }
    public var urlResponse: URLResponse? { (self as! _Response).response }
}

private struct _Response: Response {
    let request: URLRequest
    let response: URLResponse?
    let error: Error?
    let body: Data?
    let headers: [String: String]?
    var statusCode: Int? { (urlResponse as? HTTPURLResponse)?.statusCode }
    
    init(request: URLRequest, response: URLResponse?, error: Error?, body: Data?) {
        self.request = request
        self.response = response
        self.error = error
        self.body = body
        let headerPairs = (response as? HTTPURLResponse)?
            .allHeaderFields
            .compactMap { key, value -> (String, String)? in
                guard let key = key as? String, let value = value as? String else {
                    return nil
                }
                
                return (key, value)
            }
        if let headerPairs {
            self.headers = .init(uniqueKeysWithValues: headerPairs)
        } else {
            self.headers = nil
        }
    }
}

// MARK: `Request` Conformance

extension Request {
    public var urlRequest: URLRequest {
        (self as! _Request).request
    }
}

private struct _Request: Request {
    var request: URLRequest

    public var url: URL {
        get { request.url! }
        set { request.url = newValue }
    }

    public var body: Data? {
        get { request.httpBody }
        set { request.httpBody = newValue }
    }

    public var method: String {
        get { request.httpMethod ?? "" }
        set { request.httpMethod = newValue }
    }

    public var headers: [String: String] {
        get { request.allHTTPHeaderFields ?? [:] }
        set { request.allHTTPHeaderFields = newValue }
    }
}
#endif
