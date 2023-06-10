/// Represents a field in the body of a request.
@propertyWrapper
public struct RequestField<Value: Codable>: RequestBuilder {
    /// The value of the this body.
    public var wrappedValue: Value
    public init(wrappedValue: Value) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        let decoder = try request.decodeContent(KeyDecoder.self)
        if let t = Value.self as? AnyOptional.Type {
            if decoder.contains(at: key) {
                self.wrappedValue = try decoder.decode(at: key)
            } else {
                self.wrappedValue = t.nil as! Value
            }
        } else {
            self.wrappedValue = try decoder.decode(at: key)
        }
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        if let value = wrappedValue as? AnyOptional {
            if !value.isNil {
                components.addField(label, value: wrappedValue)
            }
        } else {
            components.addField(label, value: wrappedValue)
        }
    }
}

extension RequestField: Equatable where Value: Equatable {}
