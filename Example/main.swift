import Papyrus

// MARK: 0. Define your API.

@API
@Mock
@KeyMapping(.snakeCase)
@Authorization(.bearer("<my-auth-token>"))
protocol Sample {
    @GET("/todos")
    func getTodos() async throws -> [Todo]

    @POST("/todos")
    func createTodo(name: String) async throws -> Todo

    @URLForm
    @POST("/todos/:id/tags")
    func createTag(@Path id: Int) async throws

    @Multipart
    @POST("/todo/:id/attachment")
    func upload(@Path id: Int, part1: Part, part2: Part) async throws
}

public struct Todo: Codable {
    let id: Int
    let name: String
}

// MARK: 2. Create a Provider with any custom configuration.

let provider = Provider(baseURL: "http://127.0.0.1:3000")
    .intercept { req, next in
        let start = Date()
        let res = try await next(req)
        let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
        print("Got a \(res.statusCode!) for \(req.method) \(req.url) after \(elapsedTime)")
        return res
    }

// MARK: 3. Initialize an API instance & call an endpoint.

let api: Sample = SampleAPI(provider: provider)
let todos = try await api.getTodos()

// MARK: 4. Easily mock endpoints for tests.

let mock = SampleMock()
mock.mockGetTodos {
    return [
        Todo(id: 1, name: "Foo"),
        Todo(id: 2, name: "Bar"),
    ]
}

let mockedTodos = try await mock.getTodos()
