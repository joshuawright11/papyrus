/// Decodes a `RequestConvertible` from `RequestComponents` and an `Endpoint`.
struct RequestDecoder: Decoder {
    /// A keyed container for routing which request component a value
    /// should decode from.
    private struct Keyed<Key: CodingKey>: KeyedDecodingContainerProtocol {
        /// The request from which we are decoding.
        let request: RequestComponents
        let endpoint: AnyEndpoint
        
        // MARK: KeyedDecodingContainerProtocol
        
        var codingPath: [CodingKey] = []
        var allKeys: [Key] = []
        
        func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
            if let type = type as? RequestModifier.Type {
                return try type.init(from: request, at: key.stringValue, endpoint: endpoint) as! T
            } else {
                // Assume everything else is a field.
                guard let data = request.body else { throw PapyrusError("Tried to decode field \(key): \(T.self) from a request but the body was empty.") }
                let deferred = try endpoint.converter.decode(DeferredDecoder.self, from: data)
                return try deferred.decode(at: key.stringValue)
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
    
    let request: RequestComponents
    let endpoint: AnyEndpoint
    
    // MARK: Decoder
    
    var codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        KeyedDecodingContainer(Keyed(request: self.request, endpoint: endpoint))
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer { try error() }
    func singleValueContainer() throws -> SingleValueDecodingContainer { try error() }
}

/// Throws an error letting the user know of the acceptable properties
/// on an `RequestConvertible`.
///
/// - Throws: Guaranteed to throw a `PapyrusError`.
/// - Returns: A generic type, though this never returns.
private func error<T>() throws -> T {
    throw PapyrusError("Encoding single values isn't supported.")
}
