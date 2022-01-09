import Foundation
import Papyrus

struct BodyRequest: TestableRequest {
    struct BodyContent: Codable, Equatable {
        var string: String
        var int: Int
    }
    
    @Path var path1: String
    @Path var path2: Int
    @Path var path3: UUID
    @Path var path4: Bool
    @Path var path5: Double

    @Query var query1: Int
    @Query var query2: Int?
    @Query var query3: String?
    @Query var query4: String?
    @Query var query5: Bool?
    @Query var query6: Bool
    @Query var query7: [String]
    @Query var query8: [String]?
    
    @Header var header1: String
    
    @Body var body: BodyContent
    
    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!

    static let basePath: String = "/:path1/:path2/:path3/:path4/:path5"
    static let expected = BodyRequest(
        path1: "bar",
        path2: 1234,
        path3: uuid,
        path4: true,
        path5: 0.123456,
        query1: 1,
        query3: "three",
        query6: true,
        query7: ["foo", "bar"],
        header1: "foo",
        body: BodyContent(string: "baz", int: 0))
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let expectedBody = BodyContent(string: "baz", int: 0)
        let body = try contentConverter.encode(expectedBody)
        return RawTestRequest(
            path: "/bar/1234/\(uuid.uuidString)/true/0.123456",
            headers: ["header1": "foo"],
            parameters: [
                "path1": "bar",
                "path2": "1234",
                "path3": uuid.uuidString,
                "path4": "true",
                "path5": "0.123456",
            ],
            query: "query1=1&query2&query3=three&query4&query5&query6=true&query7[]=foo&query7[]=bar&query8".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "",
            body: body
        )
    }
}
