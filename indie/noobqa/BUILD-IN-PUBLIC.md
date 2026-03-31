# NoobQA — Build in Public Content Plan

> Strategy: Post 3-4x/week on LinkedIn + Twitter/X leading up to launch.
> Share real learnings, real challenges, real numbers. Not marketing fluff.
> People follow the journey, then buy the product when it launches.

---

## Content Pillars

1. **Behind the scenes** — What you built this week, architecture decisions, screenshots
2. **Technical learnings** — Specific challenges and how you solved them (devs love this)
3. **Numbers & progress** — Milestones, metrics, honest updates
4. **Industry takes** — QA pain points, AI testing opinions, iOS dev hot takes

---

## Ready-to-Post Content (From What We've Actually Built)

### Week 1 — "The Problem"

**Post 1: The origin story**
> I spent 2 hours manually testing my iOS app before every release. Tap this, check that, verify the API, screenshot the result. Every. Single. Time.
>
> So I built an AI agent that does it for me.
>
> You describe tests in plain English: "open the booking flow, verify the fare is correct"
> The agent navigates the app, checks the APIs, and reports bugs.
>
> Building this in public. Follow along.
>
> #buildinpublic #ios #testing

**Post 2: The market gap**
> iOS QA testing tools in 2026:
>
> - Appium: free but you write 500 lines of code per test
> - XCUITest: tied to Xcode, breaks every iOS update
> - Maestro: YAML scripts, better but still scripted
> - Revyl: great but $500+/mo enterprise pricing
>
> What if you could just... describe the test?
>
> "Verify the checkout flow works and the analytics event fires"
>
> That's what I'm building. $29/mo. For the other 95% of iOS devs.

---

### Week 2 — "The Technical Breakthrough"

**Post 3: The screen HTML insight (biggest optimization)**
> The #1 thing that made AI testing actually work:
>
> Stop sending screenshots to the AI. Send HTML instead.
>
> Most testing tools take a screenshot → send to vision model → AI guesses what's on screen. Slow, expensive, inaccurate.
>
> We built noober_screen_html — converts the live iOS screen into semantic HTML with coordinates:
> `<button id="3" data-center="195,283">Book a Ride</button>`
>
> Result: 100ms vs 20-30 seconds. 200x faster. And the AI can actually READ the UI instead of guessing from pixels.
>
> [Screenshot of HTML output vs screenshot comparison]

**Post 4: The unified MCP architecture**
> Day 14 of building an AI QA agent.
>
> Problem: Claude was spending 5-10 turns just figuring out which tools to use across two MCP servers.
>
> Solution: Built a single MCP server (NooberMCP) that handles everything — simulator control, app inspection, network logs, screenshots. Used the AXe library for native accessibility-based automation.
>
> One server. One namespace. Zero tool confusion. Tests went from 3 minutes to under 60 seconds.
>
> The boring infrastructure work that makes the magic possible.

---

### Week 3 — "Making It Real"

**Post 5: The learned lessons system**
> My AI testing agent gets smarter every time you use it.
>
> After each test run, it outputs what it learned:
> - "UISwitch: regular tap doesn't work, use touch() instead"
> - "More tab: label tap fails, use coordinates (352, 789)"
> - "Rewards screen: scroll needed to see full grid"
>
> These lessons persist. Next run, it doesn't repeat the same mistakes.
>
> No other testing tool does this. The agent literally builds institutional knowledge about YOUR app.

**Post 6: Making Noober optional (adoption strategy)**
> The hardest product decision so far:
>
> NoobQA works 10x better WITH our Noober SDK (sees network logs, app state, API responses). But requiring an SDK integration before someone can even try the tool? That's a death sentence for adoption.
>
> So we made it optional. Without Noober: screenshot + accessibility tree testing (like competitors). With Noober: deep inspection superpowers.
>
> Let people try → see value → THEN ask them to integrate.
>
> Free → Paid. Simple → Powerful. Low friction → High engagement.

---

### Week 4 — "Polish & Ship"

**Post 7: The auto-detect UX improvement**
> Small UX win that saves 30 seconds per session:
>
> Before: manually type "com.example.myapp" bundle ID every time
> After: dropdown that detects all installed apps on the booted simulator
>
> `xcrun simctl listapps` → parse → filter out Apple system apps → sorted dropdown
>
> 50 lines of code. Took 2 hours. But it's the kind of thing that makes a tool feel polished vs. hacky.
>
> The difference between a side project and a product is 100 of these small decisions.

