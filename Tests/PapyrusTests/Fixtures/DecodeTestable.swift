import Papyrus
import XCTest

protocol DecodeTestable: Equatable, EndpointRequest {
    static var expected: Self { get }
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest
}

extension DecodeTestable {
    static func test(converter: ContentConverter, file: StaticString = #filePath, line: UInt = #line) throws {
        var endpoint = Endpoint<Self, Empty>()
        endpoint.setConverter(converter)
        let input = try Self.input(contentConverter: converter)
        let decoded = try endpoint.decodeRequest(test: input)
        XCTAssertEqual(decoded, Self.expected, file: file, line: line)
    }
}

struct RawTestRequest {
    var headers: [String: String] = [:]
    var parameters: [String: String] = [:]
    var query: String = ""
    var body: Data? = nil
}

extension Endpoint {
    func decodeRequest(test: RawTestRequest) throws -> Request {
        try decodeRequest(method: "GET", path: "/foo", headers: test.headers, parameters: test.parameters, query: test.query, body: test.body)
    }
}
