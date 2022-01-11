import Papyrus
import XCTest

/// Helper for running tests.
protocol TestableRequest: Equatable, EndpointRequest {
    static var expected: Self { get }
    static var basePath: String { get }
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest
}

extension TestableRequest {
    static var basePath: String { "/" }
    static func input(contentConverter: ContentConverter, keyMapping: KeyMapping) throws -> RawTestRequest {
        try input(contentConverter: contentConverter.with(keyMapping: keyMapping))
    }
}

extension TestableRequest {
    /// Test that the endpoint is decodable from the expected request.
    static func testDecode(converter: ContentConverter, keyMapping: KeyMapping = .useDefaultKeys, file: StaticString = #filePath, line: UInt = #line) throws {
        var endpoint = Endpoint<Self, Empty>()
        endpoint.setConverter(converter)
        endpoint.setKeyMapping(keyMapping)
        let input = try Self.input(contentConverter: converter)
        let decoded = try endpoint.decodeRequest(test: input)
        XCTAssertEqual(decoded, Self.expected, file: file, line: line)
    }
    
    /// Test that the endpoint is encodable to the expected raw request.
    static func testEncode(converter: ContentConverter, keyMapping: KeyMapping = .useDefaultKeys, file: StaticString = #filePath, line: UInt = #line) throws {
        var endpoint = Endpoint<Self, Empty>()
        endpoint.setConverter(converter)
        let input = try Self.input(contentConverter: converter, keyMapping: keyMapping)
        endpoint.baseRequest.path = Self.basePath
        endpoint.setKeyMapping(keyMapping)
        let encoded = try endpoint.rawRequest(with: Self.expected)
        XCTAssertEqual(input.path, encoded.path, file: file, line: line)
        XCTAssertEqual(input.headers, encoded.headers, file: file, line: line)
        XCTAssertEqual(input.parameters, encoded.parameters, file: file, line: line)
        let inputQuerySet = Set(input.query.split(separator: "&"))
        let encodedQuerySet = Set(encoded.query.split(separator: "&"))
        XCTAssertEqual(inputQuerySet, encodedQuerySet, file: file, line: line)
        if let body = input.body {
            if converter is URLFormConverter {
                let inputString = String(data: body, encoding: .utf8) ?? ""
                let encodedString = encoded.body.map { String(data: $0, encoding: .utf8) ?? "" } ?? ""
                XCTAssertEqual(Set(inputString.split(separator: "&")), Set(encodedString.split(separator: "&")), file: file, line: line)
            } else {
                XCTAssertEqual(input.body, encoded.body, file: file, line: line)
            }
        } else {
            XCTAssertNil(encoded.body, file: file, line: line)
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
