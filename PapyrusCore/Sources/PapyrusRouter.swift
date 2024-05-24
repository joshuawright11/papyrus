import Foundation

public protocol PapyrusRouter {
    func register(
        method: String,
        path: String,
        action: @escaping (RouterRequest) async throws -> RouterResponse
    )
}

public struct RouterRequest {
    public let url: URL
    public let method: String
    public let headers: [String: String]
    public let body: Data?

    public init(url: URL, method: String, headers: [String : String], body: Data?) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
    }

    public func getQuery<L: LosslessStringConvertible>(_ name: String) throws -> L {
        guard let parameters = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            throw PapyrusError("unable to parse url components for url `\(url)`")
        }

        guard let item = parameters.queryItems?.first(where: { $0.name == name }) else {
            throw PapyrusError("no query item found for `\(name)`")
        }

        guard let string = item.value, let value = L(string) else {
            throw PapyrusError("query `\(item.name)` was not convertible to `\(L.self)`")
        }

        return value
    }

    public func getBody<D: Decodable>(_ type: D.Type) throws -> D {
        guard let body else {
            throw PapyrusError("expected request body")
        }

        let decoder = JSONDecoder()
        return try decoder.decode(type, from: body)
    }

    public func getHeader<L: LosslessStringConvertible>(_ name: String) throws -> L {
        guard let string = headers[name] else {
            throw PapyrusError("missing header `\(name)`")
        }

        guard let value = L(string) else {
            throw PapyrusError("header `\(name)` was not convertible to `\(L.self)`")
        }

        return value
    }

    public func getParameter<L: LosslessStringConvertible>(_ name: String, path: String) throws -> L {
        let templatePathComponents = path.components(separatedBy: "/")
        let requestPathComponents = url.pathComponents
        let parametersByName = [String: String](
            zip(templatePathComponents, requestPathComponents)
                .compactMap {
                    guard let parameter = $0.extractParameter else { return nil }
                    return (parameter, $1)
                },
            uniquingKeysWith: { a, _ in a }
        )

        guard let string = parametersByName[name] else {
            throw PapyrusError("parameter `\(name)` not found")
        }

        guard let value = L(string) else {
            throw PapyrusError("parameter `\(name)` was not convertible to `\(L.self)`")
        }

        return value
    }
}

public struct RouterResponse {
    public let status: Int
    public let headers: [String: String]
    public let body: Data?

    public init(_ status: Int, headers: [String: String] = [:], body: Data? = nil) {
        self.status = status
        self.headers = headers
        self.body = body
    }
}

extension String {
    fileprivate var extractParameter: String? {
        if hasPrefix(":") {
            String(dropFirst())
        } else if hasPrefix("{") && hasSuffix("}") {
            String(dropFirst().dropLast())
        } else {
            nil
        }
    }
}
