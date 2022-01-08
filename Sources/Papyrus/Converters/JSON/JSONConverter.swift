import Foundation

public struct JSONConverter: ContentConverter {
    public static var `default`: JSONConverter { JSONConverter(encoder: JSONEncoder(), decoder: JSONDecoder()) }

    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    public func with(keyMapping: KeyMapping) -> JSONConverter {
        let encoder = encoder
        encoder.keyEncodingStrategy = keyMapping.jsonEncodingStrategy
        let decoder = decoder
        decoder.keyDecodingStrategy = keyMapping.jsonDecodingStrategy
        return JSONConverter(encoder: encoder, decoder: decoder)
    }
    
    public func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
        try decoder.decode(type, from: data)
    }
    
    public func encode<E>(_ value: E) throws -> Data where E : Encodable {
        try encoder.encode(value)
    }
}

extension ContentConverter where Self == JSONConverter {
    public static var json: JSONConverter { .default }
}
