public protocol EndpointAdapter {
    func adapt<Req: EndpointRequest, Res: EndpointResponse>(endpoint: inout Endpoint<Req, Res>)
}

@propertyWrapper
public struct Builder<Wrapped: EndpointBuilder, Adapter: EndpointAdapter>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped { _wrappedValue.withBuilder(build: build) }
    public var build: (inout Endpoint<Request, Response>) -> Void
    private let _wrappedValue: Wrapped
    
    public init(wrappedValue: Wrapped, _ adapter: Adapter) {
        self._wrappedValue = wrappedValue
        self.build = adapter.adapt
    }
}
