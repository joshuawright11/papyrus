import Foundation
@testable import Papyrus

@propertyWrapper
struct FOO<Wrapped: EndpointBuilder>: EndpointBuilder {
    public typealias Request = Wrapped.Request
    public typealias Response = Wrapped.Response
    
    public var wrappedValue: Wrapped {
        _wrappedValue.withBuilder(build: build)
    }
    
    private let _wrappedValue: Wrapped
    public var build: (inout Endpoint<Request, Response>) -> Void
    
    public init(wrappedValue: Wrapped) {
        self._wrappedValue = wrappedValue
        self.build = { $0.headers["foo"] = "bar" }
    }
}

final class TestAPI: API {
    @POST("/foo/:path1/:path2/:path3/:path4/:path5/bar")
    var post = Endpoint<TestRequest, Empty>()
    
    @JSON
    @FOO
    @PUT("/body")
    var urlBody = Endpoint<TestURLBody, Empty>()
    
    @POST("/key/:pathString")
    var key = Endpoint<KeyMappingRequest, Empty>()
    
    @POST("/multiple")
    var multipleBodies = Endpoint<MultipleBodies, Empty>()
    
    @GET("/query")
    var queryCodable = Endpoint<TestQueryCodable, Empty>()
    
    @DELETE("/delete")
    var delete = Endpoint<Empty, Empty>()
    
    @PATCH("/patch")
    var patch = Endpoint<Empty, Empty>()
    
    @CUSTOM(method: "CONNECT", "/connect")
    var custom = Endpoint<Empty, Empty>()
}

struct KeyMappingRequest: EndpointRequest {
    struct Content: Codable {
        var stringValue: String
        var otherStringValue: String
    }
    
    @Path   var pathString: String
    @Query  var queryString: String
    @Header var headerString: String
    @Body   var body: Content
}

struct TestRequest: EndpointRequest {
    @Path var path1: String
    @Path var path2: Int
    @Path var path3: UUID
    @Path var path4: Bool
    @Path var path5: Double
    
    @Query var query1: Int
    @Query var query2: String?
    @Query var query3: String?
    @Query var query4: [String]
    @Query var query5: [String]
    @Query var query6: Bool?
    @Query var query7: Bool
    
    @Header var header1: String
    
    @Body var body: SomeJSON
}

struct TestURLBody: EndpointRequest {
    @Body var body: SomeJSON
}

struct TestQueryCodable: EndpointRequest {
    @Query var body: SomeJSON
}

struct MultipleBodies: EndpointRequest {
    @Body var body1 = SomeJSON(string: "foo", int: 0)
    @Body var body2 = SomeJSON(string: "bar", int: 1)
}

struct SomeJSON: Codable {
    var string: String
    var int: Int
}
