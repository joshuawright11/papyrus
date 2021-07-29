import Foundation
@testable import Papyrus

final class TestAPI: EndpointGroup {
    var jsonEncoder: JSONEncoder {
        let enc = JSONEncoder()
        enc.dateEncodingStrategy = .iso8601
        return enc
    }
    
    var jsonDecoder: JSONDecoder {
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        return dec
    }
    
    var baseURL: String { "http://localhost" }
    
    @POST("/foo/:path1/bar")
    var post: Endpoint<TestRequest, Empty>
    
    @PUT("/body")
    var urlBody: Endpoint<TestURLBody, Empty>
    
    @POST("/multiple")
    var multipleBodies: Endpoint<MultipleBodies, Empty>
    
    @GET("/query")
    var queryCodable: Endpoint<TestQueryCodable, Empty>
    
    @DELETE("/delete")
    var delete: Endpoint<Empty, Empty>
    
    @PATCH("/patch")
    var patch: Endpoint<Empty, Empty>
    
    @CUSTOM(method: "CONNECT", "/connect")
    var custom: Endpoint<Empty, Empty>
    
    func intercept(_ components: inout HTTPComponents) {}
}

struct TestRequest: RequestComponents {
    @Path
    var path1: String
    
    @URLQuery
    var query1: Int
    
    @URLQuery
    var query2: String?
    
    @URLQuery
    var query3: String?
    
    @URLQuery
    var query4: [String]
    
    @URLQuery
    var query5: [String]
    
    @URLQuery
    var query6: Bool?
    
    @URLQuery
    var query7: Bool
    
    @Header
    var header1: String
    
    @Body
    var body: SomeJSON
}

struct TestURLBody: RequestComponents {
    static var bodyEncoding: BodyEncoding = .urlEncoded
    
    @Body
    var body: SomeJSON
    
    init(body: SomeJSON) {
        self.body = body
    }
}

struct TestQueryCodable: RequestComponents {
    @URLQuery
    var body: SomeJSON
}

struct MultipleBodies: RequestComponents {
    @Body
    var body1 = SomeJSON(string: "foo", int: 0)
    
    @Body
    var body2 = SomeJSON(string: "bar", int: 1)
}

struct SomeJSON: Codable {
    var string: String
    var int: Int
}
