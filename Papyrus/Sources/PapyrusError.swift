/// A Papyrus related error.
public struct PapyrusError: Error, CustomDebugStringConvertible {
    /// What went wrong.
    public let message: String
    /// Error related request.
    public let request: (any PapyrusRequest)?
    /// Error related response.
    public let response: (any PapyrusResponse)?

    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    /// - Parameter request: Error related request.
    /// - Parameter response: Error related response.
    public init(_ message: String, _ request: (any PapyrusRequest)? = nil, _ response: (any PapyrusResponse)? = nil) {
        self.message = message
        self.request = request
        self.response = response
    }

    // MARK: CustomDebugStringConvertible

    public var debugDescription: String {
        "PapyrusError: \(message)"
    }
}
