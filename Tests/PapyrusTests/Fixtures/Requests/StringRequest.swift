import Papyrus

extension String: TestableRequest {
    static var expected: String = "foo"
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(body: try contentConverter.encode(expected))
    }
}
