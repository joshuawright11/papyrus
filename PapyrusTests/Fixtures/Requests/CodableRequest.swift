//import Papyrus
//
//struct CodableRequest: TestableRequest, Codable {
//    static var decodedRequest = CodableRequest(string: "foo", int: 0, bool: false, double: 0.123456)
//    
//    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
//        let body = try contentConverter.encode(decodedRequest)
//        return RawTestRequest(
//            headers: [
//                "Content-Type": contentConverter.contentType,
//                "Content-Length": String(body.count)
//            ],
//            body: body
//        )
//    }
//    
//    var string: String
//    var int: Int
//    var bool: Bool
//    var double: Double
//}
