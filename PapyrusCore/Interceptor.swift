public protocol Interceptor {
    typealias Next = (Request) async throws -> Response

    func intercept(req: Request, next: Next) async throws -> Response
}

struct AnonymousInterceptor: Interceptor {
    let action: (Request, Interceptor.Next) async throws -> Response

    func intercept(req: Request, next: Interceptor.Next) async throws -> Response {
        try await action(req, next)
    }
}
