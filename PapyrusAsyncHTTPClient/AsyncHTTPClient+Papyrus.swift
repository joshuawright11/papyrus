import AsyncHTTPClient
import NIOHTTP1
import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            httpClient: HTTPClient = HTTPClient(eventLoopGroupProvider: .createNew),
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = []) {
        self.init(baseURL: baseURL, client: httpClient, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `ProviderClient` Conformance

extension HTTPClient: ProviderClient {
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> PapyrusCore.Request {
        let method = HTTPMethod(rawValue: method)
        let body = body.map { HTTPClient.Body.data($0) }
        var headers = HTTPHeaders()
        for (key, value) in headers {
            headers.add(name: key, value: value)
        }

        let req = try! HTTPClient.Request(url: url.absoluteString,
                                          method: method,
                                          headers: headers,
                                          body: body)
        return HTTPClientRequest(request: req)
    }

    public func request(_ req: PapyrusCore.Request) async -> PapyrusCore.Response {
        do {
            let res = try await execute(request: req.request).get()
            guard res.status.isSuccessful else {
                return HTTPClientResponse(response: res, error: .unsuccessfulStatus(res.status))
            }

            return HTTPClientResponse(response: res, error: nil)
        } catch {
            return HTTPClientResponse(response: nil, error: error)
        }
    }

    public func request(_ req: PapyrusCore.Request, completionHandler: @escaping (PapyrusCore.Response) -> Void) {
        execute(request: req.request)
            .whenComplete { result in
                switch result {
                case .success(let res):
                    guard res.status.isSuccessful else {
                        let res = HTTPClientResponse(response: res, error: .unsuccessfulStatus(res.status))
                        completionHandler(res)
                        return
                    }

                    completionHandler(HTTPClientResponse(response: res, error: nil))
                case .failure(let error):
                    completionHandler(HTTPClientResponse(response: nil, error: error))
                }
            }
    }
}

// MARK: `Response` Conformance

struct HTTPClientResponse: Response {
    let response: HTTPClient.Response?
    let error: Error?

    var body: Data? { response?.body.map { Data(buffer: $0) } }
    var headers: [String: String]? { response?.headers.dict }
    var statusCode: Int? { response.map { Int($0.status.code) } }
}

extension Response {
    public var response: HTTPClient.Response? {
        (self as! HTTPClientResponse).response
    }
}

// MARK: `Request` Conformance

struct HTTPClientRequest: Request {
    var request: HTTPClient.Request

    var url: URL? {
        get { request.url }
        set { fatalError() }
    }

    var method: String {
        get { request.method.rawValue }
        set { fatalError() }
    }

    var headers: [String : String] {
        get { request.headers.dict }
        set {
            request.headers = HTTPHeaders()
            request.headers.add(contentsOf: newValue.map { ($0, $1) })
        }
    }
    var body: Data? {
        get {
            // TODO: Figure out how to give access to data.
            nil
        }
        set { request.body = newValue.map { .data($0) }}
    }
}

extension Request {
    public var request: HTTPClient.Request {
        (self as! HTTPClientRequest).request
    }
}

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
