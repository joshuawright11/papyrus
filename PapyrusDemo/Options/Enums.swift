import Foundation
import Papyrus

/*
 MARK: OPTION 1: `enum`

 PROS
 • works.
 • simple to generate inner `Provider` type.
 • readable and concise.
 • will need to confirm that @propertyWrapper is allowed on an enum case parameter.

 CONS
 • Swift enums have unique syntax and functionality, this isn't as clear and concise as a simple function.
 • no clear, typesafe way to provide.
 */

enum TodoEnumAPI {
    /// Generated
    struct Provider {
        let baseURL: String
        let session: URLSession

        func getTodos(query: String) async throws -> [Todo] {
            let url = URL(string: baseURL + "/todos")!
            let (data, _) = try await session.data(from: url)
            let decoder = JSONDecoder()
            let value = try decoder.decode([Todo].self, from: data)
            return value
        }
    }

    @GET2<[Todo]>("/todos")
    case getTodos(query: String)
}
