import Foundation
import Papyrus

/*
 MARK: OPTION 2: `struct` or `class`

 PROS
 • function definitions are clear and concise

 CONS
 • the function used purely for it's definition is janky; undefined behavior if called & needs an empty body & return type.
 • no clear, typesafe way to provide.
 */

struct TodoStructAPI {
    @GET2("/todos")
    func getTodos(query: String) -> [Todo] {
        fatalError()
    }

    /// Generated
    func todos(query: String) async throws -> [Todo] {
        let session = URLSession.shared
        let baseURL = "https://localhost:8080"
        let url = URL(string: baseURL + "/todos")!
        let (data, _) = try await session.data(from: url)
        let decoder = JSONDecoder()
        let value = try decoder.decode([Todo].self, from: data)
        return value
    }
}
