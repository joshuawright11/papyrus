import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    func testDecodeRequest() throws {
        let pathUuid = UUID()
        let body = try JSONEncoder().encode(SomeJSON(string: "baz", int: 0))
        let mockRequest = MockRequest(
            headers: ["header1": "foo"],
            parameters: [
                "path1": "bar",
                "path2": "1234",
                "path3": pathUuid.uuidString,
                "path4": "true",
                "path5": "0.123456",
            ],
            queries: [
                "query1": 1,
                "query3": "three",
                "query6": true,
            ],
            bodyData: body
        )
        let decodedRequest = try DecodeTestRequest(from: mockRequest)
        XCTAssertEqual(decodedRequest.header1, "foo")
        XCTAssertEqual(decodedRequest.path1, "bar")
        XCTAssertEqual(decodedRequest.path2, 1234)
        XCTAssertEqual(decodedRequest.path3, pathUuid)
        XCTAssertEqual(decodedRequest.path4, true)
        XCTAssertEqual(decodedRequest.path5, 0.123456)
        XCTAssertEqual(decodedRequest.query1, 1)
        XCTAssertEqual(decodedRequest.query2, nil)
        XCTAssertEqual(decodedRequest.query3, "three")
        XCTAssertEqual(decodedRequest.query4, nil)
        XCTAssertEqual(decodedRequest.body.string, "baz")
        XCTAssertEqual(decodedRequest.body.int, 0)
    }
    
    /// Decoding `@Body` with content `urlEncoded` isn't supported yet.
    func testDecodeURLBodyThrows() throws {
        XCTAssertThrowsError(try TestURLBody(from: MockRequest()))
    }
}

final class TestDecoderAPI: EndpointGroup {
    var baseURL: String = "123"
    
    var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    @POST("/test")
    var thing: Endpoint<Request, String>
}

struct Request: RequestBody {
    var thing: String = ""
}

struct MockRequest: DecodableRequest {
    let headers: [String: String]
    let parameters: [String: String]
    let queries: [String: Any]
    let bodyData: Data?
    
    init(
        headers: [String: String] = [:],
        parameters: [String: String] = [:],
        queries: [String: Any] = [:],
        bodyData: Data? = nil
    ) {
        self.headers = headers
        self.parameters = parameters
        self.queries = queries
        self.bodyData = bodyData
    }
    
    func header(_ key: String) -> String? {
        self.headers[key]
    }
    
    func query(_ key: String) -> String? {
        self.queries[key].map { "\($0)" }
    }
    
    func parameter(_ key: String) -> String? {
        self.parameters[key]
    }
    
    func decodeContent<T: Decodable>(type: ContentEncoding) throws -> T {
        try JSONDecoder().decode(T.self, from: self.bodyData ?? Data())
    }
}

struct DecodeTestRequest: RequestComponents {
    @Path var path1: String
    @Path var path2: Int
    @Path var path3: UUID
    @Path var path4: Bool
    @Path var path5: Double

    @URLQuery var query1: Int
    @URLQuery var query2: Int?
    @URLQuery var query3: String?
    @URLQuery var query4: String?
    @URLQuery var query5: Bool?
    @URLQuery var query6: Bool
    
    @Header var header1: String
    
    @Body var body: SomeJSON
}
