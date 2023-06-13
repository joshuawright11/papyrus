import Alamofire
import Foundation

/*
 GOALS
 1. Escape hatches to underlying types
    - alter underlying request
    - inspect underlying response on success
    - inspect underlying response on error
    - cancel in flight request
 2. Allow for usage on server.
    - don't be tightly coupled to Alamofire or URLSession

 Escape hatch.
 */

/// Makes URL requests.
public struct Provider: HTTPProvider {
    let baseURL: String
    let session: Session

    public init(baseURL: String, session: Session = .default, interceptors: [() -> Void] = []) {
        self.baseURL = baseURL
        self.session = session
    }

    @discardableResult
    public func request(_ request: Request) async throws -> Response {
        let req = try request.createURLRequest(baseURL: baseURL)
        return await session.request(req).validate().serializingData().response
    }
}

public protocol HTTPProvider {
    @discardableResult
    func request(_ request: Request) async throws -> Response
}

extension Request {
    func createURLRequest(baseURL: String) throws -> URLRequest {
        let url = try fullURL(baseURL: baseURL).asURL()
        let (body, headers) = try bodyAndHeaders()
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.allHTTPHeaderFields = headers
        request.httpBody = body
        return request
    }
}
