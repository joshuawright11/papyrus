import Alamofire
import Foundation

/*
 GOALS
 1. Escape hatches to underlying types
    - alter underlying request
    - inspect underlying response on success
    - inspect underlying response on error
    - cancel in flight request
 2. Allow for usage on server.
    - don't be tightly coupled to Alamofire or URLSession

 Escape hatch.
 */

/// Makes URL requests.
public final class Provider: HTTPProvider {
    let baseURL: String
    let session: Session
    var interceptors: [Interceptor]

    public init(baseURL: String, session: Session = .default, interceptors: [() -> Void] = []) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = []
    }

    @discardableResult
    public func intercept(action: @escaping (Request, (Request) async throws -> Response) async throws -> Response) -> Self {
        interceptors.append(AnonymousInterceptor(action: action))
        return self
    }

    @discardableResult
    public func request(_ request: RequestBuilder) async throws -> Response {
        var next: (Request) async throws -> Response = _request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        let req = try request.createURLRequest(baseURL: baseURL)
        return try await next(req)
    }

    private func _request(_ request: Request) async throws -> Response {
        await session.request(request.request).validate().serializingData().response
    }
}

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

protocol Interceptor {
    func intercept(req: Request, next: (Request) async throws -> Response) async throws -> Response
}

struct AnonymousInterceptor: Interceptor {
    let action: (Request, (Request) async throws -> Response) async throws -> Response

    func intercept(req: Request, next: (Request) async throws -> Response) async throws -> Response {
        try await action(req, next)
    }
}

public protocol HTTPProvider {
    @discardableResult
    func request(_ request: RequestBuilder) async throws -> Response
}

extension RequestBuilder {
    func createURLRequest(baseURL: String) throws -> URLRequest {
        let url = try fullURL(baseURL: baseURL).asURL()
        let (body, headers) = try bodyAndHeaders()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}
