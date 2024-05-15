import XCTest
@testable import PapyrusCore

final class ProviderTests: XCTestCase {
    func testProvider() {
        let provider = Provider(baseURL: "foo", http: TestHTTPService())
        let req = provider.newBuilder(method: "bar", path: "baz")
        XCTAssertEqual(req.baseURL, "foo")
        XCTAssertEqual(req.method, "bar")
        XCTAssertEqual(req.path, "baz")
    }
    
    func testRetryInterceptor() async {
        let retryInterceptor = RetryInterceptor(retryConditions: [{ _, response in
            guard let statusCode = response.statusCode else { return false }
            return statusCode == 500
        }])
        let provider = Provider(baseURL: "https://example.com", http: TestHTTPService(), retryInterceptor: retryInterceptor)
        let builder = provider.newBuilder(method: "GET", path: "/test")
        
        do {
            let response = try await provider.request(builder)
            XCTAssertEqual(response.statusCode, 200)
        } catch {
            XCTFail("Request should not fail")
        }
    }
}

private struct TestHTTPService: HTTPService {
    static var attempt = 0
    
    func build(method: String, url: URL, headers: [String : String], body: Data?) -> Request {
        fatalError()
    }
    
    func request(_ req: Request) async -> Response {
        // Simulate a retry scenario
        defer { attempt += 1 }
        
        if attempt < 2 {
            return _Response(request: req.urlRequest, response: nil, error: nil, body: nil, statusCode: 500)
        } else {
            return _Response(request: req.urlRequest, response: nil, error: nil, body: nil, statusCode: 200)
        }
    }
    
    func request(_ req: Request, completionHandler: @escaping (Response) -> Void) {

    }
}

private struct _Response: Response {
    let urlRequest: URLRequest
    let urlResponse: URLResponse?
    let error: Error?
    let body: Data?
    let headers: [String : String]?
    let statusCode: Int?
    
    init(request: URLRequest, response: URLResponse?, error: Error?, body: Data?, statusCode: Int?) {
        self.urlRequest = request
        self.urlResponse = response
        self.error = error
        self.body = body
        self.headers = nil
        self.statusCode = statusCode
    }
}
