# Deep Interview Spec: Block Popper -- iOS Puzzle Game

## Metadata
- Interview ID: di-ios-game-001
- Rounds: 9
- Final Ambiguity Score: 12%
- Type: greenfield
- Generated: 2026-04-04
- Revised: 2026-04-04 (post-interview additions: earthy palette, ads, block styles, animation specs)
- Threshold: 20%
- Status: PASSED (revised)

---

## Clarity Breakdown

| Dimension | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| Goal Clarity | 0.88 | 40% | 0.352 |
| Constraint Clarity | 0.80 | 30% | 0.240 |
| Success Criteria | 0.80 | 30% | 0.240 |
| **Total Clarity** | | | **0.832** |
| **Ambiguity** | | | **17%** |

---

## Goal

Build a native iOS puzzle game (Swift + SpriteKit) where the player drags block pieces from a tray onto a 9x9 grid. Completing an entire row or column clears it and scores points. The player has 3 lives; spending a life rescues a stuck board. The game progresses through levels gated by score thresholds. The game features an earthy color palette, 5 block style themes, interstitial ads before life rescues, and polished animations.

---

## Constraints

- **Platform**: iOS only, native Swift + SpriteKit
- **Grid**: 9x9 square grid occupying ~80% of the screen (top section)
- **Tray**: Bottom ~20% of screen displays 3 distinct block pieces at all times
- **Block placement**: Drag-and-drop only -- a piece is placed where the player drops it if it fits; rejected if it doesn't fit
- **Piece shapes** (initial set -- more to be added during implementation):
  - 1x1 dot
  - 1x2 horizontal domino
  - 2x1 vertical domino
  - 1x3 horizontal triomino
  - 1x4 horizontal tetromino
  - 1x5 horizontal pentomino
  - 2x2 square
  - 3x2 L-shape
  - 3x2 pyramid
- **Lives**: Exactly 3 per game session
- **Piece refresh**: Each tray slot refills immediately when its piece is placed (tray always shows 3 pieces). NOTE: This supersedes any earlier mention of batch refill (all 3 at once). Round 7 interview clarification is authoritative.
- **Level target scores**: Formula `targetScore(level) = 100 * level + 50 * level * (level - 1)` -- Level 1: 100, Level 2: 300, Level 3: 600, Level 4: 1000. Marked as tunable.
- **Rescue algorithm**: When stuck with lives > 0, clear the 2 most-filled rows + 2 most-filled columns; iteratively clear more lines if any tray piece still cannot be placed; worst-case clears entire board (guaranteed termination). Rescue clears do NOT award score points.
- **Color palette**: Earthy tones throughout -- warm browns, burnt oranges, forest greens, sandy beiges, terracotta. Background: `#3B2A1A`. Grid empty cells: slightly lighter brown with subtle border. HUD text: warm cream / off-white.
- **Block styles**: 5 themes (Stone, Wood, Terracotta, Moss, Sand), each with distinct fill color, border color, corner radius, and optional texture. Cycle on full-board clear (all 81 cells empty after a single placement).
- **Ads**: Google Mobile Ads SDK (interstitial). Shown when player taps "Use Life" before rescue animation. 3-second timeout -- skip silently if ad fails to load. ATT prompt required on first launch (iOS 14+).
- **Drag interaction**: 50pt vertical offset above touch point during drag to prevent finger occlusion. Preserve initial grab offset. Scale piece 1.15x during drag. Semi-transparent ghost preview on grid (green = valid, red = invalid).
- **Game flow state machine**: `GamePhase` enum with states `playing`, `animatingClear`, `stuck`, `rescuing`, `gameOver`. All model mutations gated behind animation completion.

---

## Non-Goals

- Multiplayer or online leaderboards (not mentioned -- exclude from v1)
- Undo/redo mechanic
- Time pressure / timer
- Sound design specification (implementation detail)
- Cross-platform (Android, web) support
- IAP / monetization beyond ads (out of scope for this spec)

---

## Acceptance Criteria

