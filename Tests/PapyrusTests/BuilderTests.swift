import XCTest
@testable import Papyrus

final class BuilderTests: XCTestCase {
    private let api = TestAPI()
    
    func testMultipleBuilders() throws {
        let payload = try api.stacked.rawRequest()
        XCTAssertTrue(api.stacked.baseResponse.contentConverter is URLFormConverter)
        XCTAssertEqual(payload.method, "PUT")
        XCTAssertEqual(payload.headers["foo"], "bar")
        XCTAssertEqual(payload.headers["one"], "1")
        XCTAssertEqual(payload.headers["two"], "2")
        XCTAssertEqual(payload.headers["three"], "3")
        XCTAssertEqual(payload.headers["four"], "4")
        XCTAssertEqual(payload.headers["five"], "5")
        XCTAssertTrue(payload.path.hasPrefix("/body"))
    }
    
    func testConverterOverride() throws {
        XCTAssertTrue(api.override.baseResponse.contentConverter is JSONConverter)
    }
    
    func testMethods() throws {
        XCTAssertEqual(try api.delete.rawRequest().method, "DELETE")
        XCTAssertEqual(try api.get.rawRequest().method, "GET")
        XCTAssertEqual(try api.patch.rawRequest().method, "PATCH")
        XCTAssertEqual(try api.post.rawRequest().method, "POST")
        XCTAssertEqual(try api.options.rawRequest().method, "OPTIONS")
        XCTAssertEqual(try api.trace.rawRequest().method, "TRACE")
        XCTAssertEqual(try api.connect.rawRequest().method, "CONNECT")
        XCTAssertEqual(try api.head.rawRequest().method, "HEAD")
    }
}
