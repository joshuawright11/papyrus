import Papyrus

struct ComplexQueryRequest: TestableRequest {
    struct ComplexQuery: Codable, Equatable {
        let foo: String
        let bar: Int
    }
    
    @Query var query: ComplexQuery
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(
            headers: [
                "Content-Type": contentConverter.contentType,
                "Content-Length": "0"
            ],
            query: "query[foo]=foo&query[bar]=1".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }
    static var expected: ComplexQueryRequest = .init(query: .init(foo: "foo", bar: 1))
}
