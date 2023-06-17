import Foundation

public protocol ProviderClient {
    func build(method: String, url: URL, headers: [String: String], body: Data?) -> Request
    func request(_ req: Request) async throws -> Response
}
