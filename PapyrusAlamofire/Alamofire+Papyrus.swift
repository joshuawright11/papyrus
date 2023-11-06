@_exported import Alamofire
@_exported import Foundation
@_exported import PapyrusCore

extension Provider {
    public convenience init(baseURL: String,
                            session: Session = .default,
                            modifiers: [RequestModifier] = [],
                            interceptors: [PapyrusCore.Interceptor] = []) {
        self.init(baseURL: baseURL, http: session, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `HTTPService` Conformance

extension Session: HTTPService {
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> PapyrusCore.Request {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.allHTTPHeaderFields = headers
        return _Request(request: request)
    }

    public func request(_ req: PapyrusCore.Request) async -> Response {
        await request(req.urlRequest).serializingData().response
    }

    public func request(_ req: PapyrusCore.Request, completionHandler: @escaping (Response) -> Void) {
        request(req.urlRequest).response(completionHandler: completionHandler)
    }
}

// MARK: `Response` Conformance

extension Response {
    public var urlRequest: URLRequest? { alamofire.request }
    public var urlResponse: HTTPURLResponse? { alamofire.response }
    public var alamofire: DataResponse<Data, AFError> {
        self as! DataResponse<Data, AFError>
    }
}

extension DataResponse: Response {
    public var body: Data? { data }
    public var headers: [String : String]? { response?.headers.dictionary }
    public var statusCode: Int? { response?.statusCode }
    public var error: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }
}

// MARK: `Request` Conformance

extension PapyrusCore.Request {
    public var urlRequest: URLRequest {
        (self as! _Request).request
    }
}

private struct _Request: PapyrusCore.Request {
    var request: URLRequest

    public var url: URL {
        get { request.url! }
        set { request.url = newValue }
    }

    public var body: Data? {
        get { request.httpBody }
        set { request.httpBody = newValue }
    }

    public var method: String {
        get { request.httpMethod ?? "" }
        set { request.httpMethod = newValue }
    }

    public var headers: [String: String] {
        get { request.allHTTPHeaderFields ?? [:] }
        set { request.allHTTPHeaderFields = newValue }
    }
}
