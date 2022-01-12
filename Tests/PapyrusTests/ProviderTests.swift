import XCTest
@testable import Papyrus

final class ProviderTests: XCTestCase {
    private let api = Provider(api: TestAPI())
    private let apiSnake = Provider(api: TestAPI(keyMapping: .snakeCase))
    
    func testBaseURL() throws {
        let request = try api.custom.rawRequest()
        XCTAssertEqual(request.baseURL, "http://localhost")
        XCTAssertEqual(request.method, "FOO")
    }
    
    func testKeyMappingSet() {
        switch apiSnake.get.baseRequest.preferredKeyMapping {
        case .snakeCase: break
        default: XCTFail("request keyMapping should be snake case")
        }
        
        switch apiSnake.get.baseResponse.preferredKeyMapping {
        case .snakeCase: break
        default: XCTFail("response keyMapping should be snake case")
        }
    }
    
    func testPrecedence() {
        XCTAssertTrue(api.url.baseRequest.contentConverter is URLFormConverter)
        XCTAssertTrue(api.url.baseResponse.contentConverter is URLFormConverter)
    }
}
