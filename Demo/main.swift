import Papyrus

@API
@JSON
@KeyMapping(.useDefaultKeys)
@Authorization(.bearer("TOKEN!"))
@Mock
@Headers(["foo": "bar"])
protocol Todos {
    @GET("/todos/:id")
    func todos(id: String, @Header header1 headerOne: String, @Header header2: String) async throws -> [Todo]

    @POST("/todos/:idCount/tags?foo=bar")
    @KeyMapping(.snakeCase)
    @URLForm
    @Headers(["boo": "far"])
    func tags(@Path idCount: String, @Header fieldOne: Int, fieldTwo: Bool) async throws -> [Todo]
}

@API
@Mock
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
    let todos = try await todos.tags(idCount: "Hello", fieldOne: 1, fieldTwo: true)
    print("NO ERROR \(todos.count)!")
}
catch {
    print("ERROR: \(error)")
}
