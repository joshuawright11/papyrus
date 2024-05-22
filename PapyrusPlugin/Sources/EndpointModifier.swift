import SwiftSyntax

/// To be parsed from protocol and function attributes. Modifies requests /
/// responses in some way.
enum EndpointModifier {
    /// Type or Function attributes
    case json(encoder: String, decoder: String)
    case urlForm(encoder: String)
    case multipart(encoder: String)
    case converter(encoder: String, decoder: String)
    case keyMapping(value: String)
    case headers(value: String)
    case authorization(value: String)

    /// Function attributes
    case http(method: String, path: String)

    init?(_ syntax: AttributeSyntax) {
        var firstArgument: String?
        var secondArgument: String?
        var labeledArguments: [String: String] = [:]
        if case let .argumentList(list) = syntax.arguments {
            for argument in list {
                if let label = argument.label {
                    labeledArguments[label.text] = argument.expression.description
                }
            }

            firstArgument = list.first?.expression.description
            secondArgument = list.dropFirst().first?.expression.description
        }

        let name = syntax.attributeName.trimmedDescription
        switch name {
        case "GET", "DELETE", "PATCH", "POST", "PUT", "OPTIONS", "HEAD", "TRACE", "CONNECT":
            guard let firstArgument else {
                return nil
            }

            self = .http(method: name, path: firstArgument.withoutQuotes)
        case "HTTP":
            guard let firstArgument, let secondArgument else {
                return nil
            }

            self = .http(method: secondArgument.withoutQuotes, path: firstArgument.withoutQuotes)
        case "Headers":
            guard let firstArgument else {
                return nil
            }

            self = .headers(value: firstArgument)
        case "JSON":
            let encoder = labeledArguments["encoder"] ?? "JSONEncoder()"
            let decoder = labeledArguments["decoder"] ?? "JSONDecoder()"
            self = .json(encoder: encoder, decoder: decoder)
        case "URLForm":
            self = .urlForm(encoder: firstArgument ?? "URLEncodedFormEncoder()")
        case "Multipart":
            self = .multipart(encoder: firstArgument ?? "MultipartEncoder()")
        case "Converter":
            guard let firstArgument, let secondArgument else {
                return nil
            }

            self = .converter(encoder: firstArgument, decoder: secondArgument)
        case "KeyMapping":
            guard let firstArgument else {
                return nil
            }

            self = .keyMapping(value: firstArgument)
        case "Authorization":
            guard let firstArgument else {
                return nil
            }

            self = .authorization(value: firstArgument)
        default:
            return nil
        }
    }

    func builderStatement() -> String? {
        switch self {
        case .json(let encoder, let decoder):
            """
            req.requestEncoder = .json(\(encoder))
            req.responseDecoder = .json(\(decoder))
            """
        case .urlForm(let encoder):
            "req.requestEncoder = .urlForm(\(encoder))"
        case .multipart(let encoder):
            "req.requestEncoder = .multipart(\(encoder))"
        case .converter(let encoder, let decoder):
            """
            req.requestEncoder = \(encoder)
            req.responseDecoder = \(decoder)
            """
        case .headers(let value):
            "req.addHeaders(\(value))"
        case .keyMapping(let value):
            "req.keyMapping = \(value)"
        case .authorization(value: let value):
            "req.addAuthorization(\(value))"
        case .http:
            nil
        }
    }
}

extension [EndpointModifier] {
    func parseMethodAndPath() throws -> (method: String, path: String, parameters: [String]) {
        guard let (method, path) = compactMap({
            if case let .http(method, path) = $0 { return (method, path) }
            else { return nil }
        }).first else {
            throw PapyrusPluginError("No method or path!")
        }

        let parameters = path.components(separatedBy: "/")
            .compactMap { component in
                if component.hasPrefix(":") {
                    return String(component.dropFirst())
                } else if component.hasPrefix("{") && component.hasSuffix("}") {
                    return String(component.dropFirst().dropLast())
                } else {
                    return nil
                }
            }

        return (method, path, parameters)
    }
}
