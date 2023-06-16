//import Foundation
//import Papyrus
//
//struct FieldRequest: TestableRequest {
//    struct Body: Codable {
//        let field1: String
//        let field2: Int
//        let field3: UUID
//        let field4: Bool
//        let field5: Double
//    }
//    
//    var field1: String
//    var field2: Int
//    var field3: UUID
//    var field4: Bool
//    var field5: Double
//    var field6: String?
//    
//    static let decodedRequest: FieldRequest = FieldRequest(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456, field6: nil)
//    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!
//    
//    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest {
//        let body = try contentConverter.encode(Body(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456))
//        return RawTestRequest(
//            headers: [
//                "Content-Type": contentConverter.contentType,
//                "Content-Length": String(body.count)
//            ],
//            body: body)
//    }
//}
