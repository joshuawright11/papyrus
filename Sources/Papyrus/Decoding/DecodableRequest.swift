public protocol EndpointBuilder {
    func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> Self
}

public protocol RequestModifier: Codable {
    // Modify an Endpoint.
    func modify<Req, Res>(endpoint: inout Endpoint<Req, Res>, for label: String)
    
    // Initialize from a request to the given andpoint, at the given key.
    init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws
}

/*
 Left
 - @Multipart
    - @Part with headers & such
 - @Adapter
 - URLSession
 - `async/await`
 */
