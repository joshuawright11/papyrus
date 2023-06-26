import Foundation

/// A type that can perform arbitrary HTTP requests.
public protocol HTTPService {
    /// Build a `Request` from the given components.
    func build(method: String, url: URL, headers: [String: String], body: Data?) -> Request

    /// Concurrency based API
    func request(_ req: Request) async -> Response

    /// Callback based API
    func request(_ req: Request, completionHandler: @escaping (Response) -> Void)
}
