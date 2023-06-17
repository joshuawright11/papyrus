import Papyrus

public struct Todo: Codable {
    let id: Int
    let name: String
}

@API
@Mock
@JSON
@KeyMapping(.useDefaultKeys)
@Authorization(.bearer("TOKEN!"))
@Headers(["foo": "bar"])
protocol Todos {
    @GET("/todos/:id")
    func todos(id: String, @Header header1 headerOne: String, @Header header2: String) async throws -> [Todo]

    @POST("/todos/:idCount/tags?foo=bar")
    @KeyMapping(.snakeCase)
    @Headers(["boo": "far"])
    @URLForm
    func tags(@Path idCount: String, @Field fieldOne: Int, @Query fieldTwo: Bool) async throws -> [Todo]
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

let provider = Provider(baseURL: "http://localhost:3000")
    .intercept { req, next in
        let start = Date()
        let res = try await next(req)
        let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
        // Got a 200 for GET /users after 0.45s
        print("Got a \(res.statusCode!) for \(req.method) \(req.url!.relativePath) after \(elapsedTime)")
        return res
    }

let todos: Todos = TodosAPI(provider: provider)
let user: Users = UsersAPI(provider: provider)
let accounts: Accounts = AccountsAPI(provider: provider)
do {
    let tags = try await todos.tags(idCount: "Hello", fieldOne: 1, fieldTwo: true)
    print("Got \(tags.count) todos.")
}
catch {
    print("Got error: \(error).")
}

let mock = TodosMock()
mock.mockTodos { one, two, three in
    return [
        Todo(id: 1, name: "Foo"),
        Todo(id: 2, name: "Bar"),
    ]
}

let t: Todos = mock
do {
    let r = try await t.todos(id: "foo", header1: "bar", header2: "baz")
    print("Result is \(r.count).")
}
catch {
    print("Result error is: \(error).")
}
