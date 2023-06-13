//import XCTest
//@testable import Papyrus
//
//final class ProviderTests: XCTestCase {
//    private let api = Provider(api: TestAPI())
//    private let apiSnake = Provider(api: TestAPI(keyMapping: .snakeCase))
//
//    func testBaseURL() throws {
//        let request = try api.custom.rawRequest()
//        XCTAssertEqual(request.baseURL, "http://localhost")
//        XCTAssertEqual(request.method, "FOO")
//    }
//    
//    func testFullURL() throws {
//        XCTAssertEqual(try api.custom.rawRequest().fullURL(), "http://localhost/foo")
//        XCTAssertEqual(try api.custom.rawRequest().fullURL(override: "https://example.com"), "https://example.com/foo")
//        XCTAssertEqual(try api.query.rawRequest(with: QueryRequest()).fullURL(), "http://localhost/query?key=value")
//        XCTAssertEqual(try api.queryInPath.rawRequest(with: QueryRequest()).fullURL(), "http://localhost/queryInPath?key2=value2&key=value")
//    }
//    
//    func testKeyMappingSet() {
//        switch apiSnake.get.baseRequest.preferredKeyMapping {
//        case .snakeCase: break
//        default: XCTFail("request keyMapping should be snake case")
//        }
//        
//        switch apiSnake.get.baseResponse.preferredKeyMapping {
//        case .snakeCase: break
//        default: XCTFail("response keyMapping should be snake case")
//        }
//    }
//    
//    func testPrecedence() {
//        XCTAssertTrue(api.url.baseRequest.contentConverter is URLFormConverter)
//        XCTAssertTrue(api.url.baseResponse.contentConverter is URLFormConverter)
//    }
//}
