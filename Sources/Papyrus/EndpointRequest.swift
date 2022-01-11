/// A type that can be the `Request` of an `Endpoint`.
public protocol EndpointRequest: Codable {
    init(from request: RawRequest) throws
}

extension EndpointRequest {
    public typealias Header = RequestHeader
    public typealias Field = RequestField
    public typealias Body = RequestBody
    public typealias Query = RequestQuery
    public typealias Path = RequestPath
    
    public init(from request: RawRequest) throws {
        try self.init(from: EndpointRequestDecoder(request: request))
    }
}

// Decode arrays as raw types.
extension Array where Element: Codable {
    public init(from request: RawRequest) throws {
        self = try request.decodeContent()
    }
}

/// Decodes a `RequestConvertible` from `RequestComponents` and an `Endpoint`.
private struct EndpointRequestDecoder: Decoder {
    /// A keyed container for routing which request component a value
    /// should decode from.
    private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        /// The request from which we are decoding.
        let request: RawRequest
        
        // MARK: KeyedDecodingContainerProtocol
        
        var codingPath: [CodingKey] = []
        var allKeys: [Key] = []
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            guard let type = type as? RequestBuilder.Type else {
                // Assume everything else is a field.
                return try request.decodeContent(KeyDecoder.self).decode(at: key.stringValue)
            }
            
            return try type.init(from: request, at: key.stringValue) as! T
        }
        
        func decodeNil(forKey key: Key) throws -> Bool {
            try request.decodeContent(KeyDecoder.self).decodeNil(at: key.stringValue)
        }
        
        func contains(_ key: Key) -> Bool {
            guard let decoder = try? request.decodeContent(KeyDecoder.self) else { return false }
            return decoder.contains(at: key.stringValue)
        }
        
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { try error() }
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { try error() }
        func superDecoder() throws -> Decoder { try error() }
        func superDecoder(forKey key: Key) throws -> Decoder { try error() }
    }
    
    private struct Single: SingleValueDecodingContainer {
        let request: RawRequest
        var codingPath: [CodingKey] = []
        
        func decodeNil() -> Bool {
            request.body == nil
        }
        
        func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
            try request.decodeContent(T.self)
        }
    }
    
    let request: RawRequest
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed(request: request))
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        Single(request: request)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try error() }
}

private func error<T>() throws -> T {
    throw PapyrusError("Can't decode \(T.self) from a request; only top level, codable values are supported.")
}
