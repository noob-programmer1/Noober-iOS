# NoobQA — Brand Guide

> Use this to generate consistent icons, banners, and marketing assets.
> Feed this entire doc to Gemini/Midjourney/DALL-E when generating images.

---

## Brand Identity

**Name:** NoobQA
**Tagline:** "AI-powered QA testing for iOS apps"
**One-liner:** "Your iOS app's QA team for $29/month"
**Tone:** Professional but approachable. Developer-friendly, not corporate. Confident, not flashy.

---

## Color Palette

The website and app MUST use the same colors. Here's the unified palette:

### Primary Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Neon Green** (Primary) | `#22c55e` | Accent, CTAs, pass states, active elements, icon glow |
| **Carbon 950** (Background) | `#06080c` | Website background, dark mode app background |
| **Carbon 900** | `#0a0e14` | Cards, elevated surfaces |
| **Carbon 800** | `#111822` | Input fields, secondary surfaces |
| **Carbon 700** | `#1a2332` | Borders, dividers |

### Secondary Colors

| Name | Hex | Usage |
|------|-----|-------|
| **Blue** | `#3b82f6` | Info states, links, tool calls |
| **Purple** | `#a855f7` | Noober-specific elements, premium features |
| **Red** | `#ef4444` | Errors, fail states, stop button |
| **Amber** | `#f59e0b` | Warnings, partial pass |
| **Slate 300** | `#cbd5e1` | Primary text (dark mode) |
| **Slate 400** | `#94a3b8` | Secondary text |
| **Slate 600** | `#475569` | Tertiary text, timestamps |

### App-Specific (macOS Adaptive)

The Mac app uses native macOS colors that adapt to light/dark mode:
- Background: `NSColor.windowBackgroundColor`
- Surface: `NSColor.controlBackgroundColor`
- Accent: `Color.green` (maps to `#22c55e` in dark mode)

This means the dark mode app and the website look identical in color. Light mode adapts naturally.

---

## App Icon

### Design Direction

**Style:** Minimal, modern, dark background with neon green accent. Should feel like a developer tool — think Warp terminal, Raycast, Linear icon quality.

**Concept:** A test tube or beaker shape (the app uses `testtube.2` SF Symbol throughout) combined with a subtle "play" or "check" element to convey "testing that runs automatically."

### Prompt for Gemini/AI Image Generation

```
Design a macOS app icon for "NoobQA", an AI-powered QA testing tool for iOS apps.

Style:
- Minimal, modern, professional macOS app icon
- Dark background (#06080c to #111822 gradient)
- Neon green (#22c55e) as the primary accent color
- Clean lines, no text on the icon
- Rounded square shape (macOS squircle format)
- Slight glow/bloom effect on the green element

Concept options (pick the best):
1. A test tube/beaker with a green glowing liquid inside, tilted slightly. A small checkmark or play symbol visible in the liquid.
2. A magnifying glass over a mobile phone screen, with a green scanning line across it.
3. A shield shape with a green checkmark, subtle circuit-board pattern in the background.
4. Abstract: two overlapping rounded rectangles (representing app screens), with a green "pass" checkmark bridging them.

Requirements:
- Must work at 16x16, 32x32, 128x128, 256x256, 512x512, 1024x1024
- No text, no letters, no words
- Should be recognizable in the macOS dock at small sizes
- Should feel premium — like it belongs next to Xcode, Figma, Linear icons
- Dark background is important — matches the dark UI of the app

Reference icons for quality/style:
- Warp terminal icon (minimal, dark, neon accent)
- Raycast icon (clean, modern, glowing element)
- Linear icon (simple geometry, purple glow)
- Arc browser icon (gradient, bold shape)
```

### Icon Sizes Needed (macOS)

| Size | Usage |
|------|-------|
| 16x16 | Finder sidebar, menu bar |
| 32x32 | Finder list view |
| 64x64 | Finder grid (Retina 32) |
| 128x128 | Finder icon view |
| 256x256 | Finder large icon |
| 512x512 | App Store, About window |
| 1024x1024 | Master source |

