/// A type from which a `RequestConvertible` can be decoded. Conform your
/// server's Request type to this for easy validation against a
/// `RequestConvertible` type.
public protocol DecodableRequest {
    /// Get a header for a given key.
    ///
    /// - Parameter key: The key of the header.
    /// - Returns: The value of the header for the given key, if it
    ///   exists.
    func header(_ key: String) -> String?
    
    /// Get a url query value for a given key.
    ///
    /// - Parameter key: The key of the query.
    /// - Returns: The value of the query for the given key, if it
    ///   exists.
    func query(_ key: String) -> String?
    
    /// Get a path parameter for a given key.
    ///
    /// - Parameter key: The key of the path parameter.
    /// - Returns: The value of the path parameter for the given key,
    ///   if it exists.
    func parameter(_ key: String) -> String?
    
    /// Decode the content of a request as the given content type.
    ///
    /// - Warning: Only JSON decoding is currently supported.
    ///
    /// - Throws: Any error thrown decoding the request body to `T`.
    /// - Returns: An instance of `T`, decoded from this request's
    ///   body.
    func decodeContent<T: Decodable>(type: ContentType) throws -> T
}
