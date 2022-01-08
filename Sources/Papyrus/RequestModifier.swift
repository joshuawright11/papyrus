public protocol RequestModifier: Codable {
    // Initialize from a request to the given andpoint, at the given key.
    init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws
    // Modify an Endpoint.
    func modify<Req, Res>(endpoint: inout Endpoint<Req, Res>, for label: String)
}

/*
 Left
 - @Multipart
    - @Part with headers & such
 - URLSession
 - `async/await`
 */
