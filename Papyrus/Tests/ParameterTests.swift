import XCTest
@testable import Papyrus

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
    
    func testPathWithStaticQuery() {
        var req = RequestBuilder(baseURL: "foo/", method: "GET", path: "bar/:baz?query=1")
        req.addParameter("baz", value: "value")

        XCTAssertEqual(try req.fullURL().absoluteString, "foo/bar/value?query=1")


        var reqWithTermination = RequestBuilder(baseURL: "foo/", method: "GET", path: "bar/:baz/?query=1")
        reqWithTermination.addParameter("baz", value: "value")

        XCTAssertEqual(try reqWithTermination.fullURL().absoluteString, "foo/bar/value/?query=1")
    }
}
