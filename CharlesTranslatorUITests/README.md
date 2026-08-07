Intentionally empty for Phase 1/1.1/1.2 — see the "Testing" section of the implementation plan. UI automation is deferred until the screen set stabilizes in Phase 2, to avoid maintaining brittle tests against a still-changing UI.

A throwaway diagnostic UI test was tried here once to chase a reported crash, but XCUITest's runner itself failed to bootstrap on this machine's iOS 27.0 beta simulator runtime (duplicate Objective-C class warnings across several private frameworks, unrelated to the app) — so it was removed rather than left as permanently-broken CI.
