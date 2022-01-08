import Foundation

@propertyWrapper
public struct JSON<T: EndpointBuilder>: EndpointBuilder {
    public var wrappedValue: T {
        _wrappedValue.withBuilder {
            builder?(&$0)
            $0.converter = converter
        }
    }
    
    private let _wrappedValue: T
    private let converter: JSONConverter
    private var builder: ((inout AnyEndpoint) -> Void)?
    
    public init(wrappedValue: T, converter: JSONConverter = .default) {
        self._wrappedValue = wrappedValue
        self.converter = converter
    }
    
    public init(wrappedValue: T, encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self._wrappedValue = wrappedValue
        self.converter = JSONConverter(encoder: encoder, decoder: decoder)
    }
    
    // MARK: EndpointModifier
    
    public func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> JSON<T> {
        var copy = self
        copy.builder = action
        return copy
    }
}
