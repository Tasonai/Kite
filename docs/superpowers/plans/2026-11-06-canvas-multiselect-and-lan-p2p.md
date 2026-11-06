# Canvas Multi-Selection & LAN P2P Collaboration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement multi-selection with marquee dragging and group movements on the infinite canvas, subsystem container boxes, and zero-config LAN P2P peer discovery and live synchronization across macOS and Windows.

**Architecture:** 
1. Canvas Engine: Introduce `selectedElementIds: Set<String>`, marquee rectangle gesture detection, synchronized group translation delta, group deletion, and `CanvasGroup` container models into `CanvasModels.swift` and `CanvasModels.cs`.
2. LAN P2P Discovery: UDP beacon broadcast/listener on port 49494 announcing peer presence every 3 seconds, peer heartbeat pruning, and HUD peer discovery popover with one-click live sync handshake.
3. Parity: Full matching implementation across macOS (`Kite`), Windows (`KiteWin`), and Web Studio.

**Tech Stack:** Swift, SwiftUI, Network.framework / CocoaAsyncSocket / BSD sockets, C#, .NET 9, WinUI 3, System.Net.Sockets, REST/SSE.

**Spec:** Multi-selection & Group Dragging on canvas + Live Collaboration / LAN P2P Broadcast.

## Global Constraints

- STRICT ZERO EMOJIS: Absolute prohibition across all code, UI, comments, commits, and chat.
- Apple HIG 4pt/8pt grid layout on macOS.
- Windows 11 BAWA 4 epx grid layout on Windows.
- Backward compatibility: Existing canvas JSON files without `groups` must deserialize without errors.

## Review Focus

- Empty canvas click: Must clear multi-selection without triggering element actions.
- Marquee bounding box math: Negative coordinate drags (top-left direction) must correctly normalize into positive width/height `CGRect`.
- Group dragging delta: Dragging one element in a multi-selection must update all selected items by identical dx, dy without compounding offsets.
- UDP broadcast socket conflict: Multiple instances on the same host (e.g. testing macOS and Windows or simulator) must bind with `SO_REUSEADDR` / `SO_REUSEPORT` without crashing.
- Peer heartbeat timeout: Disconnected peers must be removed from the HUD within 10 seconds of beacon silence.

---

### Task 1: Canvas Data Models & Serialization Parity

**Files:**
- Modify: `/Users/tasonai/Developer/Kite/Sources/KiteKit/CanvasModels.swift`
- Modify: `/Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/Models/CanvasModels.cs`
- Modify: `/Users/tasonai/Developer/Kite/Sources/Kite/SelfTest.swift`

**Interfaces:**
- `CanvasGroup`: `id: String`, `title: String`, `position: [Double]`, `size: [Double]`, `colorHex: String`
- `CanvasState.groups: [CanvasGroup]` (defaults to empty array)

- [ ] **Step 1: Write test in SelfTest.swift for CanvasGroup encoding and decoding**
- [ ] **Step 2: Run test via quality_gate to verify compilation failure or test coverage**
- [ ] **Step 3: Update `CanvasModels.swift` with `CanvasGroup` and backward-compatible decoding in `CanvasState`**
- [ ] **Step 4: Update `CanvasModels.cs` in KiteWin.Core with matching `CanvasGroup`**
- [ ] **Step 5: Run tests and ensure pass**

---

### Task 2: macOS Canvas Marquee Selection, Group Dragging & Subsystem Containers

**Files:**
- Modify: `/Users/tasonai/Developer/Kite/Sources/Kite/InfiniteCanvasView.swift`

**Interfaces:**
- State: `selectedElementIds: Set<String>`, `marqueeStart: CGPoint?`, `marqueeCurrent: CGPoint?`
- Gesture: Drag on canvas background computes `selectionRect` and updates `selectedElementIds`.
- Group drag: Moving any element in `selectedElementIds` applies delta offset to all selected element offsets.
- Subsystem containers: Render `CanvasGroup` bounding cards behind sticky notes with editable title and drag support.
- Group deletion: Delete key removes all items in `selectedElementIds` and connected arrows.

- [ ] **Step 1: Add marquee selection state and gesture overlay in `InfiniteCanvasView.swift`**
- [ ] **Step 2: Implement synchronized group offset tracking in element drag gestures**
- [ ] **Step 3: Add `CanvasGroup` rendering and "Группировать" action in toolbar**
- [ ] **Step 4: Verify with `grid-lint.sh` and compile test**

---

### Task 3: LAN P2P Broadcast Discovery Engine for macOS

**Files:**
- Create: `/Users/tasonai/Developer/Kite/Sources/KiteKit/KiteLANBeacon.swift`
- Modify: `/Users/tasonai/Developer/Kite/Sources/KiteKit/KiteSyncServer.swift`
- Modify: `/Users/tasonai/Developer/Kite/Sources/Kite/InfiniteCanvasView.swift`
- Modify: `/Users/tasonai/Developer/Kite/Sources/Kite/SelfTest.swift`

**Interfaces:**
- `struct KitePeer: Identifiable, Equatable, Hashable, Codable`
- `final class KiteLANBeacon: ObservableObject, @unchecked Sendable`
  - `startBroadcasting(port: Int, instanceId: String, appName: String)`
  - `discoveredPeers: [KitePeer]`
  - `stop()`

- [ ] **Step 1: Write unit tests for beacon JSON parsing and peer pruning in `SelfTest.swift`**
- [ ] **Step 2: Implement UDP broadcast transmitter and receiver in `KiteLANBeacon.swift`**
- [ ] **Step 3: Integrate `KiteLANBeacon` into `KiteSyncServer` and canvas HUD popover**
- [ ] **Step 4: Run quality gate and verify zero-emoji compliance**

---

### Task 4: Windows Canvas Multi-Selection & LAN P2P Collaboration Parity

**Files:**
- Create: `/Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/Services/KiteLANBeacon.cs`
- Modify: `/Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/Services/KiteSyncServer.cs`
- Modify: `/Users/tasonai/Developer/KiteWindows/src/KiteWin/Pages/CanvasPage.xaml`
- Modify: `/Users/tasonai/Developer/KiteWindows/src/KiteWin/Pages/CanvasPage.xaml.cs`

**Interfaces:**
- `KiteLANBeacon`: `Start(int port, string instanceId, string appName)`, `DiscoveredPeers`
- Windows `CanvasPage`: Marquee canvas drag rectangle, `SelectedElementIds`, multi-item drag delta, peer indicator in top command bar.

- [ ] **Step 1: Implement `KiteLANBeacon.cs` with `UdpClient` broadcast on 49494**
- [ ] **Step 2: Integrate peer discovery into Windows top command bar**
- [ ] **Step 3: Add marquee selection and multi-item dragging in `CanvasPage.xaml.cs`**
- [ ] **Step 4: Verify C# build with `dotnet build`**

---

### Task 5: Web Studio Parity & Full System Verification

**Files:**
- Modify: `/Users/tasonai/Developer/Kite/Sources/KiteKit/WebStudio.swift`
- Modify: `/Users/tasonai/Developer/KiteWindows/src/KiteWin.Core/WebStudio.cs`

- [ ] **Step 1: Update Web Studio canvas with group container rendering and LAN peer HUD status**
- [ ] **Step 2: Run end-to-end P2P discovery test script**
- [ ] **Step 3: Run macOS full quality gate with all 42+ self-tests**
- [ ] **Step 4: Verify zero emojis across all changes**