- [ ] A 9x9 grid renders in the top ~80% of the screen using earthy color palette
- [ ] A tray showing exactly 3 block pieces renders in the bottom ~20%
- [ ] Player can drag a piece from the tray; piece scales to 1.15x and offsets 50pt above touch during drag
- [ ] During drag, semi-transparent ghost shows on grid at snapped position (green = valid, red = invalid)
- [ ] A piece placement is rejected (3-frame shake, 0.15s, snap back) if it overlaps occupied cells or goes out of bounds
- [ ] Valid placement plays squash-and-stretch animation (scaleX 1.1 / scaleY 0.9, 0.1s bounce)
- [ ] Completing a full row clears that row with animation (flash white 0.05s, particle burst 0.3s, scale-to-zero 0.2s; total ~0.4s) and awards 9 pts
- [ ] Completing a full column clears with same animation and awards 9 pts
- [ ] Multiple rows/columns cleared in a single drop cascade sequentially with 0.1s stagger per line
- [ ] Each tray slot refills immediately when its piece is placed (tray always shows 3 pieces)
- [ ] A "stuck" state is detected when none of the 3 current tray pieces can be legally placed anywhere on the grid
- [ ] On stuck with lives > 0: "Use Life" button shown; interstitial ad plays (or skips after 3s); rescue algorithm clears lines until all 3 pieces fit; rescue sweep animation (0.5s horizontal sweep, cleared cells shrink+fade, remaining cells pulse)
- [ ] Rescue clears do NOT award score points
- [ ] When lives reach 0 and stuck state occurs: Game Over screen shown with final score, level
- [ ] Score display updates in real-time after each clear (warm cream text on dark background)
- [ ] Lives display shows current remaining lives (3 -> 2 -> 1 -> 0)
- [ ] Level advances at `targetScore(level) = 100 * level + 50 * level * (level - 1)` with visual feedback (banner slides in, holds 1.5s, slides out)
- [ ] Game Over screen shows: final score, level reached, and a "Play Again" button
- [ ] Play Again resets all state (board, score, lives, level, block style) and starts fresh
- [ ] All UI uses earthy tone palette defined in `ColorPalette.swift`; background `#3B2A1A`
- [ ] 5 block styles (Stone, Wood, Terracotta, Moss, Sand) render correctly with distinct colors/textures
- [ ] Full-board clear (all 81 cells empty) triggers style transition: wave sweep left-to-right (0.6s), per-column crossfade (0.1s staggered), celebratory particle burst (0.3s)
- [ ] ATT prompt on first launch; AdManager preloads interstitial on app launch
- [ ] `GamePhase` state machine governs all transitions with no illegal states

---

## Animation Specifications

### A. Line Clear (highest priority for game feel)
1. Row/column flashes bright white (0.05s)
2. Each cell simultaneously emits 6-8 small square particles (same color as block) scattering outward (0.3s, ease-out) via `SKEmitterNode`
3. Cells scale to 0 and fade out (0.2s, simultaneous with particles)
4. Total duration: ~0.4s
5. Multi-line clear: sequential cascade with 0.1s stagger per line

### B. Block Drop and Placement
- Valid drop: squash-and-stretch (scaleX 1.1 / scaleY 0.9 then bounce back, 0.1s)
- Invalid drop: snap back to tray with 3-frame wiggle shake (0.15s)

### C. Life Rescue Sequence
1. Player taps "Use Life" in stuck state
2. Interstitial ad shown (or skipped after 3s timeout)
3. Dramatic horizontal sweep across grid (bright line left-to-right, 0.5s)
4. Cleared cells shrink + fade as sweep passes
5. Remaining cells pulse briefly (0.2s)

### D. Block Style Transition (full-board clear)
1. Wave of warm light sweeps left-to-right (0.6s)
2. Columns crossfade to new style (0.1s per column, staggered: col 0 at t=0, col 8 at t=0.534s)
3. Total wave: ~0.7s
4. Celebratory particle burst from all cells (0.3s)

### E. Drag Ghost
- Semi-transparent ghost on grid at snapped position
- Green tint (valid) or red tint (invalid)
- Updates on every `touchesMoved`

