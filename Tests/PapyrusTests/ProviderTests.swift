import XCTest
@testable import Papyrus

private struct Provider<Service: API>: APIProvider {
    let baseURL: String
    var keyMapping: KeyMapping = .useDefaultKeys
}

final class ProviderTests: XCTestCase {
    private let api = Provider<TestAPI>(baseURL: "http://localhost")
    private let apiSnake = Provider<TestAPI>(baseURL: "http://localhost", keyMapping: .snakeCase)
    
    func testBaseURL() throws {
        let request = try api.custom.rawRequest()
        XCTAssertEqual(request.baseURL, "http://localhost")
        XCTAssertEqual(request.method, "FOO")
    }
    
    func testMultipleEndpointBuilders() throws {
        let payload = try api.stacked.rawRequest()
        XCTAssertEqual(payload.method, "PUT")
        XCTAssertEqual(payload.headers["foo"], "bar")
        XCTAssertEqual(payload.headers["one"], "1")
        XCTAssertEqual(payload.headers["two"], "2")
        XCTAssertEqual(payload.headers["three"], "3")
        XCTAssertEqual(payload.headers["four"], "4")
        XCTAssertEqual(payload.headers["five"], "5")
        XCTAssertTrue(payload.path.hasPrefix("/body"))
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
