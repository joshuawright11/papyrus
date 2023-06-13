import Foundation
import Papyrus

/*
 MARK: OPTION 3: `protocol` with extension on `Provider`

 PROS
 • function definitions are clear and concise
 • no implementation required
 • clear way to provide implementations - just conform to protocol.
 • protocols are Swifty.

 CONS
 • manually writing the extension isn't ideal & is uggo.
 •• once peer macros can add extensions this can be automatically done.

 THOROUGH EVAL

 1. Define API.
    • YES; though double check can read macro on functions
 2. Consume API.
    • YES
 4. Indicate where parameters go in the request (i.e. body, query, headers, path).
    • YES; should be simple with property wrappers
 5. Allow for generic interceptors.
    • YES; though decoupled from protocol inside the `Provider` extension (extension of the protocol might be cleaner)
 6. Allow for custom parameter & output types (Request, Response).
    • YES; by confirming all inputs / outputs conform to a protocol.
 7. Allow for custom encoding & decoding such as URLForm, JSON, XML, Multipart.
    • YES; with a default converter in the `Provider` extension (extension of the protocol or macro might be cleaner)
 8. Mock responses from test suite.
    • YES; can implement the protocol and mock. May be tricky to only expose in test suite. Would also be nice to mock just one endpoint at once. Another macro perhaps.
 9. Provide endpoints from a server.
    • YES; can implement the protocol though will need task local values if you want to access the request. Could also generate missing functions if a similar one is detected.
 10. Complex responses like streaming.
    • YES; can implement using a custom `Response` protocol or abstract even further.

 What concrete type should the generated functions be place on?

 1. A one off type associated with the protocol (`TodoAPIProvider`).
 2. An existing network access type (`URLSession`, `HTTPClient`).
 3. A new, shared type with generics (Provider<MyProtocol>).
    • I like this the best since it won't junk up the URLSession API and can store a baseURL & session variable.
    • I also like that this doesn't introduct a completely new type.
    • I also like that this will make it easy to override intercept functions.

 NAMING:

 struct Provider, protocol Service / None, generated struct API

 WHAT LOGIC GOES WHERE:

 Provider: API Specific Information
 • baseURL
 • underlying networking client
 • interceptors
 • converting

 Protocol: Endpoint Specific Information
 • input / output types & location
 • one off converting

 */

// MARK: Definition

@API
@Converter(.urlForm)
@KeyMapping(.snakeCase)
@Headers(["Foo": "Bar"])
protocol Todos {
    @GET2("/todos")
    func todos(@Default("bar") @Query2("foo") query: String, @Header2 header1 headerOne: String, @Header2 header2: String) async throws -> [Todo]

    @Http("/todos/tags", method: "WTF")
    func tags(query: String) async throws -> [Todo]
}

@API
protocol Users {
    @GET2("/users")
    func getUsers() async throws -> String
}

@API
protocol Accounts {
    @GET2("/accounts")
    func getAccounts() async throws

}

/// Makes URL requests.
struct Provider {
    let baseURL: String
    let session: URLSession
    let interceptors: [() -> Void]

    init(baseURL: String, session: URLSession = .shared, interceptors: [() -> Void] = []) {
        self.baseURL = baseURL
        self.session = session
        self.interceptors = interceptors
    }

    @discardableResult
    func request(_ request: PartialRequest) async throws -> RawResponse {
        fatalError()
    }
}

let provider = Provider(baseURL: "https://github.com", session: .shared)
//let api = TodosAPI(provider: provider)
