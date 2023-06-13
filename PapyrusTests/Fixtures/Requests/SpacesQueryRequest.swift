//@testable
//import Papyrus
//
//struct SpacesQueryRequest: TestableRequest {
//    @Query var query: String
//
//
//    static let queryString = "Hello From Spaces!"
//    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
//        RawTestRequest(
//            headers: [
//                "Content-Type": contentConverter.contentType,
//                "Content-Length": "0"
//            ],
//            query: "query=\(queryString.addingPercentEncoding(withAllowedCharacters: URLEncodedForm.unreservedCharacters)!)"
//        )
//    }
//
//    static var decodedRequest = SpacesQueryRequest(query: SpacesQueryRequest.queryString)
//}
