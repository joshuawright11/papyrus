enum Coders {

    // MARK: HTTP Body

    static var defaultHTTPBodyEncoder: HTTPBodyEncoder = .json()
    static var defaultHTTPBodyDecoder: HTTPBodyDecoder = .json()

    // MARK: Query

    static var defaultQueryEncoder = URLEncodedFormEncoder()
    static var defaultQueryDecoder = URLEncodedFormDecoder()
}
