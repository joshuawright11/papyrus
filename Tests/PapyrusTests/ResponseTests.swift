import XCTest
@testable import Papyrus

final class ResponseTests: XCTestCase {
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
    func testEncode() throws {
        for converter in converters {
            var endpoint = Endpoint<Empty, TestResponse>()
            endpoint.setConverter(converter)
            let testResponse = TestResponse(foo: "foo", bar: 0, baz: false, content: .init(foo: "foo", bar: 1))
            let rawResponse = try endpoint.rawResponse(with: testResponse)
            XCTAssertTrue(rawResponse.headers.isEmpty)
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
}

struct TestResponse: EndpointResponse, Equatable {
    struct Content: Codable, Equatable {
        let foo: String
        let bar: Int
    }
    
    let foo: String
    let bar: Int
    let baz: Bool
    let content: Content
}
