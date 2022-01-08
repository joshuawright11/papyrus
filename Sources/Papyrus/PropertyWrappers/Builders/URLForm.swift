import Foundation

@propertyWrapper
public struct URLForm<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped {
        _wrappedValue.withBuilder(build: build)
    }
    
    private let _wrappedValue: Wrapped
    public var build: (inout Endpoint<Request, Response>) -> Void
    
    public init(wrappedValue: Wrapped, converter: URLFormConverter = .default) {
        self._wrappedValue = wrappedValue
        self.build = { $0.converter = converter }
    }
    
    public init(wrappedValue: Wrapped, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) {
        self._wrappedValue = wrappedValue
        self.build = { $0.converter = URLFormConverter(encoder: encoder, decoder: decoder) }
    }
}
