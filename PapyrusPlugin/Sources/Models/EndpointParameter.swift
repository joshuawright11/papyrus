import SwiftSyntax

/// Parsed from function parameters; indicates parts of the request.
struct EndpointParameter {
    enum Kind {
        case body
        case field
        case query
        case header
        case path
    }

    let label: String?
    let name: String
    let type: String
    let kind: Kind

    init(_ parameter: FunctionParameterSyntax, httpMethod: String, pathParameters: [String]) {
        self.label = parameter.label
        self.name = parameter.name
        self.type = parameter.typeName
        self.kind =
            if type.hasPrefix("Path<") {
                .path
            } else if type.hasPrefix("Body<") {
                .body
            } else if type.hasPrefix("Header<") {
                .header
            } else if type.hasPrefix("Field<") {
                .field
            } else if type.hasPrefix("Query<") {
                .query
            } else if pathParameters.contains(name) {
                // if name matches a path param, infer this belongs in path
                .path
            } else if ["GET", "HEAD", "DELETE"].contains(httpMethod) {
                // if method is GET, HEAD, DELETE, infer query
                .query
            } else {
                // otherwise infer it's a body field
                .field
            }
    }
}
