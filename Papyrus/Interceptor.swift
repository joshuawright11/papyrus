public protocol Interceptor {
    func intercept(req: Request, next: (Request) async throws -> Response) async throws -> Response
}

struct AnonymousInterceptor: Interceptor {
    let action: (Request, (Request) async throws -> Response) async throws -> Response

    func intercept(req: Request, next: (Request) async throws -> Response) async throws -> Response {
        try await action(req, next)
    }
}
