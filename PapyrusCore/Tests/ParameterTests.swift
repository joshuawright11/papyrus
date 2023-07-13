@testable import PapyrusCore
import XCTest

final class ParameterTests: XCTestCase {
    func testPath() {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "bar/:baz")
        req.addParameter("baz", value: "value")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/bar/value")
    }

    func testPathPrefix() {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "bar/:bazzar")
        req.addParameter("baz", value: "value")
        XCTAssertThrowsError(try req.fullURL().absoluteString, "foo/bar/value")
    }

    func testPathCommonPrefix() {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "bar/:part/:partTwo")
        req.addParameter("part", value: "valueOne")
        req.addParameter("partTwo", value: "valueTwo")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/bar/valueOne/valueTwo")
    }
}
