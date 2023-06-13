import Foundation
import Papyrus

/*
 MARK: API Interface Scratch

 Considerations:

 1. Define API.
 2. Consume API.
 4. Indicate where parameters go in the request (i.e. body, query, headers, path).
 5. Allow for interceptors.
 6. Allow for custom parameter & output types.
 7. Allow for custom encoding & decoding.
 8. Mock responses from test suite.
 9. Provide endpoints from a server.
 10. Complex responses like streaming.
 */

struct Todo: Codable {
    let id: Int
    let name: String
}

//let todos = TodoAPIProvider(baseURL: "localhost:8080")
//let user = UserAPIProvider(baseURL: "localhost:8080")
//let accounts = AccountsAPIProvider(baseURL: "localhost:8080")
