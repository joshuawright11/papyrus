import Papyrus

@API
@JSON
@KeyMapping(.useDefaultKeys)
@Authorization(.bearer("TOKEN!"))
@Mock
protocol Todos {
    @GET("/todos/:id")
    func todos(id: String, @Header header1 headerOne: String, @Header header2: String) async throws -> [Todo]

    @POST("/todos/:id/tags?foo=bar")
    @KeyMapping(.snakeCase)
    @URLForm
    func tags(@Path id: String, @Query fieldOne: Int, fieldTwo: Bool) async throws -> [Todo]
}

@API
@Mock
@URLForm
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
    let todos = try await todos.tags(id: "Hello", fieldOne: 1, fieldTwo: true)
    print("NO ERROR \(todos.count)!")
}
catch {
    print("ERROR: \(error)")
}

// MARK: Docs

// ## Constructing a Request

// ### Method & Path

// Set the method and path of your request as an attribute on the function.
// You may set a custom method with the `@Http` attribute.
// You may also set queries directly in the path URL.

// ### URL

// ### Body

// ### Headers

// ### Misc

// ## Handling the Response

// ## Provider

// ## Testing
