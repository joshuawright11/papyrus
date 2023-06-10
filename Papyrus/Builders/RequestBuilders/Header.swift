/// Represents an item in a request's headers.
@propertyWrapper
public struct RequestHeader<L: LosslessStringConvertible & Codable>: RequestBuilder {
    /// The value of the this header.
    public var wrappedValue: L
    public init(wrappedValue: L) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestBuilder
    
    public init(from request: RawRequest, at key: String) throws {
        guard let string = request.headers[key] else { throw PapyrusError("Missing header at \(key).") }
        guard let value = L(string) else { throw PapyrusError("Unable to create a \(L.self) from header string at \(key): \(string)") }
        wrappedValue = value
    }
    
    public func build(components: inout PartialRequest, for label: String) {
        components.headers[label] = wrappedValue.description
    }
}

extension RequestHeader: Equatable where L: Equatable {}
