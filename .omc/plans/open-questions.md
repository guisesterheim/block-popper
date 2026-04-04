# Open Questions

## block-popper-ios - 2026-04-04

### Resolved (2026-04-04 revision)
- [x] Level score thresholds: Resolved -- formula is `100 * level + 50 * level * (level - 1)`, marked as tunable. Hardcoded in `LevelConfig.swift` for v1.
- [x] Rescue fallback depth: Resolved -- algorithm iteratively clears most-filled lines until all pieces fit, with empty-board as guaranteed termination backstop. No depth limit needed.
- [x] Color palette and visual theme: Resolved -- earthy tone palette specified with exact hex values in plan. `ColorPalette.swift` with named constants.

### Still Open
- [ ] Piece generation weighting: Should larger pieces appear less frequently than smaller ones, or equal probability? -- Directly impacts difficulty curve
- [ ] Xcode project creation method: Use SPM-based project, Xcode template, or Tuist? -- Affects build system complexity and CI setup
- [ ] Target iOS version: Minimum deployment target not specified (iOS 16? 17?) -- Affects available SpriteKit APIs and ATT availability (ATT requires iOS 14+)
- [ ] Google Mobile Ads SDK app ID: A real AdMob app ID and ad unit ID are needed for production builds -- test IDs can be used during development
- [ ] Block style texture assets: Plan references texture/pattern overlays (wood-grain, rough edge, organic border) -- are these programmatic (Core Graphics drawn) or asset-based (PNG)? -- Affects asset pipeline
