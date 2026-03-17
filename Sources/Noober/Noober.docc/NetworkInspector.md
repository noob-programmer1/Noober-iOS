# Network Inspector

Automatically capture and inspect all HTTP and WebSocket traffic.

## Overview

Noober intercepts network requests using a custom `URLProtocol` registered via method swizzling on `URLSessionConfiguration.default` and `.ephemeral`. This means all `URLSession`-based networking is captured without any code changes.

### What Gets Captured

**HTTP Requests:**
- URL, HTTP method, headers, request body
- Status code, response headers, response body
- Timing (duration in ms/s), content size
- MIME type and content type detection
- Source screen (the view controller that triggered the request)

**WebSocket Connections:**
- Connection URL, status (connecting/connected/disconnected/error)
- All sent and received frames with payload previews
- Frame types: text, binary, ping, pong, close
- Close codes and reasons

### Features

- **cURL export** — copy any request as a cURL command
- **Request replay** — re-fire a captured request with one tap
- **Image preview** — inline rendering for image responses
- **JSON pretty-printing** — formatted JSON for request and response bodies
- **Screen grouping** — group requests by the view controller that triggered them
- **Search & filter** — filter by method, status code, host, content type, entry type, or screen

### Limits

- Maximum 500 HTTP requests stored (oldest removed first)
- Maximum 1000 WebSocket frames per connection
- Maximum 200 screen history entries