Generate at 1024x1024 and downscale. Bundle as `.icns` file.

---

## Website Banner / Hero Image

### Prompt for Gemini/AI Image Generation

```
Create a hero image/banner for the NoobQA website — an AI-powered iOS testing tool.

The image should show:
- A MacBook screen displaying a terminal-like interface with green text
- On the terminal: a test running with checkmarks (pass/fail indicators)
- Next to it: an iPhone simulator showing an iOS app being tested
- Subtle green glow connecting the Mac and the phone (representing the AI agent)
- Dark background (#06080c) with subtle grid lines
- Neon green (#22c55e) as accent color
- Professional, developer-tool aesthetic

Style: Dark tech, minimal, clean. Similar to Linear, Vercel, or Warp marketing images.
Aspect ratio: 16:9 (1920x1080)
No people, no hands, no stock photo feel. Pure product/tech aesthetic.
```

---

## Social Media / Product Hunt Assets

### Product Hunt Thumbnail (240x240)

```
NoobQA logo icon on dark background (#06080c).
Neon green (#22c55e) test tube/beaker icon, centered.
Slight green glow effect. No text.
Square format, 240x240px.
```

### Twitter/X Banner (1500x500)

```
Dark banner for NoobQA — AI-powered iOS testing.

Left side: NoobQA icon (green test tube on dark bg)
Center: "Stop writing test scripts." in Outfit font, white text
Right side: Subtle terminal UI mockup with green pass indicators

Background: #06080c with subtle grid pattern
Accent: #22c55e
Fonts: Outfit (display), JetBrains Mono (code)
```

### Open Graph Image (1200x630)

```
Social share preview for NoobQA website.

Content:
- NoobQA logo/icon (top-left)
- "AI-Powered QA Testing for iOS Apps" — large white text, Outfit Bold
- "Describe tests in plain English. The agent does the rest." — smaller, slate-400 text
- Bottom-right: small terminal mockup showing "PASS (3/3)" in green

Background: #06080c to #0a0e14 gradient
Accent: #22c55e
1200x630px
```

---

## Typography

| Context | Font | Weight | Usage |
|---------|------|--------|-------|
| Website headings | Outfit | Bold (700-800) | Hero text, section titles |
| Website body | Outfit | Regular (400) | Paragraphs, descriptions |
| Code/terminal | JetBrains Mono | Regular (400) | Code samples, terminal UI |
| Mac app | SF Pro (system) | Various | Native macOS typography |
| Mac app mono | SF Mono (system) | Regular | Test plans, code, logs |

---

## Logo Variations

### 1. Icon Only (app icon, favicons, small contexts)
- Green test tube shape on dark background
- No text

### 2. Wordmark (horizontal, for headers)
```
[icon] NoobQA
```
- Icon + "NoobQA" in Outfit Bold
- Green icon, white text on dark bg
- OR green icon, dark text on light bg

### 3. Wordmark + Tagline (for marketing)
```
[icon] NoobQA
      AI-powered QA testing for iOS apps
```
- Tagline in Outfit Regular, slate-400 color

---

## Do's and Don'ts

**Do:**
- Always use `#22c55e` green as the primary accent
- Keep backgrounds dark (`#06080c` to `#111822`)
- Use green for positive states (pass, active, connected)
- Use red only for errors/failures
- Keep the icon simple — recognizable at 16x16

**Don't:**
- Don't use bright/white backgrounds on marketing materials
- Don't use gradients on the icon (flat or subtle is better)
- Don't add text to the app icon
- Don't use more than 2 accent colors in one context
- Don't use the green for error or warning states

---

## Quick Reference for AI Image Generation

When prompting any AI image tool, always include:

```
Colors: Dark background #06080c, accent #22c55e (neon green), text #cbd5e1 (light gray)
Style: Minimal, modern, dark tech aesthetic. Similar to Linear, Vercel, Warp branding.
Font: Outfit for display, JetBrains Mono for code
Mood: Professional developer tool, not playful or cartoonish
```
