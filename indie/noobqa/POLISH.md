# NoobQA — Pre-Release Polish Plan

> Last updated: 2026-03-29

---

## Part 1 — Core (Product Polish)

Make the product solid, self-contained, and frictionless before worrying about branding or distribution.

---

### 1. Make Noober Optional (But Nudge Hard)

**Goal:** Users can run NoobQA with zero SDK integration. But Noober should feel like an obvious upgrade, not a prerequisite.

**Current state:**
- `AgentService.swift` pre-registers all NooberMCP tools (lines 193-225) as allowed tools
- `SystemPrompt.swift` references Noober tools throughout both prompts
- `SetupService.swift` checks NooberMCP as a prerequisite
- `MCPService.swift` auto-installs NooberMCP on first run
- If NooberMCP isn't available, agent crashes or gets confused trying to call unavailable tools

**Implementation:**

#### A. Detect Noober availability at runtime
```
AgentService.swift:
- Before building tool list, check if NooberMCP binary exists (MCPService.findNooberMCP())
- If found: include all noober_* tools in allowedTools
- If not found: exclude all noober_* tools, rely on simulator-only tools
```

#### B. Two system prompt variants
```
SystemPrompt.swift:
- Add a `nooberAvailable: Bool` parameter to both build functions
- When nooberAvailable == false:
  - Remove all noober_* tool references
  - Replace "use noober_screen_html" with "use snapshot_ui for view hierarchy"
  - Replace "noober_assert_request" with "verify via UI output only"
  - Replace "noober_get_app_logs" with "check visible error states on screen"
  - Add note: "You cannot inspect network requests or app logs. Verify via UI only."
- When nooberAvailable == true:
  - Current behavior (full Noober tool access)
```

#### C. Nudge user to add Noober
```
ContentView.swift / SetupView.swift:
- If Noober not detected, show a subtle banner:
  "Tip: Add Noober SDK for deeper testing (network logs, app state, API verification)"
  [Learn More] → opens docs page explaining what Noober unlocks
- Don't block. Don't nag repeatedly. Show once per session.

OnboardingView.swift (Step 4 — MCPs):
- Change NooberMCP from "required" to "recommended"
- Show comparison: "Without Noober: UI testing only | With Noober: UI + API + logs + state"
- Allow skipping NooberMCP installation
```

#### D. Auto-integrate Noober (Dev Mode bonus)
```
In Dev Mode (has codebase access), offer:
"I can add Noober SDK to your project automatically. Want me to?"
→ Agent uses Read/Grep to find Package.swift or Podfile
→ Adds Noober dependency
→ Adds Noober.setup() to AppDelegate/App init
→ Rebuilds and verifies

This is a stretch goal — implement only if time allows.
Low priority since most users can add a dependency themselves.
```

#### E. Update SetupService
```
SetupService.swift:
- Change NooberMCP check from "error" to "warning" state
- setupStatus.nooberMCP = .warning("Not installed — testing limited to UI only")
- isReady should return true even without Noober
```

#### F. Update MCPService
```
MCPService.swift:
- Don't auto-install NooberMCP on first run
- Only install when user explicitly enables it in Settings or Onboarding
- Add uninstall option (claude mcp remove NooberMCP)
```

**Files to modify:**
- `AgentService.swift` — conditional tool list
- `SystemPrompt.swift` — nooberAvailable parameter + fallback prompt sections
- `SetupService.swift` — NooberMCP check as warning, not error
- `MCPService.swift` — remove auto-install, add explicit install/uninstall
- `ContentView.swift` — nudge banner
- `OnboardingView.swift` — NooberMCP as optional step
- `Models.swift` — SetupStatus.isReady should not require NooberMCP

**Effort:** 3-4 days

---

### 2. Error Handling (Critical Paths)

**Goal:** Every failure shows a clear message + actionable fix. No cryptic errors.

**Current state:**
- `AgentService.swift` catches process exit codes but shows generic messages
- `SetupService.swift` detects issues but instructions are text-only (no buttons)
- If Claude API key is invalid → exit code 1 → "The agent exited unexpectedly"
- If bundle ID wrong → app silently fails to launch → agent tries to test nothing
- `MCPService.swift` has no timeout on `claude mcp list` (can hang forever)

