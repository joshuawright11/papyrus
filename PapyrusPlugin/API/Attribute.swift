import SwiftSyntax

enum Attribute {
    /// Type or Function attributes
    case json(value: String)
    case urlForm(value: String)
    case converter(value: String)
    case keyMapping(value: String)
    case headers(value: String)

    /// Function attributes
    case http(method: String, path: String)

    /// Parameter attributes
    case body(key: String?)
    case field(key: String?)
    case query(key: String?)
    case header(key: String?)
    case path(key: String?)
    case `default`(value: String)

    init?(syntax: AttributeSyntax) {
        var firstArgument: String?
        var secondArgument: String?
        if case let .argumentList(list) = syntax.argument {
            firstArgument = list.first?.expression.description
            secondArgument = list.dropFirst().first?.expression.description
        }

        let name = syntax.attributeName.trimmedDescription
        switch name {
        case "GET2", "DELETE2", "PATCH2", "POST2", "PUT2", "OPTIONS2", "HEAD2", "TRACE2", "CONNECT2":
            guard let firstArgument else { return nil }
            self = .http(method: name, path: firstArgument)
        case "Http":
            guard let firstArgument, let secondArgument else { return nil }
            self = .http(method: secondArgument.withoutQuotes, path: firstArgument)
        case "Body2":
            self = .body(key: firstArgument?.withoutQuotes)
        case "Field2":
            self = .field(key: firstArgument?.withoutQuotes)
        case "Query2":
            self = .query(key: firstArgument?.withoutQuotes)
        case "Header2":
            self = .header(key: firstArgument?.withoutQuotes)
        case "Path2":
            self = .path(key: firstArgument?.withoutQuotes)
        case "Default":
            guard let firstArgument else { return nil }
            self = .`default`(value: firstArgument)
        case "Headers":
            guard let firstArgument else { return nil }
            self = .headers(value: firstArgument)
        case "JSON2":
            self = .json(value: firstArgument ?? ".json")
        case "URLForm2":
            self = .urlForm(value: firstArgument ?? ".urlForm")
        case "Converter":
            guard let firstArgument else { return nil }
            self = .converter(value: firstArgument)
        case "KeyMapping":
            guard let firstArgument else { return nil }
            self = .keyMapping(value: firstArgument)
        default:
            return nil
        }
    }

    func requestStatement(input: String?) -> String? {
        switch self {
        case let .body(key):
            guard let input else { return "Input Required!" }
            return """
            req.addBody("\(key ?? input)", value: \(input))
            """
        case let .query(key):
            guard let input else { return "Input Required!" }
            return """
            req.addQuery("\(key ?? input)", value: \(input))
            """
        case let .header(key):
            guard let input else { return "Input Required!" }
            return """
            req.addHeader("\(key ?? input)", value: \(input))
            """
        case let .path(key):
            guard let input else { return "Input Required!" }
            return """
            req.addParameter("\(key ?? input)", value: \(input))
            """
        case let .field(key):
            guard let input else { return "Input Required!" }
            return """
            req.addField("\(key ?? input)", value: \(input))
            """
        case .json(let value), .urlForm(let value), .converter(let value):
            return """
            req.preferredContentConverter = \(value)
            """
        case .headers(let value):
            return """
            req.addHeaders(\(value))
            """
        case .keyMapping(let value):
            return """
            req.preferredKeyMapping = \(value)
            """
        default:
            return nil
        }
    }
}

extension String {
    fileprivate var withoutQuotes: String {
        filter { $0 != "\"" }
    }
}
