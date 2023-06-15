/*
 Functionality Evaluation

 1. Define API.
    • YES
 2. Consume API.
    • YES; via a new {protocolName}API struct. A generic `Provider<T>`, but a new type is clean, straightforward, and easy to mock.
 4. Indicate where parameters go in the request (i.e. body, query, headers, path).
    • YES; use macros (property wrappers offer type safety but aren't available in protocols.
 5. Allow for generic interceptors.
    • YES; at provider (function), protocol (macro), or function level (macro)
 6. Allow for custom parameter & output types (Request, Response).
    • YES; by confirming all inputs / outputs conform to a protocol.
 7. Allow for custom encoding & decoding such as URLForm, JSON, XML, Multipart...
    • YES; via macro or provider property
 8. Mock responses from test suite.
    • YES; can implement the protocol and mock. Can also @Mock and generate a new type, though that likely belongs in a separate library.
 9. Provide endpoints from a server.
    • TBD; can implement the protocol though will need task local values if you want to access the request. Could generate missing functions if a similar one is detected? Also this likely won't be perfectly magical without being able to read functions from the protocol in a separate file. How will server be able to read attributes?
 10. Complex responses like streaming.
    • TBD; can likely implement using a custom `Response` protocol or abstract even further.
 */
