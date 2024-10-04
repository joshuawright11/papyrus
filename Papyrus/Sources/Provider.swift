import Foundation

/// Makes URL requests.
public final class Provider: Sendable {
    public let baseURL: String
    public let http: HTTPService
    public let provider: CoderProvider
    private let interceptors: ResourceMutex<[Interceptor]>
    private let modifiers: ResourceMutex<[RequestModifier]>

    public init(baseURL: String, http: HTTPService, modifiers: [RequestModifier] = [], interceptors: [Interceptor] = [], provider: CoderProvider = DefaultProvider()) {
        self.baseURL = baseURL
        self.http = http
        self.provider = provider
        self.interceptors = .init(resource: interceptors)
        self.modifiers = .init(resource: modifiers)
    }

    public func newBuilder(method: String, path: String) -> RequestBuilder {
        RequestBuilder(baseURL: baseURL, method: method, path: path)
    }

    public func add(interceptor: any Interceptor) {
        interceptors.withLock { resource in
            resource.append(interceptor)
        }
    }

    public func modifyRequests(action: @escaping (inout RequestBuilder) throws -> Void) -> Self {
        struct AnonymousModifier: RequestModifier {
            let action: (inout RequestBuilder) throws -> Void

            func modify(req: inout RequestBuilder) throws {
                try action(&req)
            }
        }

        modifiers.withLock { resource in
            resource.append(AnonymousModifier(action: action))
        }
        return self
    }

    @discardableResult
    public func intercept(action: @Sendable @escaping (PapyrusRequest, (PapyrusRequest) async throws -> PapyrusResponse) async throws -> PapyrusResponse) -> Self {
        struct AnonymousInterceptor: Interceptor {
            let action: @Sendable (PapyrusRequest, Interceptor.Next) async throws -> PapyrusResponse

            func intercept(req: PapyrusRequest, next: Interceptor.Next) async throws -> PapyrusResponse {
                try await action(req, next)
            }
        }
        interceptors.withLock { resource in
            resource.append(AnonymousInterceptor(action: action))
        }
        return self
    }

    @discardableResult
    public func request(_ builder: inout RequestBuilder) async throws -> PapyrusResponse {
        let request = try createRequest(&builder)
        var next: @Sendable (PapyrusRequest) async throws -> PapyrusResponse = http.request
        interceptors.withLock { resource in
            for interceptor in resource.reversed() {
                let _next = next
                next = { try await interceptor.intercept(req: $0, next: _next) }
            }
        }
        return try await next(request)
    }

    private func createRequest(_ builder: inout RequestBuilder) throws -> PapyrusRequest {
        try modifiers.withLock { resource in
            for modifier in resource {
                try modifier.modify(req: &builder)
            }
        }

        let url = try builder.fullURL()
        let (body, headers) = try builder.bodyAndHeaders()
        return http.build(method: builder.method, url: url, headers: headers, body: body)
    }
}

public protocol Interceptor: Sendable {
    typealias Next = @Sendable (PapyrusRequest) async throws -> PapyrusResponse
    func intercept(req: PapyrusRequest, next: Next) async throws -> PapyrusResponse
}

public protocol RequestModifier {
    func modify(req: inout RequestBuilder) throws
}