**Post 8: Process timeout story**
> Bug report from testing my own AI testing tool (meta):
>
> "The app froze and I had to force quit"
>
> Root cause: Claude CLI hung because an MCP server was offline. `process.waitUntilExit()` blocks forever. No timeout. No recovery.
>
> Fix: DispatchSemaphore with configurable timeouts on every shell command. 15 seconds for setup checks, 10 seconds for MCP operations. User gets a warning, not a freeze.
>
> Lesson: every external process call needs a timeout. Every. Single. One.

---

### Week 5 — "Numbers & Launch Prep"

**Post 9: Tech stack & costs**
> Building an indie Mac app in 2026. Total cost to launch:
>
> - Apple Developer Account: $99/yr
> - Analytics (TelemetryDeck): $0
> - Website analytics (Clarity): $0
> - Hosting (Vercel): $0
> - Payments (Lemon Squeezy): $0 upfront, 5% per sale
> - Auto-updates (Sparkle): $0
> - Total: $99
>
> Tech stack: Swift + SwiftUI + Claude API + TelemetryDeck
> Distribution: DMG + notarization (no App Store)
>
> If 1 customer pays $29/mo, I break even. Everything after that is 93% margin.

**Post 10: The honest metrics**
> NoobQA by the numbers (pre-launch):
>
> - Lines of code: ~7,500
> - Time to build: 3 weeks
> - Test execution time: under 60 seconds (recorded flows)
> - Cost per test run: ~$0.01-0.05 (Claude API)
> - Competitor pricing: $120-500+/mo
> - Our pricing: $29/mo
>
> Launching next week. Follow for the Product Hunt drop.

---

### Launch Week

**Post 11: Launch day**
> NoobQA is live.
>
> AI-powered QA testing for iOS apps. Describe tests in English. The agent does the rest.
>
> - No scripts. No YAML. No code.
> - Sees inside your app (network logs, app state, API verification)
> - Learns from every run
> - $29/mo (vs competitors at $500+)
>
> Free trial: 10 test runs, full features.
>
> [Link to Product Hunt]
> [Link to noobqa.com]
>
> Built this in 3 weeks. Let me know what you think.

---

## Post Templates

### "Today I built..." (use 2-3x/week)
```
Today I [built/fixed/shipped] [specific thing] in NoobQA.

[2-3 sentences about what it does and why]

[The surprising/interesting part]

[Screenshot or code snippet]

#buildinpublic #ios #indiedev
```

### "The problem with..." (use 1x/week)
```
The problem with [current QA tool/approach]:

[Specific pain point]

How NoobQA solves it:

[Your approach, 2-3 sentences]

[Result or metric]
```

### "Honest update" (use 1x/week)
```
Week [N] of building NoobQA:

What went well:
- [thing]
- [thing]

What didn't:
- [challenge]

Next week:
- [plan]

[Honest reflection, 1-2 sentences]
```

---

## Content From Past Optimizations (Mine This)

| Optimization | Post Angle |
|-------------|-----------|
| HTML screen layout vs screenshots | "200x faster screen reading" — technical deep dive |
| Unified NooberMCP with native AXe | "Why we built our own simulator automation" |
| Pre-warm simulator + app | "Shaving 15 seconds off every test run" |
| Recorded flow replay | "How we made test navigation 6x faster" |
| Learned lessons system | "An AI agent that remembers your app's quirks" |
| noober_assert_request | "API verification in one line instead of 20" |
| Crash-proof persistence | "The boring code that prevents data loss" |
| Process timeouts | "Every external call needs a timeout (learned the hard way)" |
| Auto-detect installed apps | "50 lines of code that save 30 seconds per session" |
| Noober made optional | "The hardest product decision: reduce your own moat" |
| LLM abstraction layer | "Designing for a multi-LLM future" |
| Private UITouch API crash on iOS 26 | "What happens when Apple breaks your undocumented API" |

---

## Hashtags

Primary: `#buildinpublic #indiedev #ios`
Secondary: `#swift #swiftui #testing #qa #ai #macos`
Niche: `#iosdev #mobiledev #devtools #indiehacker`

## Platforms

| Platform | Frequency | Content Type |
|----------|-----------|-------------|
| Twitter/X | 3-4x/week | Short takes, screenshots, threads |
| LinkedIn | 2x/week | Longer posts, professional angle, architecture decisions |
| Indie Hackers | 1x/week | Progress updates with revenue/metrics |
| Reddit (r/iOSProgramming) | Launch day + 1 update | Product announcement, not spam |

## Timing

- Start posting 2-3 weeks before launch
- Build up to 10-15 posts before launch day
- Launch day: coordinated PH + Twitter + LinkedIn + Reddit
- Post-launch: weekly updates with metrics
