# Block Popper iOS -- Implementation Plan

**Date:** 2026-04-04
**Revised:** 2026-04-04 (post critic/architect review)
**Status:** APPROVED (Consensus: Architect + Critic, iteration 2)
**Complexity:** HIGH (greenfield game, ~22 source files, SpriteKit + AdMob + animation system)

---

## 1. Requirements Summary

Build a native iOS puzzle game (Swift + SpriteKit) where:
- A 9x9 grid occupies the top ~80% of the screen
- A tray of 3 block pieces occupies the bottom ~20%
- The player drags pieces from the tray onto the grid
- Completing a full row or column clears it (9 pts each)
- Multiple simultaneous clears score additively
- Each tray slot refills immediately after placement (tray always shows exactly 3 pieces)
- 3 lives per session; a life can rescue a stuck board via the rescue algorithm (see Step 2)
- Rescue clears do NOT award score points
- Levels advance at score thresholds: `targetScore(level) = 100 * level + 50 * level * (level - 1)` (tunable)
- 5 block style themes (earthy palette), cycled on full-board clear
- Interstitial ads (Google Mobile Ads SDK) shown before each life rescue
- Game Over when stuck with 0 lives remaining

> **Spec supersession note:** Spec line 74 (batch refill when all 3 placed) is superseded by Round 7 interview clarification -- each tray slot refills immediately when its piece is placed. The tray always shows exactly 3 pieces.

**Non-Goals:** Multiplayer, leaderboards, undo/redo, timer, cross-platform, IAP.

---

## 2. RALPLAN-DR Summary

### Principles
1. **Separation of game logic and rendering** -- GameState is a pure model; SKNodes only render and forward input.
2. **Testability first** -- Core algorithms (validation, clearing, stuck detection, rescue) must be unit-testable without SpriteKit.
3. **Minimal viable scope** -- Ship the 9 piece shapes listed in the spec; no extensibility framework for future shapes.
4. **Responsive layout** -- Use proportional sizing so the game works on iPhone SE through iPad without separate layouts.
5. **Earthy visual identity** -- All colors drawn from a named earthy palette defined in `ColorPalette.swift`.

### Decision Drivers
1. **Speed to playable prototype** -- Greenfield project, want a working game loop fast.
2. **Correctness of game logic** -- Clearing, stuck detection, and life-rescue algorithms are the core value; bugs here break the game.
3. **Touch UX quality** -- Drag-and-drop must feel responsive with clear visual feedback for valid/invalid placement.

### Option A: Monolithic GameScene (all logic in one SKScene)
| Pros | Cons |
|------|------|
| Fastest to write initially | Hard to test game logic without running SpriteKit |
| No coordination between objects | Becomes a 1000+ line god class quickly |
| Simple mental model | Difficult to extend or debug |

### Option B: MVC-style with Pure Model Layer (RECOMMENDED)
| Pros | Cons |
|------|------|
| GameState, Grid, BlockPiece are pure Swift structs -- fully unit-testable | Slightly more files up front |
| SKNodes are thin renderers driven by model state | Requires clear ownership boundaries |
| Algorithms can be developed and verified before any UI | Minor indirection for simple operations |

**Decision:** Option B. The core risk in this project is algorithmic correctness (stuck detection, life rescue). Pure model types let us write exhaustive unit tests for these algorithms without SpriteKit test hosts. The additional file count (~5 extra files) is trivial for the testability gain.

### ADR
- **Decision:** MVC-style with pure model layer
- **Drivers:** Testability of game algorithms, speed to working game loop, maintainability
- **Alternatives considered:** Monolithic GameScene
- **Why chosen:** Core algorithms (stuck detection, rescue) are complex enough to warrant isolated unit testing; Option A makes this impractical
- **Consequences:** Model and rendering code are separate; all game state mutations go through GameState; SKNodes observe/render state. `GameScene` is a controller-scene hybrid (see Architecture Note below).
- **Follow-ups:** None required for initial scope

### Architecture Note

