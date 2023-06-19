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
        modifiers.append(AnonymousModifier(action: action))
        return self
    }

    @discardableResult
    public func intercept(action: @escaping (Request, (Request) async throws -> Response) async throws -> Response) -> Self {
        interceptors.append(AnonymousInterceptor(action: action))
        return self
    }

    @discardableResult
    public func request(_ builder: RequestBuilder) async throws -> Response {
        let request = try createRequest(builder)
        var next: (Request) async throws -> Response = http.request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        return try await next(request)
    }

    private func createRequest(_ builder: RequestBuilder) throws -> Request {
        var _builder = builder
        for modifier in modifiers {
            try modifier.modify(req: &_builder)
        }

        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()
        return http.build(method: builder.method, url: url, headers: headers, body: body)
    }
}

// MARK: Closure Based APIs

extension Provider {
    public func request(_ builder: RequestBuilder, completionHandler: @escaping (Response) -> Void) {
        do {
            let request = try createRequest(builder)
            var next = http.request
            for interceptor in interceptors.reversed() {
                let _next = next
                next = {
                    interceptor.intercept(req: $0, completionHandler: $1, next: _next)
                }
            }

            return next(request, completionHandler)
        } catch {
            completionHandler(.error(error))
        }
    }
}

extension Interceptor {
    fileprivate func intercept(
        req: Request,
        completionHandler: @escaping (Response) -> Void,
        next: @escaping (Request, @escaping (Response) -> Void) -> Void
    ) {
        Task {
            do {
                completionHandler(
                    try await intercept(req: req) { req in
                        return try await withCheckedThrowingContinuation {
                            next(req, $0.resume)
                        }
                    }
                )
            } catch {
                completionHandler(.error(error))
            }
        }
    }
}
