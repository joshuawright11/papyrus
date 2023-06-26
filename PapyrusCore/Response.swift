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

extension Response where Self == ErrorResponse {
    public static func error(_ error: Error) -> Response {
        ErrorResponse(error)
    }
}

public struct ErrorResponse: Response {
    let _error: Error?

    public init(_ error: Error) {
        self._error = error
    }

    public var body: Data? { nil }
    public var headers: [String : String]? { nil }
    public var statusCode: Int? { nil }
    public var error: Error? { _error }
}
