import Papyrus

let multipart = MultipartEncoder()
let data = try multipart.encode([
    "fooKey": Part(data: Data("Hello foo!".utf8), fileName: "foo.txt", mimeType: "text/plain"),
    "barKey": Part(data: Data("Hello bar!".utf8), fileName: "bar.txt", mimeType: "text/plain"),
])
let string = String(data: data, encoding: .utf8)!
print("Content-Type: \(multipart.contentType)\n\n\(string)")

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
    @URLForm
    @POST("/todos")
    func todos(id: String, @Header header1 headerOne: String, @Header header2: String, completion: @escaping (Result<[Todo], Error>) -> Void)

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

    @POST("/accounts")
    func createAccount2(name: String) async throws -> Int

    @POST("/accounts")
    func createAccount(name: String, completionHandler: @escaping (Result<Int, Error>) -> Void)

    @PATCH("/accounts")
    func updateAccount(name: String, completionHandler: @escaping (Response) -> Void)

    @Multipart
    @POST("/attachment")
    func upload(part1: Part, part2: Part) async throws
}

let provider = Provider(baseURL: "http://127.0.0.1:3000")
    .intercept { req, next in
        let start = Date()
        let res = try await next(req)
        let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
        // Got a 200 for GET /users after 0.45s
        print("Got a \(res.statusCode!) for \(req.method) \(req.url) after \(elapsedTime)")
        return res
    }

let todos: Todos = TodosAPI(provider: provider)
let user: Users = UsersAPI(provider: provider)
let accounts: Accounts = AccountsAPI(provider: provider)

try await withCheckedThrowingContinuation { done in
    todos.todos(id: "FOO", header1: "BAR", header2: "BAZ") {
        switch $0 {
        case .failure(let error):
            print("Got error: \(error).")
        case .success(let todos):
            print("Got \(todos.count) todos.")
        }

        done.resume()
    }
}

let mock = TodosMock()
mock.mockTodos { one, two, three, callback in
    callback(.success([
        Todo(id: 1, name: "Foo"),
        Todo(id: 2, name: "Bar"),
    ]))
}

let t: Todos = mock
t.todos(id: "foo", header1: "bar", header2: "baz") {
    switch $0 {
    case .failure(let error):
        print("Result error is: \(error).")
    case .success(let todos):
        print("Result is \(todos.count).")
    }
}
