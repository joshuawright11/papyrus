/// A Papyrus related error.
public struct PapyrusError: Error, CustomDebugStringConvertible {
    /// What went wrong.
    public let message: String
    /// Error related request.
    public let request: Request?
    /// Error related response.
    public let response: Response?
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    /// - Parameter request: Error related request.
    /// - Parameter response: Error related response.
    public init(_ message: String, _ request: Request? = nil, _ response: Response? = nil) {
        self.message = message
        self.request = request
        self.response = response
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        "PapyrusError: \(message)"
    }
}
