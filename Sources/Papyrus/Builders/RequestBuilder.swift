public protocol RequestBuilder: Codable {
    // Initialize from a request and the given key.
    init(from request: RawRequest, at key: String) throws
    // Modify the request.
    func build(components: inout PartialRequest, for label: String)
}
