#!/usr/bin/env python3
"""Traffic generator for NooberSample.

HTTP on :8765 and a WebSocket echo on :8766. Run it before launching the app:

    python3 Example/demo_server.py

Requires the `websockets` package (pip install websockets).
"""

import asyncio
import json
import threading
import time
from http.server import BaseHTTPRequestHandler, HTTPServer

import websockets

HTTP_PORT = 8765
WS_PORT = 8766


# ---------------------------------------------------------------- HTTP

class Handler(BaseHTTPRequestHandler):
    def _reply(self, code, payload):
        body = json.dumps(payload).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.startswith("/boom"):
            self._reply(500, {"error": "kaboom", "detail": "deliberate failure"})
        elif self.path.startswith("/slow"):
            time.sleep(1.5)
            self._reply(200, {"ok": True, "path": self.path})
        else:
            self._reply(200, {"ok": True, "path": self.path, "items": list(range(20))})

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(length) if length else b"{}"
        try:
            echoed = json.loads(raw)
        except json.JSONDecodeError:
            echoed = {"raw": raw.decode("utf-8", "replace")}
        self._reply(200, {"echo": echoed, "receivedAt": time.time()})

    def log_message(self, *args):
        pass


def serve_http():
    HTTPServer(("0.0.0.0", HTTP_PORT), Handler).serve_forever()


# ---------------------------------------------------------------- WebSocket

def fat_response(received):
    """Echo wrapped in a big envelope so frames are long enough to need scrolling."""
    return {
        "type": "server.echo",
        "receivedAt": time.time(),
        "echo": received,
        "server": {
            "region": "ap-south-1",
            "build": "demo-1.0.0",
            "features": ["mocks", "intercepts", "flows", "websockets"],
        },
        "history": [
            {"seq": i, "state": "delivered", "latencyMs": 12 + i, "note": "frame padding " * 4}
            for i in range(15)
        ],
    }


async def handler(websocket):
    async for message in websocket:
        if isinstance(message, bytes):
            await websocket.send(b"BIN-ACK" + message[:32])
            continue
        try:
            parsed = json.loads(message)
        except json.JSONDecodeError:
            parsed = message
        await websocket.send(json.dumps(fat_response(parsed)))


async def serve_ws():
    async with websockets.serve(handler, "0.0.0.0", WS_PORT):
        await asyncio.Future()


if __name__ == "__main__":
    threading.Thread(target=serve_http, daemon=True).start()
    print(f"HTTP  → http://127.0.0.1:{HTTP_PORT}")
    print(f"WS    → ws://127.0.0.1:{WS_PORT}")
    asyncio.run(serve_ws())
