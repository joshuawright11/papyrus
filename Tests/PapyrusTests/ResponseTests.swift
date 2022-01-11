import XCTest
@testable import Papyrus

final class ResponseTests: XCTestCase {
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
    func testEncode() throws {
        for converter in converters {
            var endpoint = Endpoint<Empty, TestResponse>()
            endpoint.setConverter(converter)
            let testResponse = TestResponse(foo: "foo", bar: 0, baz: false, content: .init(foo: "foo", bar: 1))
            let expectedSize = try converter.encode(testResponse).count
            let rawResponse = try endpoint.rawResponse(with: testResponse)
            XCTAssertEqual(rawResponse.headers, [
                "Content-Type": converter.contentType,
                "Content-Length": String(expectedSize),
            ])
            guard let body = rawResponse.body else {
                XCTFail("There should be a response body.")
                return
            }
            
            let decoded = try converter.decode(TestResponse.self, from: body)
            XCTAssertEqual(decoded, testResponse)
        }
    }
    
    func testDecode() throws {
        for converter in converters {
            var endpoint = Endpoint<Empty, TestResponse>()
            endpoint.setConverter(converter)
            let testResponse = TestResponse(foo: "foo", bar: 0, baz: false, content: .init(foo: "foo", bar: 1))
            let rawData = try converter.encode(testResponse)
            let rawResponse = try endpoint.decodeResponse(headers: [:], body: rawData)
            XCTAssertEqual(rawResponse, testResponse)
        }
    }
    
    func testDecodeSingleValueJSON() throws {
        let converter: ContentConverter = .json
        var endpoint = Endpoint<Empty, String>()
        endpoint.setConverter(converter)
        let testResponse = "foo/bar/baz"
        let rawData = try converter.encode(testResponse)
        let rawResponse = try endpoint.decodeResponse(headers: [:], body: rawData)
        XCTAssertEqual(rawResponse, testResponse)
    }
    
    func testDecodeArrayJSON() throws {
        let converter: ContentConverter = .json
        var endpoint = Endpoint<Empty, [TestContent]>()
        endpoint.setConverter(converter)
        let testResponse = [TestContent(foo: "foo", bar: 0), TestContent(foo: "bar", bar: 1), TestContent(foo: "baz", bar: 2)]
        let rawData = try converter.encode(testResponse)
        let rawResponse = try endpoint.decodeResponse(headers: [:], body: rawData)
        XCTAssertEqual(rawResponse, testResponse)
    }
}

extension String: EndpointResponse {}
extension Array: EndpointResponse where Element == TestContent {}

private struct TestContent: Codable, Equatable {
    let foo: String
    let bar: Int
}

private struct TestResponse: EndpointResponse, Equatable {
    let foo: String
    let bar: Int
    let baz: Bool
    let content: TestContent
}
