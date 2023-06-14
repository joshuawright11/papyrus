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
@Converter(.urlForm)
@KeyMapping(.snakeCase)
@Headers(["Foo": "Bar"])
@Mock
protocol Todos {
    @GET2("/todos")
    func todos(@Default("bar") @Query2("foo") query: String, @Header2 header1 headerOne: String, @Header2 header2: String) async throws -> [Todo]

    @Http("/todos/tags", method: "WTF")
    func tags(query: String) async throws -> [Todo]
}

@API
@Mock
protocol Users {
    @GET2("/users")
    func getUsers() async throws -> (first: String, second: Response)
}

@API
@Mock
protocol Accounts {
    @GET2("/accounts")
    func getAccounts() async throws
}

struct Todo: Codable {
    let id: Int
    let name: String
}

let provider = Provider(baseURL: "localhost:8080")
let todos: Todos = TodosAPI(provider: provider)
let user: Users = UsersAPI(provider: provider)
let accounts: Accounts = AccountsAPI(provider: provider)
