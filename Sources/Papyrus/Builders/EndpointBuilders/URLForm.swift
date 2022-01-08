@propertyWrapper
public struct URLForm<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped { _wrappedValue.withBuilder(build: build) }
    public var build: (inout Endpoint<Request, Response>) -> Void
    private let _wrappedValue: Wrapped
    
    public init(wrappedValue: Wrapped, converter: URLFormConverter = URLFormConverter()) {
        self._wrappedValue = wrappedValue
        self.build = { $0.setConverter(converter) }
    }
    
    public init(wrappedValue: Wrapped, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) {
        self.init(wrappedValue: wrappedValue, converter: URLFormConverter(encoder: encoder, decoder: decoder))
    }
}
