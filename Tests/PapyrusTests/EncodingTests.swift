import XCTest
@testable import Papyrus

struct Provider<Service: API>: APIProvider {
    let baseURL: String
    var keyMapping: KeyMapping = .useDefaultKeys
}

final class EncodingTests: XCTestCase {
    private let api = Provider<TestAPI>(baseURL: "http://localhost")
    private let apiSnake = Provider<TestAPI>(baseURL: "http://localhost", keyMapping: .snakeCase)
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
    func testBaseURL() {
        XCTAssertEqual(api.post.baseURL, "http://localhost")
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
            header2: 1,
            header3: UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!,
            header4: true,
            header5: 0.123456,
            body: SomeContent(string: "foo", int: 1)
        )
        
        let payload = try api.post.rawRequest(with: request)
        XCTAssertEqual(payload.method, "POST")
        XCTAssertEqual(payload.path, "/foo/one/1234/\(uuid.uuidString)/false/0.123456/bar")
        XCTAssertEqual(payload.headers, [
            "header1": "header_value",
            "header2": "1",
            "header3": "99739f05-3096-4cbd-a35d-c6482f51a3cc".uppercased(),
            "header4": "true",
            "header5": "0.123456",
        ])
        XCTAssertEqual(payload.queryItems?.sorted { $0.name < $1.name }, [
            "query1": "0",
            "query2": "two",
            "query3": nil,
            "query4[]": "three",
            "query4[]": "six",
            "query6": nil,
            "query7": "true",
        ])
        
        let expectedData = try JSONEncoder().encode(SomeContent(string: "foo", int: 1))
        XCTAssertNotNil(payload.body)
        XCTAssertEqual(payload.body, expectedData)
    }
    
    func testEncodeURLBody() throws {
        let req = TestURLBody(body: SomeContent(string: "test", int: 0))
        let payload = try api.urlBody.rawRequest(with: req)
        XCTAssertEqual(payload.method, "PUT")
        XCTAssertEqual(payload.headers["foo"], "bar")
        XCTAssertEqual(payload.headers["one"], "1")
        XCTAssertEqual(payload.headers["two"], "2")
        XCTAssertEqual(payload.headers["three"], "3")
        XCTAssertEqual(payload.headers["four"], "4")
        XCTAssertEqual(payload.headers["five"], "5")
        XCTAssertTrue(payload.path.hasPrefix("/body"))
    }
    
    func testKeyMapping() throws {
        let req = KeyMappingRequest(pathString: "foo", queryString: "bar", headerString: "baz", body: .init(stringValue: "tiz", otherStringValue: "taz"))
        for converter in converters {
            var endpoint = apiSnake.key
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
