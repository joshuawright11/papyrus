public protocol EndpointAdapter {
    func adapt<Req: EndpointRequest, Res: Codable>(endpoint: inout Endpoint<Req, Res>)
}

@propertyWrapper
struct Builder<Wrapped: EndpointBuilder, Adapter: EndpointAdapter>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped {
        _wrappedValue.withBuilder(build: build)
    }
    
    private let _wrappedValue: Wrapped
    public var build: (inout Endpoint<Request, Response>) -> Void
    
    public init(wrappedValue: Wrapped, _ adapter: Adapter) {
        self._wrappedValue = wrappedValue
        self.build = adapter.adapt
    }
}
