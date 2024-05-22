import SwiftSyntax

/// To be parsed from function parameters; indicates parts of the request.
enum EndpointParameter {
    case body(name: String)
    case field(name: String)
    case query(name: String)
    case header(name: String)
    case path(name: String)

    init(_ syntax: FunctionParameterSyntax, httpMethod: String, pathParameters: [String]) {
        let typeName = syntax.type.as(IdentifierTypeSyntax.self)?.name.text
        let explicitAPIAttribute: EndpointParameter? = switch typeName {
        case "Path":   .path(name: syntax.name)
        case "Body":   .body(name: syntax.name)
        case "Header": .header(name: syntax.name)
        case "Field":  .field(name: syntax.name)
        case "Query":  .query(name: syntax.name)
        default:       nil
        }

        if let explicitAPIAttribute {
            // If the attribute is specified, use that.
            self = explicitAPIAttribute
        } else if pathParameters.contains(syntax.name) {
            // If matches a path param, roll with that
            self = .path(name: syntax.name)
        } else if ["GET", "HEAD", "DELETE"].contains(httpMethod) {
            // If method is GET, HEAD, DELETE
            self = .query(name: syntax.name)
        } else {
            // Else field
            self = .field(name: syntax.name)
        }
    }

    func builderStatement() -> String {
        switch self {
        case .body(let name):
            "req.setBody(\(name))"
        case .query(let name):
            "req.addQuery(\(name.inQuotes), value: \(name))"
        case .header(let name):
            "req.addHeader(\(name.inQuotes), value: \(name), convertToHeaderCase: true)"
        case .path(let name):
            "req.addParameter(\(name.inQuotes), value: \(name))"
        case .field(let name):
            "req.addField(\(name.inQuotes), value: \(name))"
        }
    }
}

extension [EndpointParameter] {
    func validated() throws -> [EndpointParameter] {
        let bodies = filter {
            if case .body = $0 { return true }
            else { return false }
        }

        let fields = filter {
            if case .field = $0 { return true }
            else { return false }
        }

        guard fields.count == 0 || bodies.count == 0 else {
            throw PapyrusPluginError("Can't have @Body and @Field!")
        }

        guard bodies.count <= 1 else {
            throw PapyrusPluginError("Can only have one @Body!")
        }

        return self
    }
}
