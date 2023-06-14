import Foundation
import Papyrus

// TODO: Tests
// TODO: Custom compiler errors
// TODO: Final cleanup
// TODO: README.md

// TODO: Launch Twitter, HN, Swift Forums, r/swift, r/iOSProgramming Friday morning 9am

// TODO: Multipart
// TODO: Provider Requests on Server
// TODO: Custom RequestEncodable Protocol (for functions with lots of arguments)
// TODO: async-http-client provider (separate library)
// TODO: Inspect underlying response on error

@API
@Headers(["FooBar": "BarFoo"])
@Mock
protocol Todos {
    @GET("/todos")
    func todos(@Default("bar") @Query("foo") query: String, @Header header1 headerOne: String, @Header header2: String) async throws -> [Todo]

    @POST("/todos/tags")
    @KeyMapping(.snakeCase)
    @URLForm
    func tags(@Query queryValue: String, fieldOne: Int, fieldTwo: Bool) async throws -> [Todo]
}

@API
@Mock
protocol Users {
    @GET("/users")
    func getUsers() async throws -> (first: String, second: Response)
}

@API
@Mock
protocol Accounts {
    @GET("/accounts")
    func getAccounts() async throws
}

struct Todo: Codable {
    let id: Int
    let name: String
}

let provider = Provider(baseURL: "http://localhost:3000")
let todos: Todos = TodosAPI(provider: provider)
let user: Users = UsersAPI(provider: provider)
let accounts: Accounts = AccountsAPI(provider: provider)

do {
    let _todos = try await todos.tags(queryValue: "Header1", fieldOne: 1, fieldTwo: true)
    for todo in _todos {
        print("\(todo.id): \(todo.name)")
    }
}
catch {
    print("ERROR: \(error)")
}
