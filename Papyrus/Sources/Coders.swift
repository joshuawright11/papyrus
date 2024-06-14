enum Coders {

    // MARK: HTTP Body

    static let defaultHTTPBodyEncoder: HTTPBodyEncoder = .json()
    static let defaultHTTPBodyDecoder: HTTPBodyDecoder = .json()

    // MARK: Query

    static let defaultQueryEncoder = URLEncodedFormEncoder()
    static let defaultQueryDecoder = URLEncodedFormDecoder()
}
