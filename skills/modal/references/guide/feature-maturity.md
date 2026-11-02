# Feature Maturity

New features at Modal evolve through several stages. To help you understand their stability, we use two separate concepts:

* [Release phases](#release-phases) ([Alpha](#alpha), [Beta](#beta) or [GA](#general-availability-ga)): signals the stability of a feature's underlying infrastructure
* [Experimental SDK](#experimental-sdk): signals API stability in the code interface

This separation allows the SDK to remain stable even while we are still refining the performance or scaling of a backend feature.

## Release Phases

We use the following release phases to signal the maturity of a feature's underlying design and infrastructure:

### Alpha

Alpha is reserved for features that might still be fragile and have known limitations. We provide these early so you can experiment with them, but you should expect significant changes to how the feature works. The documentation will clearly state their limitations.

Some Alpha features are private, meaning you need to contact us to get access.

### Beta

Beta is our default phase for new features. Beta features are generally self-serve, functional, and mostly stable. Beta features are often suitable for production use, though we may still be refining the final behavior, pricing, or scale limits.

Some Beta features are private, meaning you need to contact us to get access.

### General Availability (GA)

GA features are stable and fully ready for production grade usage. No breaking changes are planned. Any feature not marked as Alpha or Beta in the Modal docs can be considered GA.

## Experimental SDK

In addition to the release phases described above, you may see certain parts of the Modal SDK marked as experimental (e.g., `_experimental_snapshot()`).

This is strictly an SDK concept which indicates API stability, not infrastructure maturity. It often correlates with the Alpha → Beta → GA progression, but not always. Some features stabilize their API early while the backend is still maturing, but experimental APIs may also be introduced later in a feature's lifecycle to provide additional depth of configuration.

An experimental tag means we're still gathering feedback and iterating on the interface: method names, parameters, or return types may change. Once we're confident in the design, we remove the experimental marker and commit to backwards compatibility.

## SDK Deprecations

Features that are exposed via stable API in the SDK may become *deprecated*, either because we are discontinuing support for the associated platform feature, or because the API is being adjusted, e.g. to reduce a persistent confusion or to accommodate unanticipated extensions.

Deprecated API will remain functional and will issue deprecation warnings. We recommend heeding these warnings, since deprecations will eventually be enforced and code that exercises the deprecated API will break. Breaking changes are limited to increments of the `Y` version in our `X.Y.Z` versioning scheme.

## Other interfaces

Only the official SDKs are currently considered to be stable. Any other public interfaces are undocumented, subject to change without warning, and use-at-your-own risk.

## Providing Feedback

We value your feedback on Alpha and Beta features! If you're using a feature at any release phase and have suggestions or encounter issues:

* Join our [Slack community](https://modal.com/slack) to discuss with the team and other users
* Reach out to support@modal.com with specific feedback or bug reports
