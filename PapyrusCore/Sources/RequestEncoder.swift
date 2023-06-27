import Foundation

public protocol RequestEncoder: KeyMappable {
    var contentType: String { get }
    func encode<E: Encodable>(_ value: E) throws -> Data
}

// MARK: application/json

extension RequestEncoder where Self == JSONEncoder {
    public static func json(_ encoder: JSONEncoder) -> Self {
        encoder
    }
}

extension JSONEncoder: RequestEncoder {
    public var contentType: String { "application/json" }

    public func with(keyMapping: KeyMapping) -> Self {
        let new = JSONEncoder()
        new.userInfo = userInfo
        new.dataEncodingStrategy = dataEncodingStrategy
        new.dateEncodingStrategy = dateEncodingStrategy
        new.nonConformingFloatEncodingStrategy = nonConformingFloatEncodingStrategy
        new.outputFormatting = outputFormatting
        new.keyEncodingStrategy = keyMapping.jsonEncodingStrategy
        return new as! Self
    }
}

// MARK: application/x-www-form-urlencoded

extension RequestEncoder where Self == URLEncodedFormEncoder {
    public static func urlForm(_ encoder: URLEncodedFormEncoder) -> Self {
        encoder
    }
}

extension URLEncodedFormEncoder: RequestEncoder {
    public var contentType: String { "application/x-www-form-urlencoded" }

    public func encode<E: Encodable>(_ value: E) throws -> Data {
        let string: String = try encode(value)
        guard let data = string.data(using: .utf8) else {
            throw PapyrusError("URLEncoded string wasn't convertible to utf8 data.")
        }

        return data
    }

    public func with(keyMapping: KeyMapping) -> Self {
        var copy = self
        copy.keyMapping = keyMapping
        return copy
    }
}

// MARK: multipart/form-data

extension RequestEncoder where Self == MultipartEncoder {
    public static func multipart(_ encoder: MultipartEncoder) -> Self {
        encoder
    }
}
