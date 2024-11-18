import Foundation

/// Makes URL requests.
public final class Provider: Sendable {
    public let baseURL: String
    public let http: any HTTPService
    public let provider: any CoderProvider
    private let interceptors: ResourceMutex<[any Interceptor]>
    private let modifiers: ResourceMutex<[any RequestModifier]>

    public init(
        baseURL: String,
        http: any HTTPService,
        modifiers: [any RequestModifier] = [],
        interceptors: [any Interceptor] = [],
        provider: any CoderProvider = DefaultProvider()
    ) {
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

    public func insert(interceptor: any Interceptor, at index: Int) {
        interceptors.withLock { resource in
            resource.insert(interceptor, at: index)
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
    public func intercept(action: @Sendable @escaping (
        any PapyrusRequest,
        (any PapyrusRequest) async throws -> any PapyrusResponse
    ) async throws -> any PapyrusResponse) -> Self {
        struct AnonymousInterceptor: Interceptor {
            let action: @Sendable (any PapyrusRequest, Interceptor.Next) async throws -> any PapyrusResponse

            func intercept(req: any PapyrusRequest,
                           next: Interceptor.Next) async throws -> any PapyrusResponse {
                try await action(req, next)
            }
        }
        interceptors.withLock { resource in
            resource.append(AnonymousInterceptor(action: action))
        }
        return self
    }

    @discardableResult
    public func request(_ builder: inout RequestBuilder) async throws -> any PapyrusResponse {
        let request = try createRequest(&builder)
        var next: @Sendable (any PapyrusRequest) async throws -> any PapyrusResponse = http.request
        interceptors.withLock { resource in
            for interceptor in resource.reversed() {
                let _next = next
                next = { try await interceptor.intercept(req: $0, next: _next) }
            }
        }
        return try await next(request)
    }

    private func createRequest(_ builder: inout RequestBuilder) throws -> any PapyrusRequest {
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
    typealias Next = @Sendable (any PapyrusRequest) async throws -> any PapyrusResponse
    func intercept(req: any PapyrusRequest, next: Next) async throws -> any PapyrusResponse
}

public protocol RequestModifier {
    func modify(req: inout RequestBuilder) throws
}
