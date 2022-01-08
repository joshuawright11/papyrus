/// Represents an item in a request's headers.
@propertyWrapper
public struct Header<L: LosslessStringConvertible & Codable>: RequestModifier {
    /// The value of the this header.
    public var wrappedValue: L
    public init(wrappedValue: L) { self.wrappedValue = wrappedValue }
    
    // MARK: RequestModifier
    
    public init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws {
        guard let string = request.headers[key] else { throw PapyrusError("Missing header at \(key).") }
        guard let value = L(string) else { throw PapyrusError("Unable to create a \(L.self) from header string at \(key): \(string)") }
        wrappedValue = value
    }
    
    public func modify<Req: RequestConvertible, Res: Codable>(endpoint: inout Endpoint<Req, Res>, for label: String) {
        endpoint.headers[label] = wrappedValue.description
    }
}
