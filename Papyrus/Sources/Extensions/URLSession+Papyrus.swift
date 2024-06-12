import Foundation
#if os(Linux)
import FoundationNetworking
#endif

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
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> PapyrusRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        return request
    }

    public func request(_ req: PapyrusRequest) async -> PapyrusResponse {
#if os(Linux) // Linux doesn't have access to async URLSession APIs
        await withCheckedContinuation { continuation in
            let urlRequest = req.urlRequest
            dataTask(with: urlRequest) { data, response, error in
                let response = _Response(request: urlRequest, response: response, error: error, body: data)
                continuation.resume(returning: response)
            }.resume()
        }
#else
        let urlRequest = req.urlRequest
        do {
            let (data, res) = try await data(for: urlRequest)
            return _Response(request: urlRequest, response: res, error: nil, body: data)
        } catch {
            return _Response(request: urlRequest, response: nil, error: error, body: nil)
        }
#endif
    }
}

// MARK: `Response` Conformance

extension PapyrusResponse {
    public var urlRequest: URLRequest { (self as! _Response).urlRequest }
    public var urlResponse: URLResponse? { (self as! _Response).urlResponse }
}

private struct _Response: PapyrusResponse {
    let urlRequest: URLRequest
    let urlResponse: URLResponse?

    var request: PapyrusRequest? { urlRequest }
    let error: Error?
    let body: Data?
    let headers: [String: String]?
    var statusCode: Int? { (urlResponse as? HTTPURLResponse)?.statusCode }

    init(request: URLRequest, response: URLResponse?, error: Error?, body: Data?) {
        self.urlRequest = request
        self.urlResponse = response
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

extension PapyrusRequest {
    public var urlRequest: URLRequest {
        (self as! URLRequest)
    }
}

extension URLRequest: PapyrusRequest {
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
