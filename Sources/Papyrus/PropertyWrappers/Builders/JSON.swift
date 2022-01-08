import Foundation

@propertyWrapper
public struct JSON<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped {
        _wrappedValue.withBuilder(build: build)
    }
    
    private let _wrappedValue: Wrapped
    public var build: (inout Endpoint<Request, Response>) -> Void
    
    public init(wrappedValue: Wrapped, converter: JSONConverter = .default) {
        self._wrappedValue = wrappedValue
        self.build = { $0.converter = converter }
    }
    
    public init(wrappedValue: Wrapped, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self._wrappedValue = wrappedValue
        self.build = { $0.converter = JSONConverter(encoder: encoder, decoder: decoder) }
    }
}
