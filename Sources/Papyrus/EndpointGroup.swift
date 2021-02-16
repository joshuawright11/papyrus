import Foundation

/// An `EndpointGroup` represents a collection of endpoints from the
/// same host.
///
/// The `baseURL` represents the shared base URL of all endpoints in
/// this group. An `Endpoint` must be defined as a property of an
/// `EndpointGroup` in order to properly inherit its `baseURL`.
///
/// Usage:
/// ```swift
/// final class UsersService: EndpointGroup {
///     @POST("/users")
///     var createUser: Endpoint<CreateUserRequest, UserDTO>
///
///     @GET("/users/:userID")
///     var getUser: Endpoint<GetUserRequest, UserDTO>
///
///     @GET("/users/friends")
///     var getFriends: Endpoint<Empty, [UserDTO]>
/// }
///
/// let users = UsersService(baseURL: "https://api.my-app.com")
///
/// // The baseURL of this request is inferred to be
/// // `https://api.my-app.com`
/// users.createUser.request(CreateUserRequest(...))
///     ... // platform specific code for handling the response of
///         // type `UserDTO`
/// ```
///
/// In this example, all the endpoints above will be requested from
/// the baseURL of the `UsersService` isntance, in this case
/// `https://api.my-app.com`.
///
/// Ensure that all defined `Endpoint`s are properties of an
/// `EndpointGroup` type so that their `baseURL` can be
/// automatically inferred when they are requested.
public typealias EndpointGroup = EndpointGroupBase & EndpointGroupSettings

/// Base class for `EndpointGroup`s.
open class EndpointGroupBase {
    /// The base URL for all `Endpoint`s defined in this group.
    public let baseURL: String
    
    /// Initialize a group with a base url.
    ///
    /// - Parameter baseURL: The `baseURL` for all `Endpoint`s
    ///   defined in this group.
    public init(baseURL: String) {
        self.baseURL = baseURL
    }
}

/// Any settings for this EndpointGroup.
public protocol EndpointGroupSettings {
    /// The key mapping strategy of endpoints in this group. Defaults
    /// to `.useDefaultKeys`.
    var keyMapping: KeyMapping { get }
}

extension EndpointGroupSettings {
    var keyMapping: KeyMapping { .useDefaultKeys }
}


/// Represents the mapping between your type's property names and
/// their corresponding database column.
///
/// For example, you might be using a `PostgreSQL` database which has
/// a snake_case naming convention. Your `users` table might have
/// fields `id`, `email`, `first_name`, and `last_name`.
///
/// Since Swift's naming convention is camelCase, your corresponding
/// database model will probably look like this:
/// ```swift
/// struct User: Model {
///     var id: Int?
///     let email: String
///     let firstName: String // doesn't match database field of `first_name`
///     let lastName: String // doesn't match database field of `last_name`
/// }
/// ```
/// By overriding the `keyMappingStrategy` on `User`, you can
/// customize the mapping between the property names and
/// database columns. Note that in the example above you
/// won't need to override, since keyMappingStrategy is,
/// by default, convertToSnakeCase.
public enum KeyMapping {
    /// Use the literal name for all properties on an object as its
    /// corresponding database column.
    case useDefaultKeys
    
    /// Convert property names from camelCase to snake_case for the
    /// database columns.
    ///
    /// e.g. `someGreatString` -> `some_great_string`
    case convertToSnakeCase
    
    /// A custom mapping of property name to database column name.
    case custom((String) -> String)
    
    /// Given the strategy, map from an input string to an output
    /// string.
    ///
    /// - Parameter input: The input string, representing the name of
    ///   the swift type's property
    /// - Returns: The output string, representing the column of the
    ///   database's table.
    public func map(input: String) -> String {
        switch self {
        case .convertToSnakeCase:
            return input.camelCaseToSnakeCase()
        case .useDefaultKeys:
            return input
        case .custom(let mapper):
            return mapper(input)
        }
    }
}

extension String {
    /// Map camelCase to snake_case. Assumes `self` is already in
    /// camelCase.
    ///
    /// - Returns: The snake_cased version of `self`.
    fileprivate func camelCaseToSnakeCase() -> String {
        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z0-9])"
        return self.processCamalCaseRegex(pattern: acronymPattern)?
            .processCamalCaseRegex(pattern: normalPattern)?
            .lowercased() ?? self.lowercased()
    }
    
    /// Generates a string by replacing matches of a pattern with
    /// `$1_$2` in self.
    ///
    /// - Parameter pattern: The pattern to replace.
    /// - Returns: The replaced string.
    private func processCamalCaseRegex(pattern: String) -> String? {
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: "$1_$2")
    }
}
