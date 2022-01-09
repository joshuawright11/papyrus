import Papyrus

extension String: DecodeTestable {
    static var expected: String = "foo"
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(body: try contentConverter.encode(expected))
    }
}
