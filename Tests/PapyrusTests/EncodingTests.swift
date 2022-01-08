import XCTest
@testable import Papyrus

final class EncodingTests: XCTestCase {
    private let testAPI = Provider<TestAPI>("http://localhost")
    
    func testBaseURL() {
        XCTAssertEqual(testAPI.post.baseURL, "http://localhost")
    }
    
    func testEncodePathQueryHeadersJSONBody() throws {
        let uuid = UUID()
        let request = TestRequest(
            path1: "one",
            path2: 1234,
            path3: uuid,
            path4: false,
            path5: 0.123456,
            query1: 0,
            query2: "two",
            query3: nil,
            query4: ["three", "six"],
            query5: [],
            query6: nil,
            query7: true,
            header1: "header_value",
            body: SomeJSON(string: "foo", int: 1)
        )
        
        let payload = try self.testAPI.post.payload(with: request)
        XCTAssertEqual(payload.method, "POST")
        XCTAssertEqual(payload.urlComponents.path, "/foo/one/1234/\(uuid.uuidString)/false/0.123456/bar")
        XCTAssertEqual(payload.headers, ["header1": "header_value"])
        XCTAssertEqual(payload.urlComponents.queryItems?.sorted { $0.name < $1.name }, [
            URLQueryItem(name: "query1", value: "0"),
            URLQueryItem(name: "query2", value: "two"),
            URLQueryItem(name: "query3", value: nil),
            URLQueryItem(name: "query4[]", value: "three"),
            URLQueryItem(name: "query4[]", value: "six"),
            URLQueryItem(name: "query6", value: nil),
            URLQueryItem(name: "query7", value: "true"),
        ])
        
        let expectedData = try JSONEncoder().encode(SomeJSON(string: "foo", int: 1))
        XCTAssertNotNil(payload.body)
        XCTAssertEqual(payload.body, expectedData)
    }
    
    func testEncodeURLBody() throws {
        let req = TestURLBody(body: SomeJSON(string: "test", int: 0))
        let payload = try testAPI.urlBody.payload(with: req)
        XCTAssertEqual(payload.method, "PUT")
        XCTAssertEqual(payload.headers["foo"], "bar")
        XCTAssertTrue(payload.urlComponents.path.hasPrefix("/body"))
    }
}

extension Endpoint.Payload {
    var urlComponents: URLComponents {
        URLComponents(string: url) ?? URLComponents()
    }
}
