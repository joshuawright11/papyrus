import XCTest
@testable import Papyrus

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
    func build(method: String, url: URL, headers: [String : String], body: Data?) -> Request {
        fatalError()
    }
    
    func request(_ req: Request) async -> Response {
        fatalError()
    }
    
    func request(_ req: Request, completionHandler: @escaping (Response) -> Void) {

    }
}
