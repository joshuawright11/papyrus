/// Represents the body of a request.
@propertyWrapper
public struct RequestBody<Value: Codable>: RequestBuilder {
    /// The value of the this body.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        self.wrappedValue = try request.decodeContent(Value.self)
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        components.setBody(wrappedValue)
    }
}

extension RequestBody: Equatable where Value: Equatable {}
