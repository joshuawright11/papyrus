public protocol CoderProvider: Sendable {
    func provideHttpBodyEncoder() -> any HTTPBodyEncoder
    func provideHttpBodyDecoder() -> any HTTPBodyDecoder
    func provideQueryEncoder() -> URLEncodedFormEncoder
    func provideQueryDecoder() -> URLEncodedFormDecoder
}

public struct DefaultProvider: CoderProvider {
    public init() {}

    public func provideHttpBodyEncoder() -> any HTTPBodyEncoder {
        return .json()
    }

    public func provideHttpBodyDecoder() -> any HTTPBodyDecoder {
        return .json()
    }

    public func provideQueryEncoder() -> URLEncodedFormEncoder {
        return URLEncodedFormEncoder()
    }

    public func provideQueryDecoder() -> URLEncodedFormDecoder {
        return URLEncodedFormDecoder()
    }
}
