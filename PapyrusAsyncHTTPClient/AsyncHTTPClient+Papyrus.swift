import AsyncHTTPClient
import NIOHTTP1
import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .createNew),
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = []) {
        self.init(baseURL: baseURL, http: httpClient, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `ProviderClient` Conformance

extension HTTPClient: HTTPService {
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> PapyrusCore.Request {
        RequestProxy(method: method, url: url, headers: headers, body: body)
    }

    public func request(_ req: PapyrusCore.Request) async -> PapyrusCore.Response {
        do {
            let res = try await execute(request: req.request).get()
            guard res.status.isSuccessful else {
                return ResponseProxy(response: res, error: .unsuccessfulStatus(res.status))
            }

            return ResponseProxy(response: res, error: nil)
        } catch {
            return ResponseProxy(response: nil, error: error)
        }
    }

    public func request(_ req: PapyrusCore.Request, completionHandler: @escaping (PapyrusCore.Response) -> Void) {
        execute(request: req.request)
            .whenComplete { result in
                switch result {
                case .success(let res):
                    guard res.status.isSuccessful else {
                        let res = ResponseProxy(response: res, error: .unsuccessfulStatus(res.status))
                        completionHandler(res)
                        return
                    }

                    completionHandler(ResponseProxy(response: res, error: nil))
                case .failure(let error):
                    completionHandler(ResponseProxy(response: nil, error: error))
                }
            }
    }
}

// MARK: `Response` Conformance

private struct ResponseProxy: Response {
    let response: HTTPClient.Response?
    let error: Error?
    var body: Data? { response?.body.map { Data(buffer: $0) } }
    var headers: [String: String]? { response?.headers.dict }
    var statusCode: Int? { response.map { Int($0.status.code) } }
}

extension Response {
    public var response: HTTPClient.Response? {
        (self as! ResponseProxy).response
    }
}

// MARK: `Request` Conformance

private struct RequestProxy: Request {
    var request: HTTPClient.Request {
        let method = HTTPMethod(rawValue: method)
        let body = body.map { HTTPClient.Body.data($0) }
        var headers = HTTPHeaders()
        for (key, value) in headers {
            headers.add(name: key, value: value)
        }

        return try! HTTPClient.Request(url: url.absoluteString,
                                       method: method,
                                       headers: headers,
                                       body: body)
    }

    var method: String
    var url: URL
    var headers: [String : String]
    var body: Data?
}

extension Request {
    public var request: HTTPClient.Request {
        (self as! RequestProxy).request
    }
}

// MARK: Utilities

extension HTTPHeaders {
    fileprivate var dict: [String: String] {
        var dict: [String: String] = [:]
        for (name, value) in self {
            dict[name] = value
        }

        return dict
    }
}

extension HTTPResponseStatus {
    fileprivate var isSuccessful: Bool {
        (200..<300).contains(code)
    }
}

extension Error where Self == PapyrusError {
    fileprivate static func unsuccessfulStatus(_ status: HTTPResponseStatus) -> PapyrusError {
        PapyrusError("Status code was unsuccessful: \(status.code).")
    }
}
