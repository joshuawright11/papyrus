import Foundation
@testable import Papyrus

@propertyWrapper
struct FOO<T: EndpointBuilder>: EndpointBuilder {
    public var wrappedValue: T {
        _wrappedValue.withBuilder {
            builder?(&$0)
            $0.headers["foo"] = "bar"
        }
    }
    private let _wrappedValue: T
    private var builder: ((inout AnyEndpoint) -> Void)?

    init(wrappedValue: T) {
        _wrappedValue = wrappedValue
    }
    
    // MARK: EndpointModifier
    
    public func withBuilder(_ action: @escaping (inout AnyEndpoint) -> Void) -> FOO<T> {
        var copy = self
        copy.builder = action
        return copy
    }
}

final class TestAPI: API {
    @POST("/foo/:path1/:path2/:path3/:path4/:path5/bar")
    var post = Endpoint<TestRequest, Empty>()
    
    @JSON
    @FOO
    @PUT("/body")
    var urlBody = Endpoint<TestURLBody, Empty>()
    
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

struct TestRequest: RequestConvertible {
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

struct TestURLBody: RequestConvertible {
    @Body var body: SomeJSON
}

struct TestQueryCodable: RequestConvertible {
    @Query var body: SomeJSON
}

struct MultipleBodies: RequestConvertible {
    @Body var body1 = SomeJSON(string: "foo", int: 0)
    @Body var body2 = SomeJSON(string: "bar", int: 1)
}

struct SomeJSON: Codable {
    var string: String
    var int: Int
}
