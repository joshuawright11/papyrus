import Foundation
import Papyrus

// TODO: Tests
// TODO: Custom compiler errors
// TODO: Final cleanup
// TODO: README.md

// TODO: Launch Twitter, HN, Swift Forums, r/swift, r/iOSProgramming Friday morning 9am

// TODO: Multipart
// TODO: Server Library: async-http-client requesting, provide endpoints

@API
@JSON
@KeyMapping(.useDefaultKeys)
@Headers(["FooBar": "BarFoo"])
@Mock
protocol Todos {
    @GET("/todos")
    func todos(@Query("foo") query: String, @Header header1 headerOne: String, @Header header2: String) async throws -> [Todo]

    @POST("/todos/tags")
    @KeyMapping(.snakeCase)
    @URLForm
    func tags(@Query queryValue: String, fieldOne: Int, fieldTwo: Bool) async throws -> [Todo]
}

@API
@Mock
@JSON
protocol Users {
    @URLForm
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
    let todos = try await todos.tags(queryValue: "Hello", fieldOne: 1, fieldTwo: true)
    print("NO ERROR \(todos.count)!")
}
catch {
    print("ERROR: \(error)")
}