**Implementation:**

#### A. Claude CLI errors (AgentService.swift)
```
Map exit codes to user-friendly messages:

Exit 1 + stderr contains "auth":
  → "Claude authentication failed. Run 'claude login' in your terminal."
  → [Open Terminal] button

Exit 1 + stderr contains "rate":
  → "Claude API rate limit hit. Wait a moment and try again."

Exit 1 + stderr contains "model":
  → "Model not available. Try switching to Sonnet in Settings."

Exit 127:
  → "Claude CLI not found at {path}. Check Settings → General → Claude CLI Path."
  → [Open Settings] button

Exit 137 (SIGKILL):
  → "Test was stopped." (not an error — user killed it)

Exit code != 0 + no stderr match:
  → "Test failed unexpectedly. Error: {last 500 chars of stderr}"
  → [Copy Error] [Try Again] buttons
```

#### B. Simulator errors (AgentService.swift)
```
detectBootedSimulator() returns nil:
  → "No iOS Simulator is booted."
  → [Boot Simulator] button that runs: xcrun simctl boot <first-available-udid>
  → Auto-retry detection after boot

Bundle ID launch fails (xcrun simctl launch returns non-zero):
  → "App '{bundleId}' is not installed on the simulator."
  → [Install App] button (opens file picker for .app/.ipa)
  → Show the bundle ID that was tried
```

#### C. MCP errors (MCPService.swift)
```
claude mcp list hangs:
  → Add 10-second timeout to all Process executions in MCPService
  → On timeout: "Could not connect to Claude MCP. Is Claude CLI working?"

NooberMCP shows "Failed":
  → "NooberMCP failed to start. The app may not have Noober SDK integrated."
  → [Reinstall] [Skip Noober] buttons

Figma Desktop not running:
  → "Figma Desktop is not running."
  → [Open Figma] button (NSWorkspace.shared.open for Figma.app)

Linear OAuth needed:
  → "Linear needs authentication."
  → [Authenticate] button that opens Linear OAuth URL
```

#### D. Setup errors (SetupService.swift)
```
Xcode not installed:
  → "Xcode Command Line Tools not found."
  → [Install] button that runs: xcode-select --install

Xcode license not accepted:
  → Detect via xcodebuild -version returning license error
  → "Xcode license not accepted. Run this in Terminal:"
  → [Copy Command] button for: sudo xcodebuild -license accept

No iOS simulators available:
  → "No iOS Simulator runtimes installed."
  → "Open Xcode → Settings → Platforms → Download iOS Simulator"
  → [Open Xcode] button
```

#### E. Error presentation pattern
```
New: ErrorBanner view component
- Type: warning (yellow) or error (red)
- Shows: icon + message + optional action button(s)
- Appears at top of feed or in sidebar status area
- Dismissable
- Replaces current inline feed error items for critical errors
```

**Files to modify:**
- `AgentService.swift` — exit code mapping, simulator error handling
- `SetupService.swift` — better error messages with instructions
- `MCPService.swift` — timeouts, better error messages
- `ContentView.swift` — ErrorBanner component, action buttons
- New: `ErrorBanner.swift` — reusable error/warning banner view

**Effort:** 2-3 days

---

### 3. Process Timeouts

**Goal:** Nothing hangs forever. User always has control.

**Current state:**
- `AgentService.swift` spawns Claude process with no timeout
- Tests can run 150+ turns (potentially 20+ minutes)
- `MCPService.swift` runs `claude mcp list` with no timeout
- `SetupService.swift` runs `xcode-select`, `simctl` with no timeout
- Stop button sends SIGINT → SIGTERM → SIGKILL (good chain, but only if user clicks)

**Implementation:**

#### A. Test execution timeout (AgentService.swift)
```
Add configurable test timeout:
- Default: 10 minutes (UserSettings.testTimeout)
- Slider in Settings: 5 min → 30 min
- When timeout reached:
  → Don't auto-kill. Show warning banner:
    "Test has been running for 10 minutes."
    [Keep Running] [Stop Test]
  → If user doesn't respond in 2 more minutes, show again with stronger wording
  → If process exits on its own, clear the warning
```

