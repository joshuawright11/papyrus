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
    case snakeCase
    
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
        case .snakeCase:
            return input.camelCaseToSnakeCase()
        case .useDefaultKeys:
            return input
        case .custom(let mapper):
            return mapper(input)
        }
    }
    
    var jsonEncodingStrategy: JSONEncoder.KeyEncodingStrategy {
        switch self {
        case .snakeCase:
            return .convertToSnakeCase
        case .useDefaultKeys:
            return .useDefaultKeys
        case .custom(let closure):
            return .custom { keys in
                guard let last = keys.last else {
                    return GenericCodingKey("")
                }
                
                return GenericCodingKey(closure(last.stringValue))
            }
        }
    }
    
    var jsonDecodingStrategy: JSONDecoder.KeyDecodingStrategy {
        switch self {
        case .snakeCase:
            return .convertFromSnakeCase
        case .useDefaultKeys:
            return .useDefaultKeys
        case .custom(let closure):
            return .custom { keys in
                guard let last = keys.last else {
                    return GenericCodingKey("")
                }
                
                return GenericCodingKey(closure(last.stringValue))
            }
        }
    }
}

struct GenericCodingKey: CodingKey {
    init(_ string: String) { self.stringValue = string }
    
    var stringValue: String
    init?(stringValue: String) { self.stringValue = stringValue }
    
    var intValue: Int?
    init?(intValue: Int) { return nil }
}

extension String {
    /// Map camelCase to snake_case. Assumes `self` is already in
    /// camelCase. Copied from `Foundation`.
    ///
    /// - Returns: The snake_cased version of `self`.
    fileprivate func camelCaseToSnakeCase() -> String {
        guard !self.isEmpty else { return self }
    
        var words : [Range<String.Index>] = []
        // The general idea of this algorithm is to split words on transition from lower to upper case, then on transition of >1 upper case characters to lowercase
        //
        // myProperty -> my_property
        // myURLProperty -> my_url_property
        //
        // We assume, per Swift naming conventions, that the first character of the key is lowercase.
        var wordStart = self.startIndex
        var searchRange = self.index(after: wordStart)..<self.endIndex
    
        // Find next uppercase character
        while let upperCaseRange = self.rangeOfCharacter(from: CharacterSet.uppercaseLetters, options: [], range: searchRange) {
            let untilUpperCase = wordStart..<upperCaseRange.lowerBound
            words.append(untilUpperCase)
            
            // Find next lowercase character
            searchRange = upperCaseRange.lowerBound..<searchRange.upperBound
            guard let lowerCaseRange = self.rangeOfCharacter(from: CharacterSet.lowercaseLetters, options: [], range: searchRange) else {
                // There are no more lower case letters. Just end here.
                wordStart = searchRange.lowerBound
                break
            }
            
            // Is the next lowercase letter more than 1 after the uppercase? If so, we encountered a group of uppercase letters that we should treat as its own word
            let nextCharacterAfterCapital = self.index(after: upperCaseRange.lowerBound)
            if lowerCaseRange.lowerBound == nextCharacterAfterCapital {
                // The next character after capital is a lower case character and therefore not a word boundary.
                // Continue searching for the next upper case for the boundary.
                wordStart = upperCaseRange.lowerBound
            } else {
                // There was a range of >1 capital letters. Turn those into a word, stopping at the capital before the lower case character.
                let beforeLowerIndex = self.index(before: lowerCaseRange.lowerBound)
                words.append(upperCaseRange.lowerBound..<beforeLowerIndex)
                
                // Next word starts at the capital before the lowercase we just found
                wordStart = beforeLowerIndex
            }
            searchRange = lowerCaseRange.upperBound..<searchRange.upperBound
        }
        words.append(wordStart..<searchRange.upperBound)
        let result = words.map({ (range) in
            return self[range].lowercased()
        }).joined(separator: "_")
        return result
    }
}
