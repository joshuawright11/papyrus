import Foundation

/// A type that can perform arbitrary HTTP requests.
public protocol HTTPService {
    /// Build a `Request` from the given components.
    func build(method: String, url: URL, headers: [String: String], body: Data?) -> PapyrusRequest

    /// Concurrency based API
    func request(_ req: PapyrusRequest) async -> PapyrusResponse
}
