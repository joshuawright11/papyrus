import Foundation

/// A type that can perform arbitrary HTTP requests.
public protocol HTTPService: Sendable {
    /// Build a `Request` from the given components.
    func build(method: String, url: URL, headers: [String: String], body: Data?) -> any PapyrusRequest

    /// Concurrency based API
    @Sendable
    func request(_ req: any PapyrusRequest) async -> any PapyrusResponse
}
