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
    public func request(_ request: RequestBuilder) async throws -> Response {

//        var next: (RequestBuilder) async throws -> Response = { request in
//
//        }
//
//        for interceptor in interceptors.reversed() {
//            next = { req in interceptor.intercept(req: req, next: next) }
//        }

        let req = try request.createURLRequest(baseURL: self.baseURL)
        return await self.session.request(req).validate().serializingData().response

        // TODO: How to access URL request in interceptor?
    }

    @discardableResult
    public func intercept(action: @escaping (RequestBuilder, () async throws -> Response) async throws -> Void) -> Self {
        interceptors.append(AnonymousInterceptor(action: action))
        return self
    }
}

protocol Interceptor {
    func intercept(req: RequestBuilder, next: () async throws -> Response) async throws
}

struct AnonymousInterceptor: Interceptor {
    let action: (RequestBuilder, () async throws -> Response) async throws -> Void

    func intercept(req: RequestBuilder, next: () async throws -> Response) async throws {
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