### F. Other
- Score increment: number pulses up
- Level up: banner slides in from top, holds 1.5s, slides out
- Life used: life icon pulses red
- Game Over: overlay fades in

---

## Assumptions Exposed & Resolved

| Assumption | Challenge | Resolution |
|------------|-----------|------------|
| Game is purely tap-based | Asked what mechanic -- might be swipe/tilt | Confirmed: drag-and-drop (a tap-and-drag interaction) |
| Single-tap clears a block | Challenged with "what rule triggers a clear?" | Confirmed: complete row or column clears, not individual taps |
| Endless / high-score only | Asked about win/loss condition | Confirmed: level-based with target scores |
| No failure state | Contrarian probe on level structure | Confirmed: 3-lives system with smart board rescue on stuck |
| Game engine needed | Contrarian challenge on framework choice | Confirmed SpriteKit -- suitable for this puzzle type without full engine overhead |
| Standard tetromino grid (10x10) | Asked about grid size | Resolved: 9x9 (non-standard, intentional) |
| Pieces regenerate all-at-once | Asked in round 8 | Confirmed: each slot refills immediately when that piece is placed -- tray always has 3 pieces |

---

## Technical Context

Greenfield iOS project. Repository: `block-popper` (empty at time of interview).

**Recommended architecture:**
- `GameScene: SKScene` -- controller-scene hybrid; owns animation-gated game flow and sequences model mutations with `SKAction` chains
- `GridNode: SKNode` -- renders 9x9 grid cells, handles drop validation, style-aware
- `TrayNode: SKNode` -- renders 3 piece slots, handles drag initiation
- `BlockPiece` -- struct defining shape (array of (row, col) offsets), color, type
- `BlockStyle` -- enum with 5 cases (Stone, Wood, Terracotta, Moss, Sand), carrying fill/border colors, corner radius, texture name
- `GameState` -- model: score, level, lives, current tray pieces, grid occupancy matrix, GamePhase, current BlockStyle
- `LevelConfig` -- defines target score thresholds per level
- `ColorPalette` -- static constants for all earthy UI colors
- `AdManager` -- singleton wrapping Google Mobile Ads SDK
- `AnimationFactory` -- central factory for all SKAction sequences

**Pure model types** (`GameGrid`, `GameState`, `BlockPiece`) have no SpriteKit dependency and are unit-testable in isolation. Scene nodes (`GridNode`, `TrayNode`, `HUDNode`) are thin renderers that receive state via imperative push calls (no reactive/Combine bindings).

**Key algorithms required:**
1. **Drop validation**: given a piece shape and target position, check all cells are empty and in-bounds
2. **Clear detection**: after each placement, scan all rows and columns for full completion
3. **Stuck detection**: for each of the 3 tray pieces, check every valid grid position -- if no piece can be placed anywhere, trigger stuck state
4. **Life rescue**: clear 2 most-filled rows + 2 most-filled columns; iteratively clear more lines until all 3 tray pieces can be placed (worst-case: entire board cleared = guaranteed termination). Rescue clears do NOT award score points.

**Game flow state machine:**
```swift
enum GamePhase { case playing, animatingClear, stuck, rescuing, gameOver }
```
Transitions: playing -> animatingClear (lines completed), animatingClear -> playing (stuck check passed), animatingClear -> stuck (stuck check failed), stuck -> rescuing (life spent + ad), stuck -> gameOver (no lives), rescuing -> playing (rescue done).

---

## Ontology (Key Entities)

