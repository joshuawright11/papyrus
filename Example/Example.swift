import Foundation
import Papyrus

// MARK: 0. Define your API.

@API
@Mock
public protocol Sample: Sendable {
    @GET("/todos")
    func getTodos() async throws -> [Todo]

    @POST("/todos")
    func createTodo(name: String) async throws -> Todo

    @URLForm
    @POST("/todos/:id/tags")
    func createTag(id: Int) async throws

    @Multipart
    @POST("/todo/:id/attachment")
    func upload(id: Int, part1: Part, part2: Part) async throws
}

public struct Todo: Codable, Sendable {
    let id: Int
    let name: String
}

@main
struct Example {
  static func main() async throws {
      // MARK: 1. Create a Provider with any custom configuration.

      let provider = Provider(baseURL: "http://127.0.0.1:3000")
          .modifyRequests {
              $0.addAuthorization(.bearer("<my-auth-token>"))
              $0.keyMapping = .snakeCase
          }
          .intercept { req, next in
              let start = Date()
              let res = try await next(req)
              let elapsedTime = String(format: "%.2fs", Date().timeIntervalSince(start))
              let statusCode = res.statusCode.map { "\($0)" } ?? "N/A"
              print("Got a \(statusCode) for \(req.method) \(req.url!) after \(elapsedTime)")
              return res
          }

      // MARK: 2. Initialize an API instance & call an endpoint.

      let api: any Sample = SampleAPI(provider: provider)
      let todos = try await api.getTodos()
      print(todos)

      // MARK: 3. Easily mock endpoints for tests.

      let mock = SampleMock()
      mock.mockGetTodos {
          return [
              Todo(id: 1, name: "Foo"),
              Todo(id: 2, name: "Bar"),
          ]
      }

      let mockedTodos = try await mock.getTodos()
      print(mockedTodos)
  }
}
