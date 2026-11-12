#!/usr/bin/env python3
import json
import subprocess
import sys
import time
from typing import Any

# Host one .figcraft file as a FigCraft live session from an unrooted headless MCP, without saving.
# Usage: live_host.py <file.figcraft> <bind address> <minutes>
if len(sys.argv) != 4:
    sys.exit("usage: live_host.py <file.figcraft> <bind address> <minutes>")
path, bind, minutes = sys.argv[1], sys.argv[2], int(sys.argv[3])
proc = subprocess.Popen(
    ["figcraft-cli", "mcp"],
    stdin=subprocess.PIPE,
    stdout=subprocess.PIPE,
    text=True,
    bufsize=1,
)
next_id = 0


def rpc(method: str, params: dict[str, Any]) -> Any:
    global next_id
    next_id += 1
    proc.stdin.write(
        json.dumps(
            {"jsonrpc": "2.0", "id": next_id, "method": method, "params": params}
        )
        + "\n"
    )
    proc.stdin.flush()
    while True:
        msg = json.loads(proc.stdout.readline())
        if msg.get("id") == next_id:
            return msg


def tool(name: str, arguments: dict[str, Any]) -> Any:
    res = rpc("tools/call", {"name": name, "arguments": arguments})
    text = res["result"]["content"][0]["text"]
    if res["result"].get("isError"):
        print("ERROR", name, text, flush=True)
        sys.exit(1)
    return json.loads(text)


rpc(
    "initialize",
    {
        "protocolVersion": "2025-06-18",
        "capabilities": {},
        "clientInfo": {"name": "host", "version": "0"},
    },
)
proc.stdin.write(
    json.dumps({"jsonrpc": "2.0", "method": "notifications/initialized"}) + "\n"
)
proc.stdin.flush()

tool("open_file", {"path": path})
host = tool("run_command", {"command": "collab.host", "params": {"bind": bind}})
print("HOST", json.dumps(host), flush=True)
deadline = time.time() + minutes * 60
while time.time() < deadline:
    time.sleep(30)
    peers = tool("run_command", {"command": "collab.peers", "params": {}})
    print("PEERS", len(peers.get("peers", [])), flush=True)
proc.terminate()
