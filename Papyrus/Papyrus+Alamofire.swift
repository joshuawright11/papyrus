import Alamofire
import PapyrusCore

public typealias Interceptor = PapyrusCore.Interceptor
public typealias Request = PapyrusCore.Request

extension Provider {
    public convenience init(baseURL: String,
                            session: Session = Session.default,
                            modifiers: [RequestModifier] = [],
                            interceptors: [Interceptor] = []) {
        self.init(baseURL: baseURL, client: session, modifiers: modifiers, interceptors: interceptors)
    }
}

// MARK: `ProviderClient` Conformance

extension Session: ProviderClient {
    public func build(method: String, url: URL, headers: [String: String], body: Data?) -> Request {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.body = body
        request.allHTTPHeaderFields = headers
        return request
    }

    public func request(_ req: Request) async throws -> Response {
        await request(req.request).validate().serializingData().response
    }
}

// MARK: `Response` Conformance

extension DataResponse: Response {
    public var body: Data? { data }
    public var headers: [String : String]? { response?.headers.dictionary }
    public var statusCode: Int? { response?.statusCode }
    public var error: Error? {
        guard case .failure(let error) = result else { return nil }
        return error
    }
}

extension Response {
    public var response: HTTPURLResponse? { alamofire.response }
    public var request: URLRequest? { alamofire.request }
    public var alamofire: DataResponse<Data, AFError> {
        self as! DataResponse<Data, AFError>
    }
}

// MARK: `Request` Conformance

extension Request {
    public var request: URLRequest {
        self as! URLRequest
    }
}

extension URLRequest: Request {
    public var body: Data? {
        get { httpBody }
        set { httpBody = newValue }
    }

    public var method: String {
        get { httpMethod ?? "" }
        set { httpMethod = newValue }
    }

    public var headers: [String: String] {
        get { allHTTPHeaderFields ?? [:] }
        set { allHTTPHeaderFields = newValue }
    }
}
