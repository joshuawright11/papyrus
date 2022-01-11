import Foundation

public struct URLFormConverter: ContentConverter {
    public let contentType: String = "application/x-www-form-urlencoded"
    private let encoder: URLEncodedFormEncoder
    private let decoder: URLEncodedFormDecoder
    
    public init(encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public func with(keyMapping: KeyMapping) -> URLFormConverter {
        var encoder = encoder
        encoder.keyMapping = keyMapping
        var decoder = decoder
        decoder.keyMapping = keyMapping
        return URLFormConverter(encoder: encoder, decoder: decoder)
    }
    
    public func decode<D: Decodable>(_ type: D.Type, from string: String) throws -> D {
        try decoder.decode(type, from: string)
    }
    
    public func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
        guard let string = String(data: data, encoding: .utf8) else {
            throw PapyrusError("Body data wasn't utf8 encoded.")
        }
        
        return try decode(type, from: string)
    }
    
    public func encode<E: Encodable>(_ value: E) throws -> Data {
        let string: String = try encode(value)
        guard let data = string.data(using: .utf8) else {
            throw PapyrusError("URLEncoded string wasn't convertible to utf8 data.")
        }
        
        return data
    }
    
    public func encode<E: Encodable>(_ value: E) throws -> String {
        try encoder.encode(value)
    }
}

extension ContentConverter where Self == URLFormConverter {
    public static var urlForm: URLFormConverter { URLFormConverter() }
}
