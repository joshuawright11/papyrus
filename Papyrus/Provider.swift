import Alamofire
import Foundation

/// Makes URL requests.
public final class Provider: HTTPProvider {
    public let baseURL: String
    public let session: Session
    public var interceptors: [Interceptor]
    public var modifiers: [RequestModifier]

    public init(baseURL: String, session: Session = .default, modifiers: [RequestModifier] = [], interceptors: [Interceptor] = []) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
        self.modifiers = modifiers
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
    public func request(_ request: RequestBuilder) async throws -> Response {
        var next: (Request) async throws -> Response = _request
        for interceptor in interceptors.reversed() {
            let _next = next
            next = { try await interceptor.intercept(req: $0, next: _next) }
        }

        var _request = request
        for modifier in modifiers {
            try modifier.modify(req: &_request)
        }

        let req = try _request.createURLRequest(baseURL: baseURL)
        return try await next(req)
    }

    private func _request(_ request: Request) async -> Response {
        await session.request(request.request).validate().serializingData().response
    }
}

private struct AnonymousModifier: RequestModifier {
    let action: (inout RequestBuilder) throws -> Void

    func modify(req: inout RequestBuilder) throws {
        try action(&req)
    }
}

private struct AnonymousInterceptor: Interceptor {
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
    fileprivate func createURLRequest(baseURL: String) throws -> URLRequest {
        let url = try fullURL(baseURL: baseURL).asURL()
        let (body, headers) = try bodyAndHeaders()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}

extension Decodable {
    public init(response: Response, decoder: ResponseDecoder) throws {
        try response.validate()

        guard let data = response.body else {
            throw PapyrusError("Unable to decode `\(Self.self)` from a `Response`; body was nil.")
        }

        self = try decoder.decode(Self.self, from: data)
    }
}

extension ResponseDecoder {
    public func decode<D: Decodable>(_ type: D.Type = D.self, from response: Response) throws -> D {
        if let error = response.error {
            throw error
        }

        guard let data = response.body else {
            throw PapyrusError("Unable to decode `\(Self.self)` from a `Response`; body was nil.")
        }

        return try decode(type, from: data)
    }
}
