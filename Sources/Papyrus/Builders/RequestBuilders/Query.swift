/// Represents a value in the query of an endpoint's URL.
@propertyWrapper
public struct RequestQuery<Value: Codable>: RequestBuilder {
    /// The value of the query item.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        self.wrappedValue = try request.decodeQuery(KeyDecoder.self).decode(at: key)
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        components.addQuery(label, value: wrappedValue)
    }
}
