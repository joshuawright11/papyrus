import SwiftSyntax

enum Attribute {
    /// Type or Function attributes
    case json(encoder: String, decoder: String)
    case urlForm(value: String)
    case converter(encoder: String, decoder: String)
    case keyMapping(value: String)
    case headers(value: String)
    case authorization(value: String)

    /// Function attributes
    case http(method: String, path: String)

    /// Parameter attributes
    case body
    case field(key: String?)
    case query(key: String?)
    case header(key: String?)
    case path(key: String?)

    init?(syntax: AttributeSyntax) {
        var firstArgument: String?
        var secondArgument: String?
        if case let .argumentList(list) = syntax.argument {
            firstArgument = list.first?.expression.description
            secondArgument = list.dropFirst().first?.expression.description
        }

        let name = syntax.attributeName.trimmedDescription
        switch name {
        case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
            guard let firstArgument else { return nil }
            self = .http(method: name, path: firstArgument)
        case "HTTP":
            guard let firstArgument, let secondArgument else { return nil }
            self = .http(method: secondArgument.withoutQuotes, path: firstArgument)
        case "Body":
            self = .body
        case "Field":
            self = .field(key: firstArgument?.withoutQuotes)
        case "Query":
            self = .query(key: firstArgument?.withoutQuotes)
        case "Header":
            self = .header(key: firstArgument?.withoutQuotes)
        case "Path":
            self = .path(key: firstArgument?.withoutQuotes)
        case "Headers":
            guard let firstArgument else { return nil }
            self = .headers(value: firstArgument)
        case "JSON":
            self = .json(
                encoder: firstArgument ?? "JSONEncoder()",
                decoder: secondArgument ?? "JSONDecoder()"
            )
        case "URLForm":
            self = .urlForm(value: firstArgument ?? "URLEncodedFormEncoder()")
        case "Coder":
            guard let firstArgument, let secondArgument else { return nil }
            self = .converter(encoder: firstArgument, decoder: secondArgument)
        case "KeyMapping":
            guard let firstArgument else { return nil }
            self = .keyMapping(value: firstArgument)
        case "Authorization":
            guard let firstArgument else { return nil }
            self = .authorization(value: firstArgument)
        default:
            return nil
        }
    }

    func requestStatement(input: String?) -> String? {
        switch self {
        case .body:
            guard let input else { return "Input Required!" }
            return """
            req.setBody(\(input))
            """
        case let .query(key):
            guard let input else { return "Input Required!" }
            let mapParameter = key == nil ? "" : ", mapKey: false"
            return """
            req.addQuery("\(key ?? input)", value: \(input)\(mapParameter))
            """
        case let .header(key):
            guard let input else { return "Input Required!" }
            let hasCustomKey = key == nil
            let convertParameter = hasCustomKey ? "" : ", convertToHeaderCase: true"
            return """
            req.addHeader("\(key ?? input)", value: \(input)\(convertParameter))
            """
        case let .path(key):
            guard let input else { return "Input Required!" }
            return """
            req.addParameter("\(key ?? input)", value: \(input))
            """
        case let .field(key):
            guard let input else { return "Input Required!" }
            let mapParameter = key == nil ? "" : ", mapKey: false"
            return """
            req.addField("\(key ?? input)", value: \(input)\(mapParameter))
            """
        case .json(let encoder, let decoder):
            return """
            req.requestEncoder = \(encoder)
            req.responseDecoder = \(decoder)
            """
        case .urlForm(let value):
            return """
            req.requestEncoder = \(value)
            """
        case .converter(let encoder, let decoder):
            return """
            req.requestEncoder = \(encoder)
            req.responseDecoder = \(decoder)
            """
        case .headers(let value):
            return """
            req.addHeaders(\(value))
            """
        case .keyMapping(let value):
            return """
            req.keyMapping = \(value)
            """
        case .authorization(value: let value):
            return """
            req.addAuthorization(\(value))
            """
        case .http:
            return nil
        }
    }
}

extension String {
    fileprivate var withoutQuotes: String {
        filter { $0 != "\"" }
    }
}
