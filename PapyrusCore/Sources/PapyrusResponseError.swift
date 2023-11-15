/// A Papyrus response related error.
public class PapyrusResponseError: PapyrusError {
    /// Failed response.
    public let response: Response
    
    /// Create an error with the specified message.
    ///
    /// - Parameter message: What went wrong.
    /// - Parameter response: Failed response.
    public init(_ message: String, _ response: Response) {
        self.response = response
        super.init(message)
    }
}