#### B. Shell command timeout (all services)
```
Create a shared utility: runWithTimeout(command:args:timeout:)
- Default 15 seconds for setup checks
- Default 10 seconds for MCP operations
- On timeout: throw TimeoutError with descriptive message
- Used by: SetupService, MCPService, AgentService.detectBootedSimulator()

Implementation:
  let process = Process()
  // ... configure process ...
  process.launch()

  let completed = DispatchSemaphore(signal timeout)
  if !completed {
    process.terminate()
    throw TimeoutError("Command timed out after \(timeout)s")
  }
```

#### C. MCP health check timeout (MCPService.swift)
```
claude mcp list: 10 second timeout
On timeout: mark as .warning("Could not check MCP status — timeout")
Don't block setup completion
```

#### D. Simulator boot timeout (AgentService.swift)
```
If auto-booting simulator:
- 30 second timeout
- Poll every 2 seconds: xcrun simctl list devices booted
- On timeout: "Simulator is taking too long to boot. Try opening it manually."
```

**Files to modify:**
- New: `ProcessUtils.swift` — shared `runWithTimeout()` helper
- `AgentService.swift` — test timeout warning, boot timeout
- `MCPService.swift` — use runWithTimeout for all commands
- `SetupService.swift` — use runWithTimeout for all commands
- `UserSettings.swift` — add testTimeout setting
- `SettingsView.swift` — add timeout slider

**Effort:** 2 days

---

### 4. Crash-Proof Persistence

**Goal:** Corrupted data should never crash the app. Ever.

**Current state:**
- `TestLibrary.swift` uses JSONDecoder to load `test_library.json` — if malformed, crashes
- `UserSettings.swift` decodes `customMCPs` and `appShortcuts` from UserDefaults — if malformed, crashes
- No backup before write
- No validation on load
- No migration if model changes

**Implementation:**

#### A. Safe JSON loading (TestLibrary.swift)
```
Replace:
  let data = try Data(contentsOf: url)
  let cases = try JSONDecoder().decode([SavedTestCase].self, from: data)

With:
  func safeLoad<T: Decodable>(_ type: T.Type, from url: URL) -> T? {
      guard let data = try? Data(contentsOf: url) else { return nil }
      guard let decoded = try? JSONDecoder().decode(T.self, from: data) else {
          // Corrupted — backup the bad file and start fresh
          let backup = url.appendingPathExtension("corrupted-\(Date().timeIntervalSince1970)")
          try? FileManager.default.moveItem(at: url, to: backup)
          return nil
      }
      return decoded
  }
```

#### B. Safe UserDefaults decoding (UserSettings.swift)
```
Replace:
  customMCPs = (try? JSONDecoder().decode([CustomMCP].self, from: data)) ?? []

Already uses ?? [] fallback — verify this pattern is consistent for ALL decoded properties.
Audit: customMCPs, appShortcuts — both should fallback to empty array on decode failure.
```

#### C. Auto-backup before write (TestLibrary.swift)
```
Before every save:
  1. If file exists, copy to test_library.backup.json
  2. Write new data
  3. Verify new file is valid JSON (read it back)
  4. If verification fails, restore from backup

Keep only the last 1 backup (not a growing list).
```

#### D. Data validation on load
```
After loading test cases, validate:
- Each case has a non-empty name
- Each case has a non-empty prompt
- Dates are parseable
- Remove invalid entries silently (log to console)
```

**Files to modify:**
- `TestLibrary.swift` — safeLoad, backup-before-write, validation
- `UserSettings.swift` — verify all decoded properties have fallbacks
- New helper or extension: `SafeJSON.swift` (optional, could inline)

**Effort:** 1 day

---

### 5. Auto-Detect Installed Apps (Dropdown Instead of Typing Bundle ID)

**Goal:** No more manually typing `com.cityflo.rider`. Show a dropdown of apps installed on the booted simulator.

**Current state:**
- `UserSettings.bundleIdentifier` is a plain text field
- `SettingsView.swift` and `OnboardingView.swift` show TextField for bundle ID
- `ContentView.swift` has an "Install App" file picker that detects bundle ID from Info.plist
- App shortcuts (name → bundleId mapping) exist but are manual

