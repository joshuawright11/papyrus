import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
    func testDecodeRequest() throws {
        let pathUuid = UUID()
        let expectedBody = SomeJSON(string: "baz", int: 0)
        for converter in converters {
            var endpoint = Endpoint<DecodeTestRequest, Empty>()
            endpoint.converter = converter
            let body = try converter.encode(expectedBody)
            let url = "https://localhost.com/example?query1=1&query3=three&query6=true"
            let components = RequestComponents(
                url: url,
                parameters: [
                    "path1": "bar",
                    "path2": "1234",
                    "path3": pathUuid.uuidString,
                    "path4": "true",
                    "path5": "0.123456",
                ],
                headers: ["header1": "foo"],
                body: body
            )
            let decodedRequest = try endpoint.decodeRequest(components: components)
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
    }
    
    func testDecodingField() throws {
        let fieldUuid = UUID()
        let expectedOutput = FieldTestRequest.Body(field1: "bar", field2: 1234, field3: fieldUuid, field4: true, field5: 0.123456)
        for converter in converters {
            let body = try converter.encode(expectedOutput)
            var endpoint = Endpoint<FieldTestRequest, Empty>()
            endpoint.converter = converter
            let query = try endpoint.queryConverter.encoder.encode(["query": ComplexQuery(foo: "one", bar: 2)])
            let percentEncodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
            let components = RequestComponents(url: "https://localhost.com/example?\(percentEncodedQuery)", body: body)
            let decodedRequest = try endpoint.decodeRequest(components: components)
            XCTAssertEqual(decodedRequest.query.foo, "one")
            XCTAssertEqual(decodedRequest.query.bar, 2)
            XCTAssertEqual(decodedRequest.field1, "bar")
            XCTAssertEqual(decodedRequest.field2, 1234)
            XCTAssertEqual(decodedRequest.field3, fieldUuid)
            XCTAssertEqual(decodedRequest.field4, true)
            XCTAssertEqual(decodedRequest.field5, 0.123456)
        }
    }
    
    /// Decoding `@Body` with content `urlEncoded` isn't supported yet.
    func testDecodeURLBodyThrows() throws {
        let endpoint = Endpoint<TestURLBody, Empty>()
        XCTAssertThrowsError(try endpoint.decodeRequest(components: RequestComponents(url: "", parameters: [:], headers: [:], body: nil)))
    }
}

final class TestDecoderAPI {
    @POST("/test")
    var thing = Endpoint<Request, String>()
}

struct Request: RequestConvertible {
    var thing: String = ""
}

struct ComplexQuery: Codable {
    let foo: String
    let bar: Int
}

struct FieldTestRequest: RequestConvertible {
    struct Body: Codable {
        let field1: String
        let field2: Int
        let field3: UUID
        let field4: Bool
        let field5: Double
    }
    
    @Field var field1: String
    @Field var field2: Int
    @Field var field3: UUID
    @Field var field4: Bool
    @Field var field5: Double

    @Query var query: ComplexQuery
}

struct DecodeTestRequest: RequestConvertible {
    @Path var path1: String
    @Path var path2: Int
    @Path var path3: UUID
    @Path var path4: Bool
    @Path var path5: Double

    @Query var query1: Int
    @Query var query2: Int?
    @Query var query3: String?
    @Query var query4: String?
    @Query var query5: Bool?
    @Query var query6: Bool
    
    @Header var header1: String
    
    @Body var body: SomeJSON
}
