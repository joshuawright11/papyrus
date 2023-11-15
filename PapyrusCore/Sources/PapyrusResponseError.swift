/// A Papyrus response related error.
public class PapyrusResponseError: PapyrusError {
    /// Failed response.
    public let response: Response
    
    /// Create an error with the specified message and failed response.
    ///
    /// - Parameter message: What went wrong.
    /// - Parameter response: Failed response.
    public init(_ message: String, _ response: Response) {
        self.response = response
        super.init(message)
    }
}
