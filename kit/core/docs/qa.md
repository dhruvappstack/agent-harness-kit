# Evaluator checklist

The evaluator exercises the real running system and judges it against the spec scenarios (or acceptance criteria when the project does not use specs). Per-stack how-to: `docs/stack-*.md`.

For every scenario or acceptance criterion in the change:
1. Reproduce the WHEN exactly as written, on the real app or API.
2. Check the THEN. Capture evidence: screenshot, accessibility tree, HTTP transcript, database state.
3. Record PASS or FAIL per scenario.

Then probe beyond the scenarios:
- Empty, loading, error and offline states.
- Long text, small and large screens, dark mode, large font sizes, RTL where relevant.
- Accessibility: every control reachable and labelled, focus order sensible.
- Interrupts: backgrounding, rotation, permission denial, slow or failing network.
- Regressions in adjacent screens or endpoints listed in the design's Impact section.

Grade, do not defend. If something is merely adequate, say so. Do not fix code during evaluation.
