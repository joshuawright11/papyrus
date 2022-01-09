import XCTest
@testable import Papyrus

final class DecodingTests: XCTestCase {
    private let converters: [ContentConverter] = [JSONConverter.json, .urlForm]
    
    func testDecodeRequest() throws {
        for converter in converters {
            try BodyRequest.test(converter: converter)
        }
    }
    
    func testDecodingComplexQuery() throws {
        for converter in converters {
            try ComplexQueryRequest.test(converter: converter)
        }
    }
    
    func testDecodingField() throws {
        for converter in converters {
            try FieldRequest.test(converter: converter)
        }
    }
    
    func testCodableRequest() throws {
        for converter in converters {
            try CodableRequest.test(converter: converter)
        }
    }
    
    func testTopLevelRequest() {
        XCTAssertNotNil(try String.test(converter: .json))
        // No top level allowed for URL form
        XCTAssertThrowsError(try String.test(converter: .urlForm))
    }
}

extension String: DecodeTestable {
    static var expected: String = "foo"
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(body: try contentConverter.encode(expected))
    }
}

struct CodableRequest: DecodeTestable {
    static var expected = CodableRequest(string: "foo", int: 0, bool: false, double: 0.123456)
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(body: try contentConverter.encode(expected))
    }
    
    var string: String
    var int: Int
    var bool: Bool
    var double: Double
}

struct ComplexQueryRequest: DecodeTestable {
    struct ComplexQuery: Codable, Equatable {
        let foo: String
        let bar: Int
    }
    
    @Query var query: ComplexQuery
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        RawTestRequest(query: "query[foo]=foo&query[bar]=1".addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "")
    }
    static var expected: ComplexQueryRequest = .init(query: .init(foo: "foo", bar: 1))
}

struct FieldRequest: DecodeTestable {
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
    
    static let expected: FieldRequest = FieldRequest(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456)
    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let body = try contentConverter.encode(Body(field1: "bar", field2: 1234, field3: uuid, field4: true, field5: 0.123456))
        return RawTestRequest(body: body)
    }
}

struct BodyRequest: DecodeTestable {
    struct BodyContent: Codable, Equatable {
        var string: String
        var int: Int
    }
    
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
    
    @Body var body: BodyContent
    
    private static let uuid = UUID(uuidString: "99739f05-3096-4cbd-a35d-c6482f51a3cc")!
    
    static let expected = BodyRequest(
        path1: "bar",
        path2: 1234,
        path3: uuid,
        path4: true,
        path5: 0.123456,
        query1: 1,
        query3: "three",
        query6: true,
        header1: "foo",
        body: BodyContent(string: "baz", int: 0))
    
    static func input(contentConverter: ContentConverter) throws -> RawTestRequest {
        let expectedBody = BodyContent(string: "baz", int: 0)
        let body = try contentConverter.encode(expectedBody)
        return RawTestRequest(
            headers: ["header1": "foo"],
            parameters: [
                "path1": "bar",
                "path2": "1234",
                "path3": uuid.uuidString,
                "path4": "true",
                "path5": "0.123456",
            ],
            query: "query1=1&query3=three&query6=true",
            body: body
        )
    }
}