| Entity | Type | Fields | Relationships |
|--------|------|--------|---------------|
| GameScene | Core domain | grid, tray, score, level, lives, phase | owns GridNode, TrayNode, GameState |
| GridNode | Core domain | cells[9][9], occupancy matrix | contains Cell nodes |
| Cell | Supporting | row, col, isOccupied, color | part of GridNode |
| TrayNode | Core domain | slots[3] | holds BlockPiece nodes |
| BlockPiece | Core domain | shape (offsets), type, color | placed into GridNode |
| BlockStyle | Core domain | fillColor, borderColor, cornerRadius, textureName | used by GridNode, BlockPieceNode |
| GameState | Core domain | score, level, lives, currentPieces, phase, style | drives GameScene |
| GamePhase | Core domain | playing, animatingClear, stuck, rescuing, gameOver | owned by GameState |
| LevelConfig | Supporting | level, targetScore | used by GameState |
| Life | Supporting | count (0-3) | owned by GameState |
| AdManager | Supporting | interstitial state | used by GameScene on rescue |
| ColorPalette | Supporting | named color constants | used by all renderers |
| AnimationFactory | Supporting | SKAction builders | used by GameScene, GridNode |
| Row | Supporting | index, cellCount, filledCount | part of GridNode |
| Column | Supporting | index, cellCount, filledCount | part of GridNode |
| ScoreSystem | Supporting | pointsPerCell, comboMultiplier | used by GameState |
| SpriteKit Scene | External system | SKScene lifecycle | wraps GameScene |
| Google Mobile Ads | External system | interstitial ad lifecycle | wrapped by AdManager |

---

## Ontology Convergence

| Round | Entity Count | New | Changed | Stable | Stability Ratio |
|-------|-------------|-----|---------|--------|----------------|
| 1 | 1 | 1 | - | - | N/A |
| 2 | 2 | 1 | 0 | 1 | N/A (round 2) |
| 3 | 6 | 5 | 0 | 1 | 17% |
| 4 | 7 | 1 | 0 | 6 | 86% |
| 5 | 8 | 1 | 0 | 7 | 88% |
| 6 | 11 | 3 | 0 | 8 | 73% |
| 7 | 12 | 1 | 0 | 11 | 92% |

---

## Interview Transcript

<details>
<summary>Full Q&A (7 rounds)</summary>

### Round 1
**Q:** What is the core mechanic -- what does the player actually DO moment-to-moment?
**A:** Tap/touch to interact
**Ambiguity:** 86% (Goal: 0.20, Constraints: 0.10, Criteria: 0.10)

### Round 2
**Q:** What does the player see on screen and tap on -- what is the game world made of?
**A:** Blocks / tiles to pop or clear
**Ambiguity:** 73% (Goal: 0.45, Constraints: 0.15, Criteria: 0.15)

### Round 3
**Q:** How do blocks get cleared -- what triggers them to pop or disappear?
**A:** "There is a section at the bottom, using around 20% of the screen, where we show three different blocks. The player drags the blocks into the bigger section, which is a square, and drops it where he wants if it fits. If after dropping the block an entire row or column is filled with blocks, then the block pops and makes room for more blocks to be added."
**Ambiguity:** 57% (Goal: 0.75, Constraints: 0.25, Criteria: 0.20)

### Round 4
**Q:** What ends the game, and is there a score or levels?
**A:** Reach a target score to advance levels
**Ambiguity:** 42% (Goal: 0.85, Constraints: 0.25, Criteria: 0.55)

### Round 5 (Contrarian mode)
**Q:** What framework or engine should we use? (Challenging assumption that a game engine is required)
**A:** Native Swift + SpriteKit
**Ambiguity:** 33% (Goal: 0.85, Constraints: 0.55, Criteria: 0.55)

### Round 6 (Simplifier mode)
**Q:** What should the grid size be, and what do the block pieces look like?
**A:** "9x9 grid. Blocks: 2x2 square, 1x1 dot, 1x2, 2x1, 1x3, 1x4, 1x5, 3x2 L, 3x2 pyramid. More shapes will be added during implementation."
**Ambiguity:** 26% (Goal: 0.88, Constraints: 0.80, Criteria: 0.55)

### Round 7
**Q:** What's the simplest scoring + level-up system, and what triggers Game Over?
**A:** "Points per cell cleared; 3 lives. Game over when no piece fits and lives are zero. Using a life clears the two most-filled rows and columns, guaranteeing the current pieces will fit after clearing."
**Ambiguity:** 17% (Goal: 0.88, Constraints: 0.80, Criteria: 0.80)

</details>
