import Papyrus

struct KeyMappingRequest: TestableRequest {
    struct Content: Codable, Equatable {
        var stringValue: String
        var otherStringValue: String
    }
    
    @Path   var pathString: String
    @Query  var queryString: String
    @Header var headerString: String
    @Body   var body: Content
    
    static var basePath: String = "/foo/:path_string/bar"
    static var expected = KeyMappingRequest(
        pathString: "foo",
        queryString: "bar",
        headerString: "baz",
        body: Content(
            stringValue: "tiz",
            otherStringValue: "taz"))
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(Content(stringValue: "tiz", otherStringValue: "taz"))
        return RawTestRequest(
            path: "/foo/foo/bar",
            headers: [
                "headerString": "baz",
                "Content-Type": contentConverter.contentType,
                "Content-Length": String(body.count)
            ],
            parameters: ["path_string": "foo"],
            query: "query_string=bar",
            body: body
        )
    }
}
