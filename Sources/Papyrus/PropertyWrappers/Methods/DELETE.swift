/// Represents a DELETE `Endpoint`.
@propertyWrapper
public struct DELETE<Req: RequestConvertible, Res: Codable>: EndpointMethod {
    public static var method: String { "DELETE" }
    public var wrappedValue: Endpoint<Req, Res>
    public init(wrappedValue: Endpoint<Req, Res>) { self.wrappedValue = wrappedValue }
}

public protocol EndpointMethod: EndpointBuilder {
    associatedtype Req: RequestConvertible
    associatedtype Res: Codable

    static var method: String { get }
    var wrappedValue: Endpoint<Req, Res> { get set }

    init(wrappedValue: Endpoint<Req, Res>)
}

extension EndpointMethod {
    /// Initialize with a path.
    ///
    /// - Parameter path: The path of the endpoint.
    public init(wrappedValue: Endpoint<Req, Res>, _ path: String) {
        var copy = wrappedValue
        copy.method = Self.method
        copy.path = path
        self.init(wrappedValue: copy)
    }
    
    // MARK: EndpointModifier
    
    public func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> Self {
        var _any: AnyEndpoint = wrappedValue // Not sure why can't pass unerased type through.
        action(&_any)
        var copy = self
        copy.wrappedValue = _any as! Endpoint<Req, Res>
        return copy
    }
}
