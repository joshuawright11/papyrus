import Foundation
@testable import Papyrus

final class TestAPI: API {
    @POST("/foo/:path1/:path2/:path3/:path4/:path5/bar")
    var post = Endpoint<TestRequest, Empty>()
    
    @URLForm
    @HeaderWrapper
    @HeaderWrapper(name: "one", value: "1")
    @HeaderWrapper(name: "two", value: "2")
    @HeaderWrapper(name: "three", value: "3")
    @HeaderWrapper(name: "four", value: "4")
    @HeaderWrapper(name: "five", value: "5")
    @PUT("/body")
    var urlBody = Endpoint<TestURLBody, Empty>()
    
    @POST("/key/:pathString")
    var key = Endpoint<KeyMappingRequest, Empty>()
    
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
    @Query var query5: [String]?
    @Query var query6: Bool?
    @Query var query7: Bool
    
    @Header var header1: String
    @Header var header2: Int
    @Header var header3: UUID
    @Header var header4: Bool
    @Header var header5: Double
    
    @Body var body: SomeContent
}

struct TestURLBody: EndpointRequest {
    @Body var body: SomeContent
}

struct SomeContent: Codable, Equatable {
    var string: String
    var int: Int
}
