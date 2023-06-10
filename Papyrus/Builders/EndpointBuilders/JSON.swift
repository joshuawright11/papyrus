import Foundation

@propertyWrapper
public struct JSON<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped { _wrappedValue.withBuilder(build: build) }
    public var build: (inout Endpoint<Request, Response>) -> Void
    private let _wrappedValue: Wrapped
    
    public init(wrappedValue: Wrapped, converter: JSONConverter = JSONConverter()) {
        self._wrappedValue = wrappedValue
        self.build = { $0.setConverter(converter) }
    }
    
    public init(wrappedValue: Wrapped, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.init(wrappedValue: wrappedValue, converter: JSONConverter(encoder: encoder, decoder: decoder))
    }
}
