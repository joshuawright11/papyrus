struct KeyDecoder: Decodable {
    let keyed: KeyedDecodingContainer<GenericCodingKey>
    
    init(from decoder: Decoder) throws {
        self.keyed = try decoder.container(keyedBy: GenericCodingKey.self)
    }
    
    func decode<D: Decodable>(_ type: D.Type = D.self, at key: String) throws -> D {
        try keyed.decode(D.self, forKey: GenericCodingKey(key))
    }
    
    func decodeNil(at key: String) throws -> Bool {
        try keyed.decodeNil(forKey: GenericCodingKey(key))
    }
    
    func contains(at key: String) -> Bool {
        keyed.contains(GenericCodingKey(key))
    }
}
