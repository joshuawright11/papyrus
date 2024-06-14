import XCTest
@testable import Papyrus

final class ResponseDecoderTests: XCTestCase {
    func testWithKeyMappingDoesntMutate() throws {
        let decoder = JSONDecoder()
        let snakeDecoder = decoder.with(keyMapping: .snakeCase)
        
        switch decoder.keyDecodingStrategy {
            case .useDefaultKeys: break
            default: XCTFail("Should be default keys")
        }
        
        switch snakeDecoder.keyDecodingStrategy {
            case .convertFromSnakeCase: break
            default: XCTFail("Should be snake_case keys")
        }
    }
    
    func testResponseWithOptionalTypeAndNilBody() throws {
        // Arrange
        let response = _Response()
        response.body = nil

        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())

        //Assert
        XCTAssertNil(decoded)
    }
    
    func testResponseWithOptionalTypeAndEmptyBody() throws {
        // Arrange
        let response = _Response()
        response.body = "".data(using: .utf8)

        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())

        //Assert
        XCTAssertNil(decoded)
    }
    
    func testResponseWithOptionalTypeAndNonNilBody() throws {
        // Arrange
        let response = _Response()
        response.body = "{ \"name\": \"Petru\" }".data(using: .utf8)

        // Act
        let decoded = try response.decode(_Person?.self, using: JSONDecoder())
        
        //Assert
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.name, "Petru")
    }
    
    func testResponseWithNonOptionalTypeAndNonNilBody() throws {
        // Arrange
        let response = _Response()
        response.body = "{ \"name\": \"Petru\" }".data(using: .utf8)

        // Act
        let decoded = try response.decode(_Person.self, using: JSONDecoder())
        
        //Assert
        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded.name, "Petru")
    }
}

fileprivate struct _Person: Decodable {
    let name: String
}

fileprivate class _Response : PapyrusResponse {
    var request: PapyrusRequest?
    var body: Data?
    var headers: [String : String]?
    var statusCode: Int?
    var error: Error?
}
