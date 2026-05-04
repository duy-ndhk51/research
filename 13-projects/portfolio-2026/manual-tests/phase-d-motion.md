# Manual tests — Phase D: motion

Run after motion features are implemented. Include **reduced motion** coverage.

## Route and list motion

- [ ] Navigate home → blog index → post: animations complete without jank or layout shift beyond acceptable range
- [ ] Blog list stagger or enter animation runs once per navigation (no duplicate runaway loops)

## Reduced motion

- [ ] Enable OS “reduce motion” (or browser equivalent): non-essential animations are suppressed or simplified
- [ ] Essential feedback (e.g. focus) remains visible

## Pointer and hover

- [ ] If using `Dock` or hover-driven UI: desktop hover behaves predictably
- [ ] Touch devices: same components remain usable without relying on hover-only affordances

## Performance sanity

- [ ] No sustained high CPU on idle page after animations finish

## Notes

_Date run:_ ___  
_Tester:_ ___  
_Failures / follow-ups:_ ___
