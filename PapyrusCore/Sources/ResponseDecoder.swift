import Foundation

public protocol ResponseDecoder: KeyMappable {
    func decode<D: Decodable>(_ type: D.Type, from: Data) throws -> D
}

// MARK: application/json

extension ResponseDecoder where Self == JSONDecoder {
    public static func json(_ decoder: JSONDecoder) -> Self {
        decoder
    }
}

extension JSONDecoder: ResponseDecoder {
    public func with(keyMapping: KeyMapping) -> Self {
        let new = JSONDecoder()
        new.userInfo = userInfo
        new.dataDecodingStrategy = dataDecodingStrategy
        new.dateDecodingStrategy = dateDecodingStrategy
        new.nonConformingFloatDecodingStrategy = nonConformingFloatDecodingStrategy
#if os(Linux)
#else
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            new.assumesTopLevelDictionary = assumesTopLevelDictionary
            new.allowsJSON5 = allowsJSON5
        }
#endif
        new.keyDecodingStrategy = keyMapping.jsonDecodingStrategy
        return new as! Self
    }
}
