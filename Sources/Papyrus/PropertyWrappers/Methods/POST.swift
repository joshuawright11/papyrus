/// Represents a POST `Endpoint`.
@propertyWrapper
public struct POST<Req: RequestConvertible, Res: Codable>: EndpointBuilder {
    public var wrappedValue: Endpoint<Req, Res>

    /// Initialize with a path.
    ///
    /// - Parameter path: The path of the endpoint.
    public init(wrappedValue: Endpoint<Req, Res>, _ path: String) {
        var copy = wrappedValue
        copy.method = "POST"
        copy.path = path
        self.wrappedValue = copy
    }
    
    // MARK: EndpointModifier
    
    public func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> POST<Req, Res> {
        // Not sure why can't pass unerased type through.
        var any: AnyEndpoint = wrappedValue
        action(&any)
        var copy = self
        copy.wrappedValue = any as! Endpoint<Req, Res>
        return copy
    }
}
