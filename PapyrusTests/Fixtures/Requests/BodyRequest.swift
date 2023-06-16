//import Foundation
//import Papyrus
//
//struct BodyRequest: TestableRequest {
//    struct BodyContent: Codable, Equatable {
//        var string: String
//        var int: Int
//    }
//    
//    var path1: String
//    var path2: Int
//    var path3: UUID
//    var path4: Bool
//    var path5: Double
//
//    var query1: Int
//    var query2: Int?
//    var query3: String?
//    var query4: String?
//    var query5: Bool?
//    var query6: Bool
//    var query7: [String]
//    var query8: [String]?
//    
//    var header1: String
//    
//    var body: BodyContent
//    
//    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!
//
//    static let basePath: String = "/:path1/:path2/:path3/:path4/:path5"
//    static let decodedRequest = BodyRequest(
//        path1: "bar",
//        path2: 1234,
//        path3: uuid,
//        path4: true,
//        path5: 0.123456,
//        query1: 1,
//        query3: "three",
//        query6: true,
//        query7: ["foo", "bar"],
//        header1: "foo",
//        body: BodyContent(string: "baz", int: 0))
//    
//    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
//        let expectedBody = BodyContent(string: "baz", int: 0)
//        let body = try contentConverter.encode(expectedBody)
//        return RawTestRequest(
//            path: "/bar/1234/\(uuid.uuidString)/true/0.123456",
//            headers: [
//                "header1": "foo",
//                "Content-Type": contentConverter.contentType,
//                "Content-Length": String(body.count)
//            ],
//            parameters: [
//                "path1": "bar",
//                "path2": "1234",
//                "path3": uuid.uuidString,
//                "path4": "true",
//                "path5": "0.123456",
//            ],
//            query: "query1=1&query2&query3=three&query4&query5&query6=true&query7[]=foo&query7[]=bar&query8",
//            body: body
//        )
//    }
//}
