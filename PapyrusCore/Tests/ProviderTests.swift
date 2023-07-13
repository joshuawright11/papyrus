@testable import PapyrusCore
import XCTest

final class ProviderTests: XCTestCase {
    func testProvider() {
        let provider = Provider(baseURL: "foo", http: TestHTTPService())
        let req = provider.newBuilder(method: "bar", path: "baz")
        XCTAssertEqual(req.baseURL, "foo")
        XCTAssertEqual(req.method, "bar")
        XCTAssertEqual(req.path, "baz")
    }
}

private struct TestHTTPService: HTTPService {
    func build(method _: String, url _: URL, headers _: [String: String], body _: Data?) -> Request {
        fatalError()
    }

    func request(_: Request) async -> Response {
        fatalError()
    }

    func request(_: Request, completionHandler _: @escaping (Response) -> Void) {}
}
