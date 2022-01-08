/// Represents a path component value on an endpoint. This value will
/// replace a path component with the name of the property this
/// wraps.
@propertyWrapper
public struct Path<L: LosslessStringConvertible & Codable>: RequestModifier {
    /// The value of this path component.
    public var wrappedValue: L
    public init(wrappedValue: L) { self.wrappedValue = wrappedValue }

    // MARK: RequestModifier
    
    public init(from request: RequestComponents, at key: String, endpoint: AnyEndpoint) throws {
        guard let string = request.parameters[key] else { throw PapyrusError("Missing path item for \(key).") }
        guard let value = L(string) else { throw PapyrusError("Unable to create a \(L.self) from path string at \(key): \(string)") }
        wrappedValue = value
    }
    
    public func modify<Req: EndpointRequest, Res: Codable>(endpoint: inout Endpoint<Req, Res>, for label: String) {
        endpoint.parameters[label] = wrappedValue.description
    }
}
