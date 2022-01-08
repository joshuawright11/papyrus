import Foundation

public struct URLFormConverter: ContentConverter {
    public static let `default` = URLFormConverter(encoder: URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder())

    public let encoder: URLEncodedFormEncoder
    public let decoder: URLEncodedFormDecoder
    
    public init(encoder: URLEncodedFormEncoder = URLEncodedFormEncoder(), decoder: URLEncodedFormDecoder = URLEncodedFormDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
        guard let string = String(data: data, encoding: .utf8) else {
            throw PapyrusError("Body data wasn't utf8 encoded.")
        }
        
        return try decoder.decode(type, from: string)
    }
    
    public func encode<E>(_ value: E) throws -> Data where E : Encodable {
        guard let data = try encoder.encode(value).data(using: .utf8) else {
            throw PapyrusError("URLEncoded string wasn't convertible to utf8 data.")
        }
        
        return data
    }
}

extension ContentConverter where Self == URLFormConverter {
    public static var urlForm: URLFormConverter { .default }
}
