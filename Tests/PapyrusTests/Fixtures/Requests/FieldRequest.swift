import Foundation
import Papyrus

struct FieldRequest: DecodeTestable {
    struct Body: Codable {
        let field1: String
        let field2: Int
        let field3: UUID
        let field4: Bool
        let field5: Double
    }
    
    @Field var field1: String
    @Field var field2: Int
    @Field var field3: UUID
    @Field var field4: Bool
    @Field var field5: Double
    
    static let expected: FieldRequest = FieldRequest(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456)
    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(Body(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456))
        return RawTestRequest(body: body)
    }
}
