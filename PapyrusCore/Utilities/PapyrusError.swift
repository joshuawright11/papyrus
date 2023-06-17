import Foundation

/// A Papyrus related error.
public struct PapyrusError: Error {
    /// What went wrong.
    public let message: String
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    public init(_ message: String) {
        self.message = message
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
