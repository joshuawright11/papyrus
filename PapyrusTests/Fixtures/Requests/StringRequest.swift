//import Papyrus
//
//extension String: TestableRequest {
//    static var decodedRequest: String = "foo"
//    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
//        let body = try contentConverter.encode(decodedRequest)
//        return RawTestRequest(
//            headers: [
//                "Content-Type": contentConverter.contentType,
//                "Content-Length": String(body.count)
//            ],
//            body: body)
//    }
//}
