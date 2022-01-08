struct DeferredDecoder: Decodable {
    let keyed: KeyedDecodingContainer<GenericCodingKey>
    
    init(from decoder: Decoder) throws {
        self.keyed = try decoder.container(keyedBy: GenericCodingKey.self)
    }
    
    func decode<D: Decodable>(_ type: D.Type = D.self, at key: String) throws -> D {
        return try keyed.decode(D.self, forKey: GenericCodingKey(key))
    }
}
