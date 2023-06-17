import Foundation

public protocol Response {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension Response {
    @discardableResult
    public func validate() throws -> Self {
        guard let error else {
            return self
        }

        throw error
    }
}