`GameScene` is a controller-scene hybrid, not a thin renderer. It owns the animation-gated game flow and sequences model mutations with `SKAction` chains. Pure model types (`GameGrid`, `GameState`, `BlockPiece`) have no SpriteKit dependency and are unit-testable in isolation. Scene nodes (`GridNode`, `TrayNode`, `HUDNode`) are thin renderers that receive state via imperative push calls (no reactive/Combine bindings).

---

## 3. Game Flow State Machine

```swift
enum GamePhase {
    case playing
    case animatingClear
    case stuck
    case rescuing
    case gameOver
}
```

### Transitions

| From | To | Trigger |
|------|----|---------|
| `playing` | `animatingClear` | Piece placed, at least one row/col completed |
| `playing` | `playing` | Piece placed, no lines completed, stuck check passed |
| `playing` | `stuck` | Piece placed, no lines completed, stuck check FAILED |
| `animatingClear` | `playing` | Clear animation finished. **Full-board check:** after `clearFullLines()` completes and before tray refill, check if all 81 cells are empty — if so, call `advanceStyle()` and play style transition animation (0.7s); input remains blocked (phase stays `animatingClear`) until transition completes. Then tray slot refills, stuck check passed. |
| `animatingClear` | `stuck` | Clear animation finished, tray slot refilled, stuck check FAILED |
| `stuck` | `rescuing` | Player confirms life spend (ad shown first via AdManager) |
| `stuck` | `gameOver` | `lives == 0` |
| `rescuing` | `playing` | Rescue algorithm complete, all 3 pieces verified to fit |
| `rescuing` | `gameOver` | `lives == 0` (defensive -- should not occur mid-rescue but handle it) |

`GameScene` gates all model mutations behind animation completion. No model state changes during `animatingClear` or `rescuing` phases except the rescue algorithm itself.

---

## 4. Acceptance Criteria

