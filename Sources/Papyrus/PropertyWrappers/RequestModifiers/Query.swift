/// Represents a value in the query of an endpoint's URL.
@propertyWrapper
public struct Query<Value: Codable>: RequestModifier {
    /// The value of the query item.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestModifier
    
    public init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws {
        let deferredDecoder = try endpoint.queryConverter.decoder.decode(DeferredDecoder.self, from: request.query)
        self.wrappedValue = try deferredDecoder.decode(at: key)
    }
    
    public func modify<Req: RequestConvertible, Res: Codable>(endpoint: inout Endpoint<Req, Res>, for label: String) {
        endpoint.queries[label] = AnyEncodable(wrappedValue)
    }
}
