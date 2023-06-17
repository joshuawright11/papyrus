import Foundation

public protocol Response {
    var body: Data? { get }
    var headers: [String: String]? { get }
    var statusCode: Int? { get }
    var error: Error? { get }
}

extension Response {
    public func validate() throws {
        if let error = error {
            throw error
        }
    }
}
