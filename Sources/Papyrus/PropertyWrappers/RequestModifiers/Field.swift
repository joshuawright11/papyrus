/// Represents a field in the body of a request.
@propertyWrapper
public struct Field<Value: Codable>: RequestModifier {
    /// The value of the this body.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestModifier
    
    public init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws {
        guard let data = request.body else { throw PapyrusError("Tried to decode field \(key): \(Value.self) from a request but the body was empty.") }
        let deferred = try endpoint.converter.decode(DeferredDecoder.self, from: data)
        self.wrappedValue = try deferred.decode(at: key)
    }
    
    public func modify<Req: EndpointRequest, Res: Codable>(endpoint: inout Endpoint<Req, Res>, for label: String) {
        endpoint.addField(label, value: wrappedValue)
    }
}