| # | Criterion | Verification |
|---|-----------|-------------|
| AC-1 | 9x9 grid renders in top ~80% of screen on iPhone SE and iPhone 15 Pro | Visual inspection on simulator |
| AC-2 | Tray shows exactly 3 block pieces in bottom ~20% | Visual inspection |
| AC-3 | Dragging a piece from tray: piece scales to 1.15x, offsets 50pt above touch, follows finger preserving initial grab offset | Manual touch test |
| AC-4 | During drag, semi-transparent ghost renders on grid at snapped position: green tint if valid, red tint if invalid; updates every `touchesMoved` | Manual test |
| AC-5 | Dropping on valid position: squash-and-stretch animation (scaleX 1.1 / scaleY 0.9 bounce back, 0.1s), cells fill with piece color in current block style | Manual test + unit test for validation logic |
| AC-6 | Dropping on invalid position: piece shakes (3-frame wiggle, 0.15s) then snaps back to tray | Manual test + unit test |
| AC-7 | Completing a full row clears it and awards 9 pts; clear animation: flash white (0.05s), 6-8 square particles scatter outward (0.3s ease-out), cells scale to 0 + fade (0.2s); total ~0.4s | Unit test (scoring) + manual test (animation) |
| AC-8 | Completing a full column: same clear animation and 9 pts | Unit test + manual test |
| AC-9 | Multi-line clear (2+ lines in one drop): sequential cascade with 0.1s stagger per line | Manual test |
| AC-10 | Tray slot refills immediately after piece placed | Manual test |
| AC-11 | Stuck state detected correctly (no piece fits anywhere) | Unit test with crafted board states |
| AC-12 | Stuck + lives > 0: "Use Life" button shown; on tap, interstitial ad plays (or skipped after 3s timeout); then rescue animation (horizontal sweep 0.5s, cleared cells shrink+fade, remaining cells pulse); board state guaranteed playable | Unit test (algorithm) + manual test (animation + ad) |
| AC-13 | Rescue clears do NOT award score points | Unit test |
| AC-14 | Stuck + lives == 0: Game Over screen with final score, level, Play Again | Manual test |
| AC-15 | Score and lives update in real-time on HUD (warm cream text on dark background) | Manual test |
| AC-16 | Level advances at `targetScore(level) = 100 * level + 50 * level * (level - 1)` -- Level 1: 100, Level 2: 300, Level 3: 600, Level 4: 1000 | Unit test |
| AC-17 | Play Again resets all state and starts fresh game | Manual test |
| AC-18 | All UI uses earthy tone palette defined in `ColorPalette.swift`; background deep warm brown (#3B2A1A); grid cells lighter brown with subtle border; HUD warm cream/off-white | Visual inspection |
| AC-19 | Full-board clear (all 81 cells empty after a placement) triggers block style transition: wave sweep left-to-right (0.6s), columns crossfade to new style (0.1s per column staggered), celebratory particle burst (0.3s) | Manual test |
| AC-20 | 5 block styles cycle on full-board clear: Stone, Wood, Terracotta, Moss, Sand | Manual test |
| AC-21 | ATT prompt shown on first launch; AdManager preloads interstitial on app launch | Manual test on device |
| AC-22 | `GamePhase` state machine governs all transitions; no illegal phase transitions possible | Unit test |

---

## 5. Implementation Steps

### Xcode Project Structure

```
BlockPopper/
  BlockPopper.xcodeproj
  BlockPopper/
    App/
      AppDelegate.swift
      GameViewController.swift
    Model/
      BlockPiece.swift          -- Shape definitions (offsets, color, type enum)
      BlockStyle.swift           -- 5 style themes (Stone, Wood, Terracotta, Moss, Sand)
      GameGrid.swift             -- 9x9 occupancy matrix, placement, clearing, rescue
      GameState.swift            -- Score, level, lives, current tray pieces, GamePhase
      LevelConfig.swift          -- Score thresholds per level
      PieceGenerator.swift       -- Random piece selection for tray refill
    Scene/
      GameScene.swift            -- SKScene controller-hybrid, owns nodes + animation-gated flow
      GridNode.swift             -- Renders 9x9 grid cells, drop target, style-aware
      TrayNode.swift             -- Renders 3 piece slots, drag source
      BlockPieceNode.swift       -- SKNode for a draggable piece, style-aware
      HUDNode.swift              -- Score, lives, level display
      GameOverNode.swift         -- Game Over overlay
      AnimationFactory.swift     -- All SKAction sequences: clear, rescue, style transition, drag feedback
    Ads/
      AdManager.swift            -- Singleton wrapping Google Mobile Ads SDK
    Helpers/
      ColorPalette.swift         -- All named earthy colors as static constants
      Constants.swift            -- Grid size, layout proportions, timing constants
      Extensions.swift           -- CGPoint/CGSize helpers, grid coordinate conversion
    Assets.xcassets
    LaunchScreen.storyboard
    Info.plist                   -- Includes NSUserTrackingUsageDescription
  BlockPopperTests/
    Model/
      GameGridTests.swift
      GameStateTests.swift
      BlockPieceTests.swift
      PieceGeneratorTests.swift
      LevelConfigTests.swift
```

---

### Step 1: Project Scaffolding, Model Types, and Color Palette

**What:** Create the Xcode project structure, define all model types, piece shape catalog, block styles, color palette, and level config.

**Files to create:**
- `BlockPopper.xcodeproj` (SpriteKit game template or SPM-based)
- `Model/BlockPiece.swift` -- `PieceType` enum with 9 shapes, `BlockPiece` struct with `offsets: [(Int, Int)]`, `color`, `type`
- `Model/BlockStyle.swift` -- enum with 5 cases:
  - `.stone`: fill `#8B7D6B`, border `#6B5D4B`, cornerRadius 4, no texture
  - `.wood`: fill `#A07B5A`, border `#7A5B3A`, cornerRadius 3, woodGrain overlay
  - `.terracotta`: fill `#C4613A`, border `#A4412A`, cornerRadius 2, roughEdge
  - `.moss`: fill `#4A6B3A`, border `#2A4B1A`, cornerRadius 5, organicBorder
  - `.sand`: fill `#D4BC8A`, border `#B49C6A`, cornerRadius 3, subtleGradient
  Each case carries: `fillColor: UIColor`, `borderColor: UIColor`, `cornerRadius: CGFloat`, `textureName: String?`
- `Model/GameGrid.swift` -- `GameGrid` struct with `cells: [[CellState]]` (9x9), methods: `canPlace(piece:at:) -> Bool`, `place(piece:at:)`, `clearFullLines() -> ClearResult`, `isBoardStuck(pieces:) -> Bool`
- `Model/GameState.swift` -- `GameState` with `score`, `level`, `lives`, `grid`, `trayPieces[3]`, `phase: GamePhase`, `currentStyle: BlockStyle`; methods: `placePiece(index:at:)`, `useLife()`, `checkLevelUp()`
- `Model/LevelConfig.swift` -- `targetScore(forLevel:) -> Int` using formula: `100 * level + 50 * level * (level - 1)` -- Level 1: 100, Level 2: 300, Level 3: 600, Level 4: 1000. Marked as tunable.
- `Model/PieceGenerator.swift` -- Weighted random piece selection
- `Helpers/ColorPalette.swift` -- static constants:
  - `background: #3B2A1A` (deep warm brown)
  - `gridCellEmpty: #5A4A3A` (lighter brown)
  - `gridCellBorder: #4A3A2A`
  - `hudText: #F5E6D0` (warm cream)
  - `hudTextSecondary: #D4BC8A`
  - `ghostValid: UIColor.green.withAlphaComponent(0.3)`
  - `ghostInvalid: UIColor.red.withAlphaComponent(0.3)`
- `Helpers/Constants.swift` -- Grid dimensions, layout ratios, timing constants (all animation durations as named constants)

**Acceptance criteria:**
- All 9 piece shapes defined with correct cell offsets
- 5 block styles defined with earthy fill/border colors, corner radius, and texture name
- `ColorPalette.swift` contains all named color constants
- `LevelConfig.targetScore(forLevel: 1)` returns 100; `forLevel: 2` returns 300; `forLevel: 3` returns 600; `forLevel: 4` returns 1000
- `GameGrid.canPlace()` returns correct results for in-bounds, out-of-bounds, and overlap cases
- `GameGrid.clearFullLines()` identifies and clears completed rows/columns
- Unit tests pass for all model types

---

### Step 2: Core Game Algorithms (Clearing, Stuck Detection, Rescue)

**What:** Implement and thoroughly test the 4 key algorithms: drop validation, clear detection, stuck detection, and life rescue. The rescue algorithm is the highest-risk component.

**Files to modify:**
- `Model/GameGrid.swift` -- Implement `clearFullLines()`, `isBoardStuck(pieces:)`, `rescueBoard(pieces:)`

**Rescue algorithm (must be implemented as specified):**

```
func rescueBoard(pieces: [BlockPiece]) -> Void {
    // Step 1: Clear the 2 most-filled rows + 2 most-filled columns
    let sortedRows = rows.sorted(by: filledCount, descending)
    let sortedCols = columns.sorted(by: filledCount, descending)
    clear(rows: sortedRows.prefix(2))
    clear(columns: sortedCols.prefix(2))
    // Note: Row and column clears are independent. If a cell sits at the intersection
    // of a cleared row and a cleared column, the second clear is a no-op on that cell.

    // Step 2: Iteratively clear more lines until all pieces fit
    let remainingLines = (allRows + allCols)
        .excluding(already cleared)
        .sorted(by: filledCount, descending)

    while any piece in `pieces` cannot be placed anywhere on the grid {
        let nextLine = remainingLines.removeFirst()  // most-filled-first
        clear(nextLine)
        if board is empty { break }  // guaranteed termination backstop
    }

    // Postcondition: all 3 pieces can be placed on the grid
    // (empty board always accommodates any piece)

    // IMPORTANT: rescue clears do NOT award score points
}
```

- Return type is `Void` -- the algorithm is guaranteed to succeed because clearing the entire board is the worst-case backstop and is acceptable for v1.
- Rescue clears do NOT award score points (prevents exploiting intentional stuck states).
- `Model/GameState.swift` -- Wire algorithms into game flow following the `GamePhase` state machine: place -> clear -> check stuck -> rescue or game over

**Test files to create:**
- `BlockPopperTests/Model/GameGridTests.swift` -- Tests for:
  - Place validation (valid, overlap, OOB)
  - Row clear (single, multiple)
  - Column clear (single, multiple)
  - Simultaneous row + column clear
  - Stuck detection (stuck and not-stuck boards)
  - Rescue: clears 2 most-filled rows + 2 most-filled cols
  - Rescue: guarantees all 3 pieces fit after clearing
  - Rescue: iteratively clears additional lines when initial 4-line clear is insufficient
  - Rescue: worst-case empty-board backstop terminates
  - Rescue: does not modify score
- `BlockPopperTests/Model/GameStateTests.swift` -- Tests for:
  - Score increments correctly (9 per line)
  - Lives decrement on rescue
  - Level advances at threshold (100, 300, 600, 1000)
  - Game over triggered at 0 lives + stuck
  - `GamePhase` transitions match the state machine (no illegal transitions)
- `BlockPopperTests/Model/LevelConfigTests.swift` -- Verify formula for levels 1-10

**Acceptance criteria:**
- All algorithm unit tests pass
- Stuck detection correctly handles edge cases (nearly full board, L-shaped pieces)
- Rescue algorithm tested with 50+ random near-full board configurations; all pass postcondition (every tray piece can be placed)
- Rescue never awards score points (verified by unit test)
- `GamePhase` transitions tested: all 9 transitions from state machine table produce correct results; illegal transitions (e.g., `playing -> rescuing`) are rejected or impossible

---

### Step 3: SpriteKit Rendering Layer with Earthy Theme

**What:** Build the visual layer -- grid, tray, HUD, piece nodes -- all styled with the earthy color palette. No interaction yet, just static rendering driven by GameState.

**Files to create:**
- `App/AppDelegate.swift` -- Standard SpriteKit app delegate; trigger ATT prompt on first launch
- `App/GameViewController.swift` -- Presents GameScene, handles device rotation lock (portrait)
- `Scene/GameScene.swift` -- Creates and positions GridNode, TrayNode, HUDNode; initializes GameState; owns `GamePhase`
- `Scene/GridNode.swift` -- Renders 9x9 grid of cell sprites using `ColorPalette` colors; method `updateFromGrid(_:style:)` syncs visual state; accepts `BlockStyle` for re-skinning
- `Scene/TrayNode.swift` -- Renders 3 piece slots positioned at bottom; method `updatePieces(_:style:)` refreshes display
- `Scene/BlockPieceNode.swift` -- Composite SKNode for a piece shape; configurable via `BlockStyle` (fill color, border color, corner radius, texture)
- `Scene/HUDNode.swift` -- SKLabelNodes for score, level, lives count; warm cream text (`ColorPalette.hudText`) on dark background
- `Helpers/Extensions.swift` -- Grid coordinate <-> scene point conversion helpers

**Acceptance criteria:**
- Grid renders correctly on iPhone SE (smallest) and iPhone 15 Pro Max (largest) simulators
- Grid occupies ~80% of screen height, tray ~20%
- All 9 piece shapes render correctly in the tray
- HUD displays score: 0, level: 1, lives: 3 in warm cream text
- Background is `#3B2A1A`; grid empty cells are `#5A4A3A` with `#4A3A2A` border
- Cell sizes scale proportionally to screen size
- `GridNode` and `BlockPieceNode` correctly render all 5 block styles when given different `BlockStyle` values

---

### Step 4: Drag-and-Drop Interaction with Ghost Preview

**What:** Implement the complete touch interaction: pick up piece from tray, drag with visual feedback (offset, scale, ghost preview), snap to grid on valid drop, reject on invalid drop.

**Files to modify:**
- `Scene/GameScene.swift` -- Touch handling with proper offset tracking:
  - `touchesBegan`: record `dragOffset = piece.position - touchLocation`; scale piece to 1.15x
  - `touchesMoved`: `piece.position = touchLocation + dragOffset + CGVector(dx: 0, dy: 50)` (50pt above touch to prevent finger occlusion); update ghost preview on grid
  - `touchesEnded`: attempt placement or snap back; restore scale to 1.0
- `Scene/GridNode.swift` -- Add `showGhost(for:at:valid:)`: semi-transparent overlay at snapped position, green tint (`ColorPalette.ghostValid`) for valid placement, red tint (`ColorPalette.ghostInvalid`) for invalid; `hideGhost()`; `snapPosition(for:near:) -> GridPosition?` for grid snapping
- `Scene/TrayNode.swift` -- Detect which piece slot was touched; hide piece visually during drag
- `Scene/BlockPieceNode.swift` -- Scale animation on pickup (1.0 -> 1.15x)

**Game flow on drop:**
1. `GridNode.snapPosition()` finds nearest valid grid cell
2. `GameState.placePiece()` validates and places via `GameGrid.canPlace()`
3. If valid: squash-and-stretch animation (scaleX 1.1 / scaleY 0.9, bounce back, 0.1s), cells fill, transition `GamePhase` to `animatingClear` if lines completed or check stuck
4. If invalid: shake animation (3-frame wiggle, 0.15s), piece snaps back to tray
5. After placement: check stuck state via `GamePhase` state machine

**Acceptance criteria:**
- Piece follows finger smoothly during drag, offset 50pt above touch point
- Initial grab offset preserved (piece does not jump to finger center)
- Piece scales to 1.15x during drag, 1.0x on drop
- Ghost preview renders on grid at snapped position: green when valid, red when invalid
- Ghost updates on every `touchesMoved` call
- Valid drop plays squash-and-stretch (0.1s)
- Invalid drop plays shake (0.15s) then snaps back
- Valid drop fills grid cells and immediately refills the tray slot

---

### Step 5: Animations, Ads, Game Flow, and Polish

**What:** Wire up the complete game loop with the `GamePhase` state machine. Implement all animations, ad integration, life rescue UX, game over, and block style transitions.

**Files to create:**
- `Scene/GameOverNode.swift` -- Overlay with final score, level reached, Play Again button
- `Scene/AnimationFactory.swift` -- Central factory for all `SKAction` sequences (keeps `GameScene` lean)
- `Ads/AdManager.swift` -- Singleton wrapping Google Mobile Ads SDK:
  - Preload interstitial on app launch
  - Reload after each show
  - `showInterstitial(from viewController: UIViewController, completion: @escaping () -> Void)`
  - If ad fails to load or times out (>3s): call completion immediately (skip silently)

**Files to modify:**
- `Scene/GameScene.swift` -- `GamePhase` state machine orchestration; all model mutations gated behind animation completion
- `Scene/GridNode.swift` -- Clear animation, rescue animation, style transition animation
- `Scene/HUDNode.swift` -- Animate score counter, lives indicator, level-up banner
- `Model/GameState.swift` -- `resetGame()` method for Play Again; `advanceStyle()` on full-board clear
- `Info.plist` -- Add `NSUserTrackingUsageDescription` ("We use tracking to show relevant ads"), `GADApplicationIdentifier`

**Animation specifications (implemented in `AnimationFactory.swift`):**

**A. Line clear (highest priority for game feel):**
1. Row/column flashes bright white (0.05s)
2. Each cell simultaneously emits 6-8 small square particles (same color as block) that scatter outward (0.3s, ease-out) via `SKEmitterNode`
3. Cells scale to 0 and fade out (0.2s, simultaneous with particles)
4. Total duration: ~0.4s
5. Multi-line clear: sequential cascade -- each line clears with 0.1s stagger (line 1 at t=0, line 2 at t=0.1s, etc.)

**B. Block drop and placement:**
- Valid drop: squash-and-stretch (scaleX 1.1 / scaleY 0.9 then bounce back, 0.1s)
- Invalid drop: snap back to tray with 3-frame wiggle shake (0.15s)

**C. Life rescue sequence:**
1. Player taps "Use Life" in stuck state
2. AdManager shows interstitial (or skips after 3s timeout)
3. On ad dismiss: dramatic horizontal sweep across grid (bright line sweeps left-to-right, 0.5s)
4. Cleared cells animate out (shrink + fade) as sweep passes over them
5. Remaining cells pulse briefly (0.2s) to signal board is still active

**D. Block style transition (full-board clear):**
1. Wave of warm light sweeps left-to-right across grid (0.6s)
2. As wave passes each column, blocks transform to new style (0.1s crossfade per column)
3. Stagger: column 0 at t=0, column 1 at t=0.067s, ..., column 8 at t=0.534s (total wave ~0.6s + 0.1s last column = ~0.7s)
4. After transition: celebratory particle burst from all cells (0.3s)
5. Implement as `SKAction` sequence on `GridNode`

**E. Drag ghost:** (implemented in Step 4, listed here for completeness)
- Semi-transparent ghost on grid at snapped position; green valid, red invalid; updates every `touchesMoved`

**F. Other animations:**
- Score increment: number pulses up
- Level up: banner slides in from top, holds 1.5s, slides out
- Life used: life icon pulses red
- Game Over: overlay fades in with score and Play Again button

**Ad integration flow:**
1. `AppDelegate` initializes Google Mobile Ads SDK and requests ATT permission
2. `AdManager.shared.preloadInterstitial()` called on app launch
3. On stuck state with lives > 0: UI shows "Use Life" button
4. Player taps "Use Life" -> `lives -= 1` immediately -> `GamePhase` transitions to `rescuing` -> `AdManager.showInterstitial(from:completion:)` called. Life counter decrements before the ad is shown; if the ad fails/skips, rescue still proceeds — the life is already spent.
5. On ad dismiss (or 3s timeout/failure): rescue animation plays -> board cleared -> `GamePhase` transitions to `playing`
6. `AdManager` reloads next interstitial in background

**Acceptance criteria:**
- Line clear animation plays in ~0.4s with white flash + particle burst + cell scale-to-zero
- Multi-line clears cascade with 0.1s stagger between lines
- Valid drop squash-and-stretch plays in 0.1s
- Invalid drop shake plays in 0.15s
- Rescue sweep animation plays in 0.5s left-to-right
- Style transition wave plays in ~0.7s with per-column stagger
- Interstitial ad shows before rescue (or skips silently after 3s)
- ATT prompt appears on first launch
- Game Over overlay appears with correct score and level
- Play Again resets board, score, lives, level, style and starts fresh
- Full-board clear advances block style and plays transition animation
- All `GamePhase` transitions match the state machine table in section 3

---

### Step 6: Tuning, Edge Cases, and Final QA

**What:** Tune level thresholds, verify edge cases, final polish pass, performance profiling.

**Tasks:**
- Verify level score thresholds: Level 1 = 100, Level 2 = 300, Level 3 = 600, Level 4 = 1000 (formula: `100 * level + 50 * level * (level - 1)`, tunable)
- Test rescue fallback: when clearing 2 rows + 2 cols is insufficient, algorithm iteratively clears more lines until all pieces fit (or board is empty)
- Test rescue does not award score points across all code paths
- Test simultaneous multi-line clears (e.g., place a piece that completes 2 rows and 1 column at once = 27 pts)
- Verify piece generation produces reasonable distribution (no 3x identical pieces)
- Test full-board clear detection and style cycling (style 1 -> 2 -> 3 -> 4 -> 5 -> 1)
- Test ad timeout path (simulate ad load failure, verify rescue proceeds after 3s)
- Performance test: fill grid to near capacity, verify no frame drops during stuck detection
- Test on physical device for touch responsiveness
- Verify all colors match `ColorPalette.swift` definitions on device

**Acceptance criteria:**
- Level thresholds match formula for levels 1-10
- No crash or incorrect state for any board configuration
- Stuck detection completes in < 16ms (one frame at 60fps) even on worst case
- Touch latency feels immediate on physical device
- All 5 block styles render correctly and cycle on full-board clear
- Ad failure gracefully handled (rescue proceeds within 3s)
- All earthy colors render correctly on device (not washed out on different display profiles)

---

## 6. Risks and Mitigations

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Rescue algorithm fails to guarantee playable board | Game-breaking (soft lock) | Medium | Unit test with 50+ random near-full boards; iterative fallback clears until all pieces fit or board is empty (guaranteed termination) |
| Drag-and-drop feels laggy or imprecise | Poor UX, game feels broken | Medium | Use SpriteKit's native touch handling (not UIKit gesture recognizers); 50pt offset + grab-point preservation; test on physical device early in Step 4 |
| Grid layout breaks on smaller screens (iPhone SE) | Visual bugs | Low | Use proportional sizing from Constants.swift; test on SE simulator in Step 3 |
| Stuck detection too slow on near-full boards | Frame drops, perceived freeze | Low | Worst case: 3 pieces x 81 positions x ~5 cells each = ~1200 checks -- trivial for modern hardware; profile if needed |
| Google Mobile Ads SDK integration issues | Blocked ad revenue | Medium | Isolate in `AdManager.swift` with 3s timeout fallback; game flow never blocks on ad |
| ATT rejection rate high (user denies tracking) | Reduced ad revenue | High | Non-blocking -- game functions without tracking; ads still show (non-personalized) |
| Xcode project generation without Xcode GUI | Build failures | Medium | Use `swift package init` for SPM-based project or generate xcodeproj with known-good template; verify builds before proceeding |

---

## 7. Verification Steps

1. **Unit tests (Step 2):** Run `xcodebuild test` -- all GameGrid, GameState, LevelConfig tests pass; rescue postcondition verified on 50+ random boards
2. **Visual verification (Step 3):** Screenshot grid on iPhone SE and iPhone 15 Pro Max simulators; grid is proportional and centered; earthy palette applied; all 5 block styles render
3. **Interaction verification (Step 4):** Screen recording of drag-and-drop on simulator; piece follows touch with 50pt offset, ghost preview shows green/red, snaps correctly, rejects invalid placements with shake
4. **Animation verification (Step 5):** Screen recording of line clear (0.4s with particles), rescue sweep (0.5s), style transition wave (0.7s); all timing matches spec
5. **Ad verification (Step 5):** Test interstitial shows before rescue; test timeout fallback (disconnect network, verify rescue proceeds in 3s)
6. **Game flow verification (Step 5):** Play through to Game Over; verify score, level, lives, clear animations, rescue, ad, style transitions, and game over screen all work correctly; verify `GamePhase` never enters illegal state
7. **Edge case verification (Step 6):** Run extended unit test suite with randomized board states; no assertion failures
8. **Performance verification (Step 6):** Instruments profiling on physical device; no frame drops below 60fps during gameplay

---

## Summary

- **6 steps** across **~22 source files** + **5 test files**
- **Estimated effort:** 5-7 days for an experienced Swift/SpriteKit developer
- **Critical path:** Steps 1-2 (model + algorithms) gate everything; Step 4 (drag-and-drop) is the highest UX risk; Step 5 (animations + ads) is the most complex
- **Key architectural decision:** Pure model layer (Option B) enables thorough testing of game algorithms without SpriteKit dependency
- **New in revision:** Rescue algorithm pseudocode, GamePhase state machine, earthy color palette, 5 block styles, AdMob integration, detailed animation specs with exact timing, drag ghost preview, touch offset/occlusion handling
