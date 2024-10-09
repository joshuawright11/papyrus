public protocol CoderProvider: Sendable {
    func provideHttpBodyEncoder() -> HTTPBodyEncoder
    func provideHttpBodyDecoder() -> HTTPBodyDecoder
    func provideQueryEncoder() -> URLEncodedFormEncoder
    func provideQueryDecoder() -> URLEncodedFormDecoder
}

public struct DefaultProvider: CoderProvider {
    public init() {}

    public func provideHttpBodyEncoder() -> HTTPBodyEncoder {
        return .json()
    }

    public func provideHttpBodyDecoder() -> HTTPBodyDecoder {
        return .json()
    }

    public func provideQueryEncoder() -> URLEncodedFormEncoder {
        return URLEncodedFormEncoder()
    }

    public func provideQueryDecoder() -> URLEncodedFormDecoder {
        return URLEncodedFormDecoder()
    }
}
