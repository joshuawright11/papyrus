import Foundation

public struct JSONConverter: ContentConverter {
    public let contentType: String = "application/json"
    internal let encoder: JSONEncoder
    internal let decoder: JSONDecoder
    
    public init(encoder: JSONEncoder = JSONEncoder(), decoder: JSONDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }

    public func with(keyMapping: KeyMapping) -> JSONConverter {
        let encoder = encoder.copy()
        encoder.keyEncodingStrategy = keyMapping.jsonEncodingStrategy
        let decoder = decoder.copy()
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

extension JSONEncoder {
    fileprivate func copy() -> JSONEncoder {
        let new = JSONEncoder()
        new.keyEncodingStrategy = keyEncodingStrategy
        new.userInfo = userInfo
        new.dataEncodingStrategy = dataEncodingStrategy
        new.dateEncodingStrategy = dateEncodingStrategy
        new.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        new.outputFormatting = outputFormatting
        return new
    }
}

extension JSONDecoder {
    fileprivate func copy() -> JSONDecoder {
        let new = JSONDecoder()
        new.keyDecodingStrategy = keyDecodingStrategy
        new.userInfo = userInfo
        new.dataDecodingStrategy = dataDecodingStrategy
        new.dateDecodingStrategy = dateDecodingStrategy
        new.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
        return new
    }
}

extension ContentConverter where Self == JSONConverter {
    public static var json: JSONConverter { JSONConverter() }
}
