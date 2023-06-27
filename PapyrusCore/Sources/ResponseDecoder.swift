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
        if #available(iOS 15.0, macOS 12.0, *) {
            new.assumesTopLevelDictionary = assumesTopLevelDictionary
            new.allowsJSON5 = allowsJSON5
        }
#endif
        new.keyDecodingStrategy = keyMapping.jsonDecodingStrategy
        return new as! Self
    }
}

// MARK: JSONEncoder + KeyMapping

extension KeyMapping {
    struct GenericCodingKey: CodingKey {
        var stringValue: String
        var intValue: Int?

        init(_ string: String) {
            self.stringValue = string
        }

        init?(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            return nil
        }
    }

    public var jsonDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        switch self {
        case .snakeCase:
            return .convertFromSnakeCase
        case .useDefaultKeys:
            return .useDefaultKeys
        case .custom(_, let fromMapper):
            return .custom { keys in
                guard let last = keys.last else {
                    return GenericCodingKey("")
                }

                return GenericCodingKey(fromMapper(last.stringValue))
            }
        }
    }
}
