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
    func build(method: String, url: URL, headers: [String : String], body: Data?) -> PapyrusRequest {
        fatalError()
    }
    
    func request(_ req: PapyrusRequest) async -> PapyrusResponse {
        fatalError()
    }
    
    func request(_ req: PapyrusRequest, completionHandler: @escaping (PapyrusResponse) -> Void) {

    }
}
