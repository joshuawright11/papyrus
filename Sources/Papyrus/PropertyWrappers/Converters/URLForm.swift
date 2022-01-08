import Foundation

@propertyWrapper
public struct URLForm<T: EndpointBuilder>: EndpointBuilder {
    public var wrappedValue: T {
        _wrappedValue.withBuilder {
            builder?(&$0)
            $0.converter = converter
        }
    }

    private let _wrappedValue: T
    private let converter: URLFormConverter
    private var builder: ((inout AnyEndpoint) -> Void)?
    
    public init(wrappedValue: T, converter: URLFormConverter = .default) {
        self._wrappedValue = wrappedValue
        self.converter = converter
    }
    
    public init(wrappedValue: T, encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) {
        self._wrappedValue = wrappedValue
        self.converter = URLFormConverter(encoder: encoder, decoder: decoder)
    }
    
    // MARK: EndpointModifier
    
    public func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> URLForm<T> {
        var copy = self
        copy.builder = action
        return copy
    }
}
