import XCTest
@testable import Papyrus

final class ProviderTests: XCTestCase {
    private let api = Provider<TestAPI>(baseURL: "http://localhost")
    private let apiSnake = Provider<TestAPI>(baseURL: "http://localhost", keyMapping: .snakeCase)
    
    func testBaseURL() throws {
        let request = try api.custom.rawRequest()
        XCTAssertEqual(request.baseURL, "http://localhost")
        XCTAssertEqual(request.method, "FOO")
    }
    
    func testKeyMappingSet() {
        switch apiSnake.custom.baseRequest.keyMapping {
        case .snakeCase: break
        default: XCTFail("request keyMapping should be snake case")
        }
        
        switch apiSnake.custom.baseResponse.keyMapping {
        case .snakeCase: break
        default: XCTFail("response keyMapping should be snake case")
        }
    }
}
