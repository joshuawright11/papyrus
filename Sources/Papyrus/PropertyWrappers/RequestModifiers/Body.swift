/// Represents the body of a request.
@propertyWrapper
public struct Body<Value: Codable>: RequestModifier {
    /// The value of the this body.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestModifier
    
    public init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws {
        guard let data = request.body else { throw PapyrusError("Tried to decode \(Value.self) from a request body but the body was empty.") }
        self.wrappedValue = try endpoint.converter.decode(Value.self, from: data)
    }
    
    public func modify<Req: RequestConvertible, Res: Codable>(endpoint: inout Endpoint<Req, Res>, for label: String) {
        endpoint.setBody(wrappedValue)
    }
}
