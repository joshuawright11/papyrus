import Papyrus

struct NilRequest: TestableRequest {
    static var decodedRequest = NilRequest(string: "foo", int: 0, bool: nil, double: nil)
    
    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(decodedRequest)
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
