---
name: swift
description: Always use when creating and editing Swift files (*.swift)
---

# Swift Style Guide

## Naming

- Use UpperCamelCase for type and protocol names, and lowerCamelCase for everything else.

- Name booleans like `isSpaceship`, `hasSpacesuit`, etc. This makes it clear that they are booleans and not other types.

- Acronyms in names (`ID`, `URL`, etc) should be all-caps except when it’s the start of a name that would otherwise be lowerCamelCase, in which case it should be uniformly lower-cased.

- Event-handling functions should be named like past-tense sentences (e.g. `didTap`, not `handleTap`). The subject can be omitted if it's not needed for clarity.

- Avoid Objective-C-style acronym prefixes. This is not needed to avoid naming conflicts in Swift.

## Style

- Don't include types where they can be easily inferred.

- Prefer letting the type of a variable or property be inferred from the right-hand-side value rather than writing the type explicitly on the left-hand side.

- Don't use `self` unless it's necessary for disambiguation or required by the language.

- Name members of tuples for extra clarity. Rule of thumb: if you've got more than 3 fields, you should probably be using a struct.

- When unwrapping an optional, prefer reusing the existing identifier rather than introducing a new one. However, it's fine to introduce a new name when doing so improves clarity at the use site.

- Prefer `if` expressions over ternary operators for single-expression return values. Use ternary operators for conditions nested in other expressions, such as SwiftUI modifier conditions. Generally prefer `if` expressions for assignments after `=` operators.

- Prefer using `for` loops over the functional `forEach(…)` method, unless using `forEach(…)` as the last element in a functional chain.

### Functions

- Avoid using `unowned` captures. Instead prefer safer alternatives like `weak` captures, or capturing variables directly.

### Operators

- When extending bound generic types, prefer using generic bracket syntax (`extension Collection<Planet>`), or sugared syntax for applicable standard library types (`extension [Planet]`) instead of generic type constraints.

## Patterns

- Prefer initializing properties at `init` time whenever possible, rather than using implicitly unwrapped optionals. A notable exception is UIViewController's `view` property.

- Avoid performing any meaningful or time-intensive work in `init()`. Avoid doing things like opening database connections, making network requests, reading large amounts of data from disk, etc. Create something like a `start()` method if these things need to be done before an object is ready for use.

- Omit redundant memberwise initializers. The compiler synthesizes `internal` memberwise initializers for structs, so explicit `internal` initializers equivalent to the synthesized initializer should be omitted.

- Extract complex property observers into methods. This reduces nestedness and separates side-effects from property declarations.

- Extract complex callback blocks into methods to reduced nestedness.

- When validating preconditions at the start of a scope, prefer using `guard` statements over `if` statements. This reduces nesting, and allows the compiler to verify that the `return` statement is present.

- Avoid global functions whenever possible. Prefer methods within type definitions.

- Prefer immutable values whenever possible. Use `map` and `compactMap` instead of appending to a new collection. Use `filter` instead of removing elements from a mutable collection.

- Prefer immutable or computed static properties over mutable ones whenever possible. Use stored `static let` properties or computed `static var` properties over stored `static var` properties whenever possible, as stored `static var` properties are global mutable state.

- Handle an unexpected but recoverable condition with an `assert` method combined with the appropriate logging in production. If the unexpected condition is not recoverable, prefer a `precondition` method or `fatalError()`. This strikes a balance between crashing and providing insight into unexpected conditions in the wild. Only prefer `fatalError` over a `precondition` method when the failure message is dynamic, since a `precondition` method won't report the message in the crash report.

- Default classes to `final`.

- When defining type functions in classes, prefer `static func` over `class func`.

- When switching over an enum, generally prefer enumerating all cases rather than using the `default` case.

- Check for nil rather than using optional binding if you don't need to use the value.

- Prefer dedicated logging systems like `os_log` or `swift-log` over writing directly to standard out using `print(…)`, `debugPrint(…)`, or `dump(…)`.

- Don't use `#file`. Use `#fileID` or `#filePath` as appropriate.

- Don't use `#filePath` in production code. Use `#fileID` instead.

- Prefer using opaque generic parameters (with `some`) over verbose named generic parameter syntax where possible.

- Prefer to avoid using `@unchecked Sendable`. Use a standard `Sendable` conformance instead where possible. If working with a type from a module that has not yet been updated to support Swift Concurrency, suppress concurrency-related errors using `@preconcurrency import`.

- Prefer using a generated Equatable implementation when comparing all properties of a type. For structs, prefer using the compiler-synthesized Equatable implementation when possible.

- If available in your project, prefer using a `#URL(_:)` macro instead of force-unwrapping URL(string:)! initializer.

## SwiftUI

- For internal SwiftUI views, prefer using the synthesized memberwise init by defining internal properties rather than private properties. However, SwiftUI dynamic properties like `@State` should stay private.

## Testing

- In Swift Testing, name test cases as sentences using raw identifiers, rather than using lowerCamelCase. Don't prefix test case names with "`test`". Use UpperCamelCase for test suite names. Always omit the display name string from the `@Test` or `@Suite` macro.

- In Swift Testing, avoid expectation message strings that restate the expectation without adding additional context. Unlike `XCTAssert`, the Swift Testing `#expect` macro generates detailed failure messages that include the expectation condition.

- Avoid `guard` statements in unit tests. XCTest and Swift Testing have APIs for unwrapping an optional and failing the test, which are much simpler than unwrapping the optionals yourself. Use assertions instead of guarding on boolean conditions.

- In test suites, test cases should be `internal`, and helper methods and properties should be `private`.

- Avoid force-unwrapping in unit tests. Force-unwrapping (!) will crash your test suite. Use safe alternatives like `try XCTUnwrap` or `try #require`, which will throw an error instead, or standard optional unwrapping (`?`).

## Performance

- Prefer using `count(where: { ... })` over `filter { ... }.count`.

- Prefer using `isEmpty` over comparing `count` against zero.

- Prefer using `flatMap { ... }` over `map { ... }.reduce([], +)`.

- Prefer using `contains` over `filter(_:).isEmpty`, `first(where:) != nil`, and `range(of:) != nil`.

- Prefer using `first(where: { ... })` over `filter { ... }.first`.

- Prefer using `min()` over `sorted().first`.

- Prefer `lazy.map` over `map` when the chain reduces to a single result (`joined(separator:)`, `min`, `max`, `reduce`, `contains`, etc).

## Apple Frameworks

- Use constructors instead of Make() functions for NSRange and others.

* Prefer CIFilter's typed factory methods (via `CIFilterBuiltins`) over the string-based `CIFilter(name:)` initializer and KVO `setValue(_:forKey:)`.
