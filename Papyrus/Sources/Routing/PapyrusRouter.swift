public protocol PapyrusRouter {
    func register(
        method: String,
        path: String,
        action: @escaping (RouterRequest) async throws -> RouterResponse
    )
}
