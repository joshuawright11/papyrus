import Foundation

/// Makes URL requests.
public final class Provider {
    public let baseURL: String
    public let http: HTTPService
    public var interceptors: [Interceptor]
    public var modifiers: [RequestModifier]

    public init(baseURL: String, http: HTTPService, modifiers: [RequestModifier] = [], interceptors: [Interceptor] = []) {
        self.baseURL = baseURL
        self.http = http
        self.interceptors = interceptors
        self.modifiers = modifiers
    }

    public func newBuilder(method: String, path: String) -> RequestBuilder {
        RequestBuilder(baseURL: baseURL, method: method, path: path)
    }

    public func modifyRequests(action: @escaping (inout RequestBuilder) throws -> Void) -> Self {
        struct AnonymousModifier: RequestModifier {
            let action: (inout RequestBuilder) throws -> Void

            func modify(req: inout RequestBuilder) throws {
                try action(&req)
            }
        }

        modifiers.append(AnonymousModifier(action: action))
        return self
    }

    @discardableResult
    public func intercept(action: @escaping (Request, (Request) async throws -> Response) async throws -> Response) -> Self {
        struct AnonymousInterceptor: Interceptor {
            let action: (Request, Interceptor.Next) async throws -> Response

            func intercept(req: Request, next: Interceptor.Next) async throws -> Response {
                try await action(req, next)
            }
        }

        interceptors.append(AnonymousInterceptor(action: action))
        return self
    }

    @discardableResult
    public func request(_ builder: inout RequestBuilder) async throws -> Response {
        let request = try createRequest(&builder)
        var next: (Request) async throws -> Response = http.request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        return try await next(request)
    }

    private func createRequest(_ builder: inout RequestBuilder) throws -> Request {
        for modifier in modifiers {
            try modifier.modify(req: &builder)
        }

        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()
        return http.build(method: builder.method, url: url, headers: headers, body: body)
    }
}

public protocol Interceptor {
    typealias Next = (Request) async throws -> Response
    func intercept(req: Request, next: Next) async throws -> Response
}

public protocol RequestModifier {
    func modify(req: inout RequestBuilder) throws
}
