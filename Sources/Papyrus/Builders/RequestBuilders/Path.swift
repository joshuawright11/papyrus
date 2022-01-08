/// Represents a path component value on an endpoint. This value will replace a
/// path component with the name of the property this wraps.
@propertyWrapper
public struct RequestPath<L: LosslessStringConvertible & Codable>: RequestBuilder {
    /// The value of this path component.
    public var wrappedValue: L
    public init(wrappedValue: L) { self.wrappedValue = wrappedValue }

    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        guard let string = request.parameters[key] else { throw PapyrusError("Missing path item for \(key).") }
        guard let value = L(string) else { throw PapyrusError("Unable to create a \(L.self) from path string at \(key): \(string)") }
        wrappedValue = value
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        components.parameters[label] = wrappedValue.description
    }
}
