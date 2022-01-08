/// Represents a field in the body of a request.
@propertyWrapper
public struct RequestField<Value: Codable>: RequestBuilder {
    /// The value of the this body.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        self.wrappedValue = try request.decodeContent(KeyDecoder.self).decode(at: key)
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        components.addField(label, value: wrappedValue)
    }
}
