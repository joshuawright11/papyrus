import XCTest
@testable import Papyrus

final class RequestBuilderTests: XCTestCase {
    func testPath() throws {
        let req = RequestBuilder(baseURL: "foo/", method: "bar", path: "baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testPathNoTrailingSlash() throws {
        let req = RequestBuilder(baseURL: "foo", method: "bar", path: "/baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testPathDoubleSlash() throws {
        let req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        XCTAssertEqual(try req.fullURL().absoluteString, "foo/baz")
    }

    func testMultipart() throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = MultipartEncoder(boundary: UUID().uuidString)
        req.requestBodyEncoder = encoder
        req.addField("a", value: Part(data: Data("one".utf8), fileName: "one.txt", mimeType: "text/plain"))
        req.addField("b", value: Part(data: Data("two".utf8)))
        let (body, headers) = try req.bodyAndHeaders()
        guard let body else {
            XCTFail()
            return
        }

        // 0. Assert Headers

        XCTAssertEqual(headers, [
            "Content-Type": "multipart/form-data; boundary=\(encoder.boundary)",
            "Content-Length": "266"
        ])

        // 1. Assert Body

        XCTAssertEqual(body.string, """
            --\(encoder.boundary)\r
            Content-Disposition: form-data; name="a"; filename="one.txt"\r
            Content-Type: text/plain\r
            \r
            one\r
            --\(encoder.boundary)\r
            Content-Disposition: form-data; name="b"\r
            \r
            two\r
            --\(encoder.boundary)--\r

            """
        )
    }

    func testJSON() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        req.requestBodyEncoder = encoder
        req.addField("a", value: "one")
        req.addField("b", value: "two")
        let (body, headers) = try req.bodyAndHeaders()
        guard let body else {
            XCTFail()
            return
        }

        // 0. Assert Headers

        XCTAssertEqual(headers, [
            "Content-Type": "application/json",
            "Content-Length": "32"
        ])

        // 1. Assert Body

        XCTAssertEqual(body.string, """
            {
              "a" : "one",
              "b" : "two"
            }
            """
        )
    }

    func testURLForm() async throws {
        var req = RequestBuilder(baseURL: "foo/", method: "bar", path: "/baz")
        req.requestBodyEncoder = URLEncodedFormEncoder()
        req.addField("a", value: "one")
        req.addField("b", value: "two")
        let (body, headers) = try req.bodyAndHeaders()
        guard let body else {
            XCTFail()
            return
        }

        // 0. Assert Headers

        XCTAssertEqual(headers, [
            "Content-Type": "application/x-www-form-urlencoded",
            "Content-Length": "11"
        ])

        // 1. Assert Body
        XCTAssertTrue(["a=one&b=two", "b=two&a=one"].contains(body.string))
    }
}

extension Data {
    fileprivate var string: String {
        String(decoding: self, as: UTF8.self)
    }
}