**Implementation:**

#### A. Fetch installed apps from simulator
```
New function in SetupService or AgentService:

func listInstalledApps(simulatorUDID: String) async -> [InstalledApp] {
    // Method 1: List app containers
    // xcrun simctl listapps <udid> — outputs plist with all installed apps
    // Parse: ApplicationType, CFBundleIdentifier, CFBundleDisplayName, CFBundleName, Path

    // Filter out Apple system apps (com.apple.*)
    // Return sorted by display name
}

struct InstalledApp: Identifiable {
    let bundleId: String
    let displayName: String
    let icon: NSImage?  // optional, from app bundle
}
```

#### B. Dropdown in Settings + Onboarding
```
Replace TextField("com.example.app") with:

Picker("Select App", selection: $settings.bundleIdentifier) {
    Text("Select an app...").tag("")
    ForEach(installedApps) { app in
        HStack {
            if let icon = app.icon {
                Image(nsImage: icon).resizable().frame(width: 16, height: 16)
            }
            Text(app.displayName)
            Text(app.bundleId).foregroundStyle(.secondary)
        }.tag(app.bundleId)
    }
}

// Keep a "Custom..." option that reveals the text field for manual entry
// Refresh button to re-scan installed apps
```

#### C. Auto-refresh on simulator boot
```
When simulator status changes (detected in SetupService):
- Re-fetch installed apps list
- Update dropdown

On ContentView appear:
- If simulator is booted, fetch installed apps
- Cache the list (don't re-fetch every second)
```

#### D. Also update the run flow
```
ContentView.swift run button area:
- If no bundle ID selected AND simulator is booted:
  → Show inline app picker instead of disabling run button
  → "Select the app to test:" + dropdown
```

**Files to modify:**
- `SetupService.swift` or new `SimulatorService.swift` — listInstalledApps()
- `Models.swift` — InstalledApp struct
- `SettingsView.swift` — replace TextField with Picker
- `OnboardingView.swift` — replace TextField with Picker
- `ContentView.swift` — inline app picker before run

**Effort:** 2 days

---

### 6. Self-Contained (Minimize External Dependencies)

**Goal:** User installs NoobQA. Logs in. Everything works. No hunting for CLI tools.

**Current state:**
- Requires manual install of Claude Code CLI (`npm install -g @anthropic-ai/claude-code`)
- Requires Xcode (unavoidable — needed for Simulator)
- Requires Node.js (because Claude CLI is an npm package)
- NooberMCP binary path is hardcoded to build output

**Implementation:**

#### A. Bundle Claude Code CLI (if legally possible)
```
Option 1: Bundle the claude binary inside NoobQA.app/Contents/Resources/
- On first launch, copy to ~/.noobqa/bin/claude
- Set as default claudeCLIPath
- BLOCKER: Check Anthropic's license for redistribution rights
- Claude CLI is installed via npm — we'd need to bundle the node binary + claude package

Option 2: Auto-install Claude CLI (more practical)
- On first launch, if claude not found:
  → Check if npm/node exists
  → If yes: run `npm install -g @anthropic-ai/claude-code` automatically
  → If no: check if Homebrew exists → `brew install node` then npm install
  → If nothing: show "Install Node.js" link + instructions
- Show progress: "Setting up Claude Code CLI... (one-time setup)"

Option 3: Use Claude API directly (eliminate CLI dependency entirely)
- Instead of spawning `claude run`, call Claude API directly via URLSession
- Manage MCP tool calls ourselves
- MAJOR refactor but eliminates the biggest external dependency
- This is the ideal long-term solution but too much work for Part 1
```

**Recommendation: Go with Option 2 for now. Option 3 for v2.**

#### B. Bundle NooberMCP binary
```
Current: Looks for NooberMCP in ~/.build/arm64-apple-macosx/release/ (dev path)
Fix:
- Build NooberMCP as a release binary
- Include in NoobQA.app/Contents/Resources/NooberMCP
- On first launch, register with Claude: claude mcp add NooberMCP -- <bundled-path>
- Update MCPService.findNooberMCP() to check bundle first (already partially does this)
```

