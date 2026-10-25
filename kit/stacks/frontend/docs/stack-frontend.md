# Frontend stack notes

## Run
`scripts/harness/verify.sh --fast` lints and builds (including typechecking). Unit and component tests run through the test script; E2E through Playwright.

## Make the UI testable
- Query by role and accessible name first, then `data-testid="screen.element"` when needed.
- Mock the network at the boundary (MSW or Playwright route mocking) with fixed fixtures; no real third-party calls in tests.
- Component stories or an isolated route for each state (loading, empty, error, populated).

## Evaluator protocol
1. Start the dev or preview server with seeded data.
2. With Playwright (or a browser tool), perform each scenario's WHEN, check the THEN, save screenshots and traces to `<change-dir>/evidence/`.
3. Check: keyboard-only navigation, focus order, accessible names (run axe), responsive widths (360, 768, 1280), dark mode, slow and failing network, console errors.
4. Compare against the design reference if one is linked in the proposal.

## Pitfalls agents hit here
- Asserting on implementation details (class names, internal state) instead of user-visible behaviour.
- Fixed `sleep`s instead of auto-waiting assertions.
- Adding dependencies for trivial utilities; ignoring bundle size.
- Injecting raw HTML; storing tokens in web storage.
