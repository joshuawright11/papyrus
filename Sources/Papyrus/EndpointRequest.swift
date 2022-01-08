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
            if let type = type as? RequestBuilder.Type {
                return try type.init(from: request, at: key.stringValue) as! T
            } else {
                // Assume everything else is a field.
                return try request.decodeContent(KeyDecoder.self).decode(at: key.stringValue)
            }
        }
        
        func contains(_ key: Key) -> Bool { true }
        func decodeNil(forKey key: Key) throws -> Bool { try error() }
        func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws
            -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey { try error() }
        func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer { try error() }
        func superDecoder() throws -> Decoder { try error() }
        func superDecoder(forKey key: Key) throws -> Decoder { try error() }
    }
    
    let request: RawRequest
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed(request: request))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try error() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { try error() }
}

private func error<T>() throws -> T {
    throw PapyrusError("Only top level, codable values are supported.")
}