#### C. Claude login flow inside the app
```
Current: User must run `claude login` in terminal separately
Fix:
- Detect if Claude is authenticated (run `claude --version` or try a simple prompt)
- If not authenticated:
  → Show login screen inside NoobQA
  → Option A: Open browser for OAuth (claude login --browser)
  → Option B: API key entry field (claude config set apiKey <key>)
  → Option C: "Open Terminal to log in" with copy-paste command

Simplest approach: run `claude login` as a Process and capture the auth URL,
then open it in the default browser. Poll for completion.
```

#### D. Xcode — can't bundle, but can guide
```
Xcode is required for Simulator. Can't avoid this.
But improve the guidance:
- Detect if Xcode is installed vs just Command Line Tools
- If only CLT: "Full Xcode is needed for iOS Simulator. Download from Mac App Store."
  → [Open Mac App Store] button
- If Xcode installed but no simulators: "Download an iOS Simulator runtime in Xcode."
  → [Open Xcode Settings] button (open via URL scheme)
```

#### E. First-run experience (putting it all together)
```
New onboarding flow:
1. Welcome screen
2. "Setting up..." (auto-detect/install)
   ├── Claude CLI: found / installing / need manual install
   ├── Claude auth: logged in / need login → [Log In] button
   ├── Xcode: found / not found → [Install] link
   ├── Simulator: available / need download → instructions
   └── NooberMCP: auto-configured from bundle
3. "Choose your app" → dropdown of installed simulator apps
4. "Write your first test" → example test plan → Run

Steps 2-4 can auto-advance if everything is detected.
Power user can skip straight to main app.
```

**Files to modify:**
- `SetupService.swift` — auto-install Claude CLI, bundled NooberMCP detection
- `MCPService.swift` — use bundled NooberMCP path
- `OnboardingView.swift` — new auto-setup flow
- `AgentService.swift` — use bundled NooberMCP
- `NoobQAApp.swift` — first-run setup orchestration
- New: `ClaudeSetupService.swift` — Claude CLI installation + auth flow

**Effort:** 4-5 days

---

### 7. Connectors (Linear, Figma, Slack) — Low Priority

**Goal:** Work like Claude Desktop's MCP connections. User toggles on, authenticates, done. Not critical for launch.

**Current state:**
- Figma: `claude mcp add figma-desktop http://127.0.0.1:3845/mcp` — requires Figma Desktop running
- Linear: `claude mcp add linear-server https://mcp.linear.app/mcp` — requires OAuth
- Slack: mentioned in settings toggle but not actually implemented
- Custom MCPs: can add name + command/URL, stored in UserDefaults

**Implementation (when we get to it):**

#### A. Connector UI pattern
```
Each connector gets a card in Settings → Integrations:

┌─────────────────────────────────────┐
│ 🔗 Linear                    [On/Off] │
│ Status: Connected ✅                  │
│ Auto-file bugs from test reports      │
│                        [Disconnect]   │
└─────────────────────────────────────┘

States: Not connected → Connecting... → Connected → Error
```

#### B. Figma connector
```
- Toggle on → check if Figma Desktop is running (ping localhost:3845)
- If not running: "Open Figma Desktop to enable design comparison"
- If running: auto-register MCP, show "Connected"
- No OAuth needed — Figma Desktop MCP is local
```

#### C. Linear connector
```
- Toggle on → open Linear OAuth URL in browser
- Poll for auth completion (or use redirect URI)
- Once authenticated, register MCP
- Show connected workspace name
```

#### D. Slack connector
```
- Need to determine which Slack MCP to use
- Likely: official Slack MCP or custom webhook-based approach
- Toggle on → OAuth → register MCP
- Configure: which channel to post reports to
```

**Effort:** 3-4 days (all three)
**Priority:** Do after Part 2 launch. These are nice-to-have, not blockers.

---

## Part 1 Summary

