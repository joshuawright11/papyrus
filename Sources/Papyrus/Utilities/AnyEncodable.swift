/// An erased `Encodable`.
public struct AnyEncodable: Encodable {
    /// Closure for encoding, erasing the type of the instance this
    /// class was instantiated with.
    private let _encode: (Encoder) throws -> Void
    
    /// Initialize with a generic `Encodable` instance.
    ///
    /// - Parameter wrapped: An instance of `Encodable`.
    public init<T: Encodable>(_ wrapped: T) {
        _encode = wrapped.encode
    }
    
    // MARK: Encodable
    
    public func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
