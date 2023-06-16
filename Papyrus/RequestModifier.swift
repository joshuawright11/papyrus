public protocol RequestModifier {
    func modify(req: inout RequestBuilder) throws
}

struct AnonymousModifier: RequestModifier {
    let action: (inout RequestBuilder) throws -> Void

    func modify(req: inout RequestBuilder) throws {
        try action(&req)
    }
}
