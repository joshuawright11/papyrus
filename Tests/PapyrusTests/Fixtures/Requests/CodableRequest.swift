import Papyrus

struct CodableRequest: TestableRequest {
    static var expected = CodableRequest(string: "foo", int: 0, bool: false, double: 0.123456)
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(body: try contentConverter.encode(expected))
    }
    
    var string: String
    var int: Int
    var bool: Bool
    var double: Double
}
