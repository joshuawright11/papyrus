import Papyrus

@propertyWrapper
struct HeaderWrapper<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped {
        _wrappedValue.withBuilder(build: build)
    }
    
    private let _wrappedValue: Wrapped
    public var build: (inout Endpoint<Request, Response>) -> Void
    
    public init(wrappedValue: Wrapped) {
        self._wrappedValue = wrappedValue
        self.build = { $0.baseRequest.headers["foo"] = "bar" }
    }
    
    public init(wrappedValue: Wrapped, name: String, value: String) {
        self._wrappedValue = wrappedValue
        self.build = { $0.baseRequest.headers[name] = value }
    }
}
