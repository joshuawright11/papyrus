import Papyrus
import XCTest

/// Helper for running tests.
protocol TestableRequest: Equatable, EndpointRequest {
    static var basePath: String { get }
    static var decodedRequest: Self { get }
    static func encodedRequest(contentConverter: ContentConverter) throws -> RawTestRequest
}

extension TestableRequest {
    static var basePath: String { "/" }
    static func encodedRequest(contentConverter: ContentConverter, keyMapping: KeyMapping) throws -> RawTestRequest {
        try encodedRequest(contentConverter: contentConverter.with(keyMapping: keyMapping))
    }
}

extension TestableRequest {
    /// Test that the endpoint is decodable from the expected request.
    static func testDecode(converter: ContentConverter, keyMapping: KeyMapping = .useDefaultKeys, file: StaticString = #filePath, line: UInt = #line) throws {
        var endpoint = Endpoint<Self, Empty>()
        endpoint.setConverter(converter)
        endpoint.setKeyMapping(keyMapping)
        let input = try Self.encodedRequest(contentConverter: converter)
        let decoded = try endpoint.decodeRequest(test: input)
        XCTAssertEqual(decoded, Self.decodedRequest, file: file, line: line)
    }
    
    /// Test that the endpoint is encodable to the expected raw request.
    static func testEncode(converter: ContentConverter, keyMapping: KeyMapping = .useDefaultKeys, file: StaticString = #filePath, line: UInt = #line) throws {
        var endpoint = Endpoint<Self, Empty>()
        endpoint.setConverter(converter)
        let expected = try Self.encodedRequest(contentConverter: converter, keyMapping: keyMapping)
        endpoint.baseRequest.path = Self.basePath
        endpoint.setKeyMapping(keyMapping)
        let actual = try endpoint.rawRequest(with: Self.decodedRequest)
        XCTAssertEqual(expected.path, actual.path, file: file, line: line)
        XCTAssertEqual(expected.headers, actual.headers, file: file, line: line)
        XCTAssertEqual(expected.parameters, actual.parameters, file: file, line: line)
        let inputQuerySet = Set(expected.query.split(separator: "&"))
        let encodedQuerySet = Set(actual.query.split(separator: "&"))
        XCTAssertEqual(inputQuerySet, encodedQuerySet, file: file, line: line)
        if let body = expected.body {
            if converter is URLFormConverter {
                let inputString = String(data: body, encoding: .utf8) ?? ""
                let encodedString = actual.body.map { String(data: $0, encoding: .utf8) ?? "" } ?? ""
                XCTAssertEqual(Set(inputString.split(separator: "&")), Set(encodedString.split(separator: "&")), file: file, line: line)
            } else {
                XCTAssertEqual(expected.body, actual.body, file: file, line: line)
            }
        } else {
            XCTAssertNil(actual.body, file: file, line: line)
        }
    }
}

struct RawTestRequest: Equatable {
    var path: String = "/"
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
