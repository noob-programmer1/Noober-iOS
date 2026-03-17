# Deep Link Tester

Test URL schemes and universal links from the debug panel.

## Overview

The Deep Link Tester lives in the **Rules** tab under the **Links** section. It lets you fire any URL — custom schemes (`myapp://product/123`), universal links (`https://example.com/share/abc`), or system URLs (`tel:`, `mailto:`) — and see whether the system opened it successfully.

### Testing a Deep Link

1. Open the debug panel and navigate to **Rules > Links**
2. Type a URL in the input field
3. Tap **Fire**
4. The result badge shows **Opened** (green) or **Failed** (red)

### Favorites

Swipe right on any history entry to star it as a favorite. Favorites appear in a pinned section at the top and persist across launches. Tap any favorite to re-fire it instantly.

### History

All fired links are recorded with their timestamp and result. History persists across launches (up to 100 entries). Swipe left to delete individual entries, or tap **Clear All** to remove all history.

### Use Cases

- Test deep links during development without switching to Safari or another app
- Verify universal link routing for different URL patterns
- Keep frequently-used test links as favorites
- Debug deep link handling across different screens and states
