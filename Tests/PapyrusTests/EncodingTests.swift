import XCTest
@testable import Papyrus

struct Provider<Service: API>: APIProvider {
    let baseURL: String
    var keyMapping: KeyMapping = .useDefaultKeys
}

final class EncodingTests: XCTestCase {
    private let testAPI = Provider<TestAPI>(baseURL: "http://localhost")
    private let snakeCaseAPI = Provider<TestAPI>(baseURL: "http://localhost", keyMapping: .snakeCase)
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
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
        
        let payload = try testAPI.post.rawRequest(with: request)
        XCTAssertEqual(payload.method, "POST")
        XCTAssertEqual(payload.path, "/foo/one/1234/\(uuid.uuidString)/false/0.123456/bar")
        XCTAssertEqual(payload.headers, ["header1": "header_value"])
        XCTAssertEqual(payload.queryItems?.sorted { $0.name < $1.name }, [
            "query1": "0",
            "query2": "two",
            "query3": nil,
            "query4[]": "three",
            "query4[]": "six",
            "query6": nil,
            "query7": "true",
        ])
        
        let expectedData = try JSONEncoder().encode(SomeJSON(string: "foo", int: 1))
        XCTAssertNotNil(payload.body)
        XCTAssertEqual(payload.body, expectedData)
    }
    
    func testEncodeURLBody() throws {
        let req = TestURLBody(body: SomeJSON(string: "test", int: 0))
        let payload = try testAPI.urlBody.rawRequest(with: req)
        XCTAssertEqual(payload.method, "PUT")
        XCTAssertEqual(payload.headers["foo"], "bar")
        XCTAssertTrue(payload.path.hasPrefix("/body"))
    }
    
    func testKeyMapping() throws {
        let req = KeyMappingRequest(pathString: "foo", queryString: "bar", headerString: "baz", body: .init(stringValue: "tiz", otherStringValue: "taz"))
        for converter in converters {
            var endpoint = snakeCaseAPI.key
            endpoint.setConverter(converter)
            let payload = try endpoint.rawRequest(with: req)
            XCTAssertEqual(payload.method, "POST")
            XCTAssertEqual(payload.path, "/key/foo")
            XCTAssertEqual(payload.headers["headerString"], "baz")
            XCTAssertEqual(payload.queryItems, ["query_string": "bar"])
            if converter is URLFormConverter {
                let string = String(data: payload.body ?? Data(), encoding: .utf8)
                XCTAssertTrue(string == "string_value=tiz&other_string_value=taz" || string == "other_string_value=taz&string_value=tiz")
            } else {
                let dict = try endpoint.baseRequest.contentConverter.decode([String: String].self, from: payload.body ?? Data())
                XCTAssertEqual(dict, ["string_value": "tiz", "other_string_value": "taz"])
            }
        }
    }
}

extension RawRequest {
    var queryItems: [URLQueryItem]? {
        URLComponents(string: "?\(query)")?.queryItems
    }
}

extension Array: ExpressibleByDictionaryLiteral where Element == URLQueryItem {
    public init(dictionaryLiteral elements: (String, String?)...) {
        self = elements.map { URLQueryItem(name: $0, value: $1) }
    }
}
