import Foundation
import Papyrus

@API
@JSON
@KeyMapping(.useDefaultKeys)
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
@Authorization(.basic(username: "josh@withapollo.com", password: "P@ssword"))
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
