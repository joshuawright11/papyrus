import Papyrus

struct NilRequest: TestableRequest {
    static var expected = NilRequest(string: "foo", int: 0, bool: nil, double: nil)
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(expected)
        return RawTestRequest(
            headers: [
                "Content-Type": contentConverter.contentType,
                "Content-Length": String(body.count)
            ],
            body: body
        )
    }
    
    var string: String?
    var int: Int?
    var bool: Bool?
    var double: Double?
}
