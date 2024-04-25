@_exported import Foundation
#if os(Linux)
@_exported import FoundationNetworking
#endif
@_exported import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            urlSession: URLSession = .shared,
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = [RetryInterceptor()]) {
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
        return request
    }

    public func request(_ req: Request) async -> Response {
#if os(Linux) // Linux doesn't have access to async URLSession APIs
        await withCheckedContinuation { continuation in
            request(req, completionHandler: continuation.resume)
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

    public func request(_ req: Request, completionHandler: @escaping (Response) -> Void) {
        let urlRequest = req.urlRequest
        dataTask(with: urlRequest) {
            completionHandler(_Response(request: urlRequest, response: $1, error: $2, body: $0))
        }.resume()
    }
}

// MARK: `Response` Conformance

extension Response {
    public var urlRequest: URLRequest { (self as! _Response).urlRequest }
    public var urlResponse: URLResponse? { (self as! _Response).urlResponse }
}

private struct _Response: Response {
    let urlRequest: URLRequest
    let urlResponse: URLResponse?

    var request: Request? { urlRequest }
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

extension Request {
    public var urlRequest: URLRequest {
        (self as! URLRequest)
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

// MARK: Retry Interceptor

public struct RetryInterceptor: Interceptor {
    public init() {}

    public func intercept(req: Request, next: Next) async throws -> Response {
        var response: Response
        var retryCount = 0
        let maxRetryCount = 3

        repeat {
            do {
                response = try await next(req)
                if let statusCode = response.statusCode, (500...599).contains(statusCode) {
                    retryCount += 1
                    try await Task.sleep(nanoseconds: 2_000_000_000 * UInt64(retryCount)) // Exponential backoff
                } else {
                    return response
                }
            } catch {
                throw error
            }
        } while retryCount < maxRetryCount

        return response
    }
}
