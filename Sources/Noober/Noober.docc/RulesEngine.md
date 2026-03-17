# Rules Engine

Rewrite URLs, mock responses, and intercept requests mid-flight.

## Overview

The rules engine provides three types of rules that modify network behavior at runtime. All rules are persisted in UserDefaults and survive app restarts.

### URL Match Patterns

All rules use a `URLMatchPattern` with one of five match modes:

- **Host** — exact domain match
- **Contains** — case-insensitive substring match anywhere in the URL
- **Prefix** — URL starts with the pattern
- **Exact** — full URL equality
- **Regex** — NSRegularExpression match against the full URL

### URL Rewrite Rules

Redirect requests to a different host without changing the path or query parameters.

Example: Redirect all `api.production.com` requests to `api.staging.com:8080`.

### Mock Rules

Return synthetic responses without hitting the network. Configure:
- Match pattern and optional HTTP method filter
- Response status code (default: 200)
- Response headers (default: `Content-Type: application/json`)
- Response body

Mocked requests are tagged in the network inspector with a "Mock" badge.

### Intercept Rules

Pause matching requests mid-flight and present them in the debug panel for inspection. You can:
- **Proceed with modifications** — edit the URL, method, headers, or body and continue
- **Proceed original** — continue with the unmodified request
- **Cancel** — abort the request entirely

Intercepted requests auto-timeout after 60 seconds if no action is taken.

### Processing Order

When a request matches multiple rule types, they are evaluated in this order:
1. Mock rules (highest priority — returns immediately)
2. Intercept rules (pauses the request)
3. Environment rewrites
4. URL rewrite rules