| # | Task | Priority | Effort | Dependencies |
|---|------|----------|--------|-------------|
| 1 | Make Noober optional | Critical | 3-4 days | None |
| 2 | Error handling (critical paths) | Critical | 2-3 days | None |
| 3 | Process timeouts | Critical | 2 days | None |
| 4 | Crash-proof persistence | Critical | 1 day | None |
| 5 | Auto-detect installed apps | High | 2 days | #3 (timeout utils) |
| 6 | Self-contained setup | High | 4-5 days | #2, #3 |
| 7 | Connectors (Linear/Figma/Slack) | Low | 3-4 days | After Part 2 |

**Total Part 1: ~15-17 days (3-3.5 weeks)**

**Recommended order:**
```
Week 1:
  Day 1:      #4 Crash-proof persistence (quick win, protects everything else)
  Day 2-3:    #3 Process timeouts (shared utility used by everything)
  Day 4-5:    #2 Error handling (depends on timeout utils)

Week 2:
  Day 6-7:    #5 Auto-detect installed apps
  Day 8-11:   #1 Make Noober optional (biggest change, needs careful testing)

Week 3:
  Day 12-16:  #6 Self-contained setup (Claude CLI bundling, auth flow, onboarding)
  Day 17:     Integration testing — test the full flow on a clean Mac
```

---

## Part 2 — Release (Distribution & Launch)

### Analytics & Tracking (Code Done — Activation TODO)

**Mac App — TelemetryDeck (free, 100K signals/mo)**
- [x] `Analytics.swift` — full tracking service with TelemetryDeck SDK integrated
- [x] `Package.swift` — TelemetryDeck/SwiftSDK v2.12 dependency added
- [x] Tracks: app launches, feature usage, test pass/fail counts, error types, duration buckets
- [x] Does NOT track: test plans, file paths, bundle IDs, screenshots, personal data
- [x] Opt-out toggle in Settings → About with full transparency
- [x] "Delete Local Data" button for full user control
- [ ] **TODO: Create TelemetryDeck account** at dashboard.telemetrydeck.com (1 min)
- [ ] **TODO: Replace `YOUR_APP_ID_HERE`** in `Sources/Analytics.swift` with real app ID

**Landing Page — Website Analytics**
- [x] Microsoft Clarity script added to `index.html`
- [x] Vercel Analytics script added to `index.html`
- [x] Vercel Speed Insights script added to `index.html`
- [ ] **TODO: Create Clarity account** at clarity.microsoft.com (1 min)
- [ ] **TODO: Replace `YOUR_CLARITY_PROJECT_ID`** in `noobqa-website/index.html`
- [ ] **TODO: Deploy website** — `cd noobqa-website && vercel --prod`

### Distribution & Branding

- [ ] App icon + branding
- [ ] Lemon Squeezy integration (payments + license keys) — free, 5% + $0.50 per sale
- [ ] Apple Developer Account ($99/yr) + code signing + notarization
- [ ] DMG packaging + Sparkle auto-updates (both free)
- [ ] Landing page polish + demo video (Vercel, already deployed)
- [ ] Pricing page on website
- [ ] Launch strategy (Product Hunt, Reddit, Twitter)
- [ ] Connectors (#7) — post-launch feature

### Total Cost to Launch

| Item | Cost |
|------|------|
| Apple Developer Account | $99/year |
| TelemetryDeck | $0 (free tier) |
| Clarity | $0 |
| Vercel | $0 (hobby tier) |
| Lemon Squeezy | $0 upfront (5% per sale) |
| Sparkle | $0 (open source) |
| **Total** | **$99** |

---

## What's NOT in Part 1 (Intentionally Deferred)

| Item | Why Deferred |
|------|-------------|
| Unit tests | Ship first, test critical paths in Month 1 |
| Localization | English-only is fine for launch market |
| Accessibility (VoiceOver) | Important but won't block first 100 users |
| Android support | iOS-only is the niche, not a limitation |
| Team features | Solo/indie is launch market |
| Multiple LLM support | Protocol abstraction done (AgentProvider.swift). Implementation in v2. |
| Crash reporting (Sentry) | Local analytics covers basics. Add Sentry post-launch. |
| Test scheduling (cron) | Manual runs are fine for launch |
| Historical trending / graphs | Build when there's enough data to show |
