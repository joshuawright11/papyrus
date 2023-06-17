import Foundation

/// Makes URL requests.
public final class Provider {
    public let baseURL: String
    public let client: ProviderClient
    public var interceptors: [Interceptor]
    public var modifiers: [RequestModifier]

    public init(baseURL: String, client: ProviderClient, modifiers: [RequestModifier] = [], interceptors: [Interceptor] = []) {
        self.baseURL = baseURL
        self.client = client
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
        var _builder = builder
        for modifier in modifiers {
            try modifier.modify(req: &_builder)
        }

        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()
        let request = client.build(method: builder.method, url: url, headers: headers, body: body)

        var next = client.request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        return try await next(request)
    }
}
