import Papyrus

struct KeyMappingFieldRequest: TestableRequest {
    struct Content: Codable, Equatable {
        var stringValue: String
        var otherStringValue: String
    }
    
    @Field var someField: Content
    
    static var expected = KeyMappingFieldRequest(
        someField: Content(
            stringValue: "tiz",
            otherStringValue: "taz"))
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(["some_field": Content(stringValue: "tiz", otherStringValue: "taz")])
        return RawTestRequest(
            headers: [
                "Content-Type": contentConverter.contentType,
                "Content-Length": String(body.count)
            ],
            body: body
        )
    }
}
